/**
 * logger.js — Structured JSON logger
 *
 * Every log line is JSON with:
 *   - timestamp (ISO 8601 UTC)
 *   - level (debug/info/warn/error)
 *   - message
 *   - requestId (if available)
 *   - userId (if available)
 *   - arbitrary context fields
 *
 * Sensitive data (password, token, refresh_token, card) is auto-redacted.
 */

const SENSITIVE_KEYS = new Set([
    'password', 'new_password', 'current_password',
    'token', 'access_token', 'refresh_token', 'authtoken',
    'authorization', 'cookie',
    'card', 'card_number', 'cvv', 'pin',
    'secret', 'api_key', 'apikey',
    'private_key',
]);

function redact(obj, depth = 0) {
    if (depth > 5) return '[max depth]';
    if (obj == null) return obj;
    if (typeof obj !== 'object') return obj;
    if (Array.isArray(obj)) return obj.slice(0, 100).map(v => redact(v, depth + 1));
    const out = {};
    for (const [k, v] of Object.entries(obj)) {
        if (SENSITIVE_KEYS.has(k.toLowerCase())) {
            out[k] = '[redacted]';
        } else if (typeof v === 'string' && v.length > 2000) {
            out[k] = v.slice(0, 2000) + '... [truncated]';
        } else if (typeof v === 'object') {
            out[k] = redact(v, depth + 1);
        } else {
            out[k] = v;
        }
    }
    return out;
}

function format(level, message, context = {}) {
    const entry = {
        timestamp: new Date().toISOString(),
        level,
        message,
        ...redact(context),
    };
    return JSON.stringify(entry);
}

const logger = {
    debug(message, context = {}) {
        if (process.env.LOG_LEVEL === 'debug') {
            console.log(format('debug', message, context));
        }
    },
    info(message, context = {}) {
        console.log(format('info', message, context));
    },
    warn(message, context = {}) {
        console.warn(format('warn', message, context));
    },
    error(message, context = {}) {
        console.error(format('error', message, context));
    },
    requestLog(req, res, durationMs, extra = {}) {
        const level = res.statusCode >= 500 ? 'error'
                    : res.statusCode >= 400 ? 'warn' : 'info';
        console.log(format(level, `${req.method} ${req.originalUrl} ${res.statusCode}`, {
            requestId: req.requestId,
            method: req.method,
            route: req.originalUrl?.split('?')[0],
            status: res.statusCode,
            durationMs,
            userId: req.user?.id || req.admin?.id || null,
            ip: req.ip,
            userAgent: req.headers['user-agent']?.slice(0, 200),
            ...extra,
        }));
    },
};

module.exports = logger;
