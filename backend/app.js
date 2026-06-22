require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const path = require('path');
const cors = require('cors');
const fs = require('fs');
const helmet = require('helmet');
const compression = require('compression');
const metrics = require('./src/shared/metrics.js');
var cookieParser = require('cookie-parser')
var session = require('express-session')
var cluster = require("cluster"); // Load Balancer
var filter = require('content-filter') // reliable security for MongoDB applications against the injection attacks
require("./v1/auth/passport");

// Ensure DB indexes on startup (async, doesn't block server start)
require('./v1/models/db_indexes.js').ensureIndexes().catch(e =>
    console.error('[startup] index creation failed:', e.message));

// Using version 1
const v1 = require("./v1/index.js");

// Server port
const port = process.env.REST_API_PORT || 8393;

const RateLimit = require('express-rate-limit');
const passport = require('passport');

// Global rate limiter — generous, allows normal usage
const apiLimiter = RateLimit({
    windowMs: 1 * 60 * 1000,
    max: 1000,
    standardHeaders: true,
    legacyHeaders: false,
});

// Strict rate limiter for authentication endpoints (anti-brute-force)
const authLimiter = RateLimit({
    windowMs: 15 * 60 * 1000, // 15 min
    max: 10,                  // 10 attempts per 15 min per IP
    standardHeaders: true,
    legacyHeaders: false,
    message: { errors: { status: 429, title: "Too many attempts",
        detail: "Please wait 15 minutes before trying again." } },
});

// Strict rate limiter for OTP sending (anti-SMS-spam)
const otpLimiter = RateLimit({
    windowMs: 1 * 60 * 1000, // 1 min
    max: 1,                  // 1 OTP per minute per IP
    standardHeaders: true,
    legacyHeaders: false,
    message: { errors: { status: 429, title: "Too many OTP requests",
        detail: "Please wait 60 seconds." } },
});

// Strict rate limiter for registrations
const registerLimiter = RateLimit({
    windowMs: 1 * 60 * 60 * 1000, // 1 hour
    max: 5,                       // 5 registrations per hour per IP
    standardHeaders: true,
    legacyHeaders: false,
    message: { errors: { status: 429, title: "Too many registrations",
        detail: "Please wait before registering again." } },
});

// Mutation rate limiter (write operations)
const mutationLimiter = RateLimit({
    windowMs: 1 * 60 * 1000,
    max: 60, // 60 mutations per minute per IP
    standardHeaders: true,
    legacyHeaders: false,
});

const app = express();

app.use(apiLimiter);
app.disable('x-powered-by');

// Security headers (helmet) — adjusted to allow inline scripts/styles for our app
app.use(helmet({
    contentSecurityPolicy: false, // disable CSP for now — would need careful tuning
    crossOriginEmbedderPolicy: false,
    crossOriginResourcePolicy: { policy: 'cross-origin' }, // allow uploads to be embedded
}));

// Gzip compression for all responses
app.use(compression());
app.use(metrics.metricsMiddleware);

app.set("view engine", "ejs");

app.use(cors({
    origin: [
        "http://sparkrentals.software:3000",
        "http://sparkrentals.software:1337",
        "http://localhost:3000",
        "http://localhost:1337",
        "http://localhost:8081", // Expo mobile dev
    ],
    credentials: true,
}));
app.options('*', cors());

app.use(cookieParser(process.env.COOKIE_KEY));

// Custom Morgan format that strips query strings (avoid leaking tokens in logs)
const morgan = require('morgan');
morgan.format('sparkrentals', ':method :url :status :res[content-length] - :response-time ms - :remote-addr');
app.use(morgan('sparkrentals'));

app.use(session({
    secret: process.env.COOKIE_KEY,
    resave: false,
    saveUninitialized: true,
    cookie: { secure: process.env.NODE_ENV === 'production' }
}));

app.use(passport.initialize());
app.use(passport.session());

// Body parsers with size limits (security)
app.use(bodyParser.json({ limit: '1mb' }));
app.use(bodyParser.urlencoded({ extended: true, limit: '1mb' }));

// Multipart for file uploads
const multer = require('multer');
const upload = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: 5 * 1024 * 1024 }, // 5 MB
});

// Static: API docs
app.use(express.static(path.join(__dirname, "public")));

// Static: uploaded files (photos for parking proof, breakdowns, etc.)
const UPLOAD_DIR = process.env.UPLOAD_DIR || '/home/z/my-project/uploads';
fs.mkdirSync(UPLOAD_DIR, { recursive: true });
app.use('/uploads', express.static(UPLOAD_DIR));

app.use(filter());

// Health check endpoint (for monitoring / k8s probes)
app.get('/health', (req, res) => {
    res.status(200).json({ status: 'ok', timestamp: new Date().toISOString(),
});

// Prometheus metrics endpoint
app.get('/metrics', (req, res) => {
  res.setHeader('Content-Type', 'text/plain; version=0.0.4');
  res.status(200).send(metrics.formatPrometheus());
});
                           version: '1.0.0' });
});

// System info endpoint (admin only — uses API key check below via v1 router)
// We expose this at /v1/system instead.

// Expose rate limiters + multer to v1 router via app.locals
app.locals.authLimiter = authLimiter;
app.locals.otpLimiter = otpLimiter;
app.locals.registerLimiter = registerLimiter;
app.locals.mutationLimiter = mutationLimiter;
app.locals.upload = upload;

// Request ID middleware (applied to all routes)
app.use((req, res, next) => {
    req.requestId = req.headers['x-request-id'] || 'req_' + require('crypto').randomBytes(8).toString('hex');
    res.setHeader('X-Request-Id', req.requestId);
    next();
});

// New modular routes (Clean Architecture per constitution) — mounted BEFORE v1 legacy
const tripsRoutes = require('./src/modules/trips/api/trip.routes.js');
const viewsRoutes = require('./src/views/routes.js');
app.use("/v1/trips-v2", tripsRoutes);
app.use("/v1/views", viewsRoutes);

// Legacy v1 router
app.use("/v1", v1);

// 404 handler
app.use((req, res) => {
    res.status(404).json({ errors: { status: 404, source: req.path,
        title: "Not found", detail: `Path ${req.path} not found` }});
});

// Global error handler — never leak stack traces in production
app.use((err, req, res, next) => {
    console.error('[unhandled error]', err);
    const isProd = process.env.NODE_ENV === 'production';
    res.status(err.status || 500).json({
        errors: {
            status: err.status || 500,
            source: req.path,
            title: err.title || 'Internal server error',
            detail: isProd ? 'An error occurred' : (err.message || 'Unknown error'),
            ...(isProd ? {} : { stack: err.stack }),
        }
    });
});

// Catch unhandled promise rejections so they don't crash the process
process.on('unhandledRejection', (reason, promise) => {
    console.error('[unhandledRejection]', reason);
});
process.on('uncaughtException', (err) => {
    console.error('[uncaughtException]', err);
});

// Cron jobs: run periodic maintenance tasks
const tripsModel = require('./v1/models/trips.js');
const geofencingModel = require('./v1/models/geofencing.js');

// Every 1 minute: expire stale reservations, check geofencing violations
setInterval(async () => {
    try {
        await tripsModel.expireStaleReservations();
    } catch (e) { console.error('[cron] expireStaleReservations:', e.message); }
}, 60 * 1000);

// Every 5 minutes: check active trip zone violations
setInterval(async () => {
    try {
        await geofencingModel.checkActiveTripViolations();
    } catch (e) { console.error('[cron] checkActiveTripViolations:', e.message); }
}, 5 * 60 * 1000);

// Every 10 minutes: flag long-running trips for review
setInterval(async () => {
    try {
        await tripsModel.autoEndLongTrips();
// Every hour: auto-schedule maintenance for scooters needing it
setInterval(async () => {
    try {
        const { scheduleAutoMaintenance } = require('./src/modules/maintenance/scheduler.js');
        await scheduleAutoMaintenance();
    } catch (e) { console.error('[cron] scheduleAutoMaintenance:', e.message); }
}, 60 * 60 * 1000);
    } catch (e) { console.error('[cron] autoEndLongTrips:', e.message); }
// Every hour: auto-schedule maintenance for scooters needing it
setInterval(async () => {
    try {
        const { scheduleAutoMaintenance } = require('./src/modules/maintenance/scheduler.js');
        await scheduleAutoMaintenance();
    } catch (e) { console.error('[cron] scheduleAutoMaintenance:', e.message); }
}, 60 * 60 * 1000);
}, 10 * 60 * 1000);

if (process.env.API_CLUSTER) {
    if (cluster.isPrimary) {
        console.log(`Primary ${process.pid} is running`);
        var cpuCount = require('os').cpus().length;
        console.log(`Total CPU ${cpuCount}`);
        for (var worker = 0; worker < cpuCount; worker += 1) {
            cluster.fork();
        }
        cluster.on('exit', function () { cluster.fork(); })
    } else {
        const server = app.listen(port, () => console.log(`Worker ID ${process.pid}, is running on http://localhost:` + port));
        // Attach WebSocket server for real-time updates
        try {
            const wsServer = require('./src/realtime/ws-server.js');
            wsServer.attach(server);
        } catch (e) { console.error('[ws] failed to attach:', e.message); }
    }
} else {
    const server = app.listen(port, () => console.log(`Worker ID ${process.pid}, is running on http://localhost:` + port));
    // Attach WebSocket server for real-time updates
    try {
        const wsServer = require('./src/realtime/ws-server.js');
        wsServer.attach(server);
    } catch (e) { console.error('[ws] failed to attach:', e.message); }
}
