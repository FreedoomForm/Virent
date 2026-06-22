/**
 * WebSocket server for real-time updates
 *
 * Per Backend Design System §20 (Observability) + §28 (laws):
 *   "WebSocket / SSE для real-time обновлений админки"
 *
 * Provides:
 *   - /ws — single endpoint, subscribe via message: { type: 'subscribe', channel: 'admin:dashboard' }
 *   - Channels:
 *     - admin:dashboard — admin dashboard live updates
 *     - admin:trips — new trip events
 *     - admin:scooters — scooter status changes
 *     - user:<userId> — user-specific events (trip state, notifications)
 *     - public:announcements — broadcasts
 *
 * Auth: JWT in query param ?token=...
 *
 * Usage:
 *   const wsServer = require('./src/realtime/ws-server.js');
 *   wsServer.attach(server);
 */

const { WebSocketServer } = require('ws');
const jwt = require('jsonwebtoken');
const logger = require('../shared/logger.js');

const jwtSecret = process.env.JWT_SECRET || 'dev-secret';
const subscribers = new Map();  // channel → Set<ws>

function getSubscribers(channel) {
    if (!subscribers.has(channel)) subscribers.set(channel, new Set());
    return subscribers.get(channel);
}

function publish(channel, message) {
    const subs = getSubscribers(channel);
    const payload = JSON.stringify({
        channel,
        data: message,
        timestamp: new Date().toISOString(),
    });
    let sent = 0;
    for (const ws of subs) {
        if (ws.readyState === ws.OPEN) {
            try {
                ws.send(payload);
                sent++;
            } catch (e) {
                subs.delete(ws);
            }
        } else {
            subs.delete(ws);
        }
    }
    return sent;
}

function subscribe(ws, channel) {
    getSubscribers(channel).add(ws);
    logger.debug('WS subscribe', { channel, subscribers: getSubscribers(channel).size });
}

function unsubscribe(ws, channel) {
    if (subscribers.has(channel)) {
        subscribers.get(channel).delete(ws);
    }
}

function unsubscribeAll(ws) {
    for (const [channel, subs] of subscribers) {
        subs.delete(ws);
        if (subs.size === 0) subscribers.delete(channel);
    }
}

/**
 * Verify JWT from query
 */
function authenticate(req) {
    try {
        const url = new URL(req.url, 'http://localhost');
        const token = url.searchParams.get('token');
        if (!token) return null;
        const decoded = jwt.verify(token, jwtSecret);
        return decoded;
    } catch (e) {
        return null;
    }
}

function attach(server) {
    const wss = new WebSocketServer({ server, path: '/ws' });

    wss.on('connection', (ws, req) => {
        const user = authenticate(req);
        if (!user) {
            ws.close(4001, 'Unauthorized');
            return;
        }

        logger.info('WS connected', { user_id: user.id, role: user.role });
        ws.userId = user.id;
        ws.role = user.role;
        ws.channels = new Set();

        ws.on('message', (raw) => {
            try {
                const msg = JSON.parse(raw.toString());
                handleWsMessage(ws, msg);
            } catch (e) {
                ws.send(JSON.stringify({ error: 'Invalid JSON' }));
            }
        });

        ws.on('close', () => {
            unsubscribeAll(ws);
            logger.info('WS disconnected', { user_id: ws.userId });
        });

        ws.on('error', (err) => {
            logger.error('WS error', { user_id: ws.userId, error: err.message });
        });

        ws.send(JSON.stringify({
            type: 'connected',
            user_id: user.id,
            timestamp: new Date().toISOString(),
        }));
    });

    logger.info('WebSocket server attached', { path: '/ws' });
    return wss;
}

function handleWsMessage(ws, msg) {
    switch (msg.type) {
        case 'subscribe':
            if (canSubscribe(ws, msg.channel)) {
                subscribe(ws, msg.channel);
                ws.channels.add(msg.channel);
                ws.send(JSON.stringify({ type: 'subscribed', channel: msg.channel }));
            } else {
                ws.send(JSON.stringify({ type: 'error', message: 'Cannot subscribe to ' + msg.channel }));
            }
            break;

        case 'unsubscribe':
            unsubscribe(ws, msg.channel);
            ws.channels.delete(msg.channel);
            ws.send(JSON.stringify({ type: 'unsubscribed', channel: msg.channel }));
            break;

        case 'ping':
            ws.send(JSON.stringify({ type: 'pong', timestamp: new Date().toISOString() }));
            break;

        default:
            ws.send(JSON.stringify({ type: 'error', message: 'Unknown message type: ' + msg.type }));
    }
}

function canSubscribe(ws, channel) {
    if (ws.role === 'admin') return true;
    if (channel.startsWith('user:')) return channel === `user:${ws.userId}`;
    if (channel === 'public:announcements') return true;
    return false;
}

/**
 * Helper: publish trip update
 */
function publishTripUpdate(trip) {
    publish(`user:${trip.user_id}`, {
        type: 'trip_update',
        trip_id: String(trip._id || trip.id),
        status: trip.status,
        cost: trip.cost,
        duration_min: trip.duration_min,
    });
    publish('admin:trips', {
        type: 'trip_update',
        trip_id: String(trip._id || trip.id),
        user_id: String(trip.user_id),
        scooter_id: String(trip.scooter_id),
        status: trip.status,
        cost: trip.cost,
    });
}

/**
 * Helper: publish scooter telemetry update
 */
function publishScooterUpdate(scooter) {
    publish('admin:scooters', {
        type: 'scooter_update',
        scooter_id: String(scooter._id || scooter.id),
        status: scooter.status,
        battery: scooter.battery,
        coordinates: scooter.coordinates,
        last_seen: scooter.last_seen,
    });
    if (scooter.trip?.user_id) {
        publish(`user:${scooter.trip.user_id}`, {
            type: 'scooter_update',
            scooter_id: String(scooter._id || scooter.id),
            battery: scooter.battery,
        });
    }
}

function publishNotification(userId, notification) {
    publish(`user:${userId}`, {
        type: 'notification',
        notification,
    });
}

function publishDashboardUpdate(stats) {
    publish('admin:dashboard', {
        type: 'dashboard_update',
        stats,
    });
}

module.exports = {
    attach,
    publish,
    subscribe,
    unsubscribe,
    publishTripUpdate,
    publishScooterUpdate,
    publishNotification,
    publishDashboardUpdate,
};
