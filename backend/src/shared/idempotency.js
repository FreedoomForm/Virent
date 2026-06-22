/**
 * idempotency.js — Idempotency key middleware
 * Per Backend Design System §36: "Idempotency key needed for repeatable write requests"
 *
 * Usage:
 *   router.post('/trips:end', idempotency.middleware(), controller.end);
 *   Client sends: Idempotency-Key: <uuid>
 *   If same key seen again → return cached response
 */
const crypto = require('crypto');
const cache = new Map(); // L1: in-memory. L2: Redis in production.

function middleware() {
  return (req, res, next) => {
    const key = req.headers['idempotency-key'];
    if (!key) return next(); // Optional — skip if not provided

    const cacheKey = `${req.user?.id || 'anon'}:${req.method}:${req.path}:${key}`;
    if (cache.has(cacheKey)) {
      const cached = cache.get(cacheKey);
      return res.status(cached.status).json(cached.body);
    }

    // Intercept res.json to cache response
    const originalJson = res.json.bind(res);
    res.json = function(body) {
      if (res.statusCode >= 200 && res.statusCode < 300) {
        cache.set(cacheKey, { status: res.statusCode, body });
        // Auto-expire after 24 hours
        setTimeout(() => cache.delete(cacheKey), 24 * 60 * 60 * 1000);
      }
      return originalJson(body);
    };
    next();
  };
}

module.exports = { middleware, cache };
