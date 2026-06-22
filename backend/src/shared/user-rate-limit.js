/**
 * user-rate-limit.js — Per-user rate limiting
 * Per constitution §19: rate limiting on expensive operations
 *
 * Limits per user (identified by JWT):
 *   - trip/reserve: 5 per hour (anti-abuse)
 *   - trip/end: 10 per hour
 *   - support/create: 10 per hour
 *   - transactions/topup: 5 per hour
 */
const rateMap = new Map(); // userId:action → { count, windowStart }

const LIMITS = {
  'trip:reserve': { max: 5, windowMs: 3600000 },
  'trip:end': { max: 10, windowMs: 3600000 },
  'trip:cancel': { max: 10, windowMs: 3600000 },
  'support:create': { max: 10, windowMs: 3600000 },
  'topup': { max: 5, windowMs: 3600000 },
  'promo:redeem': { max: 20, windowMs: 3600000 },
};

function check(userId, action) {
  const limit = LIMITS[action];
  if (!limit) return { allowed: true };
  
  const key = `${userId}:${action}`;
  const now = Date.now();
  let entry = rateMap.get(key);
  
  if (!entry || now - entry.windowStart > limit.windowMs) {
    entry = { count: 1, windowStart: now };
    rateMap.set(key, entry);
    return { allowed: true, remaining: limit.max - 1 };
  }
  
  entry.count++;
  if (entry.count > limit.max) {
    return { allowed: false, remaining: 0, retryAfterMs: limit.windowMs - (now - entry.windowStart) };
  }
  
  return { allowed: true, remaining: limit.max - entry.count };
}

function middleware(action) {
  return (req, res, next) => {
    const userId = req.user?.id || req.admin?.id || 'anonymous';
    const result = check(userId, action);
    if (!result.allowed) {
      return res.status(429).json({
        errors: {
          status: 429,
          title: 'Rate limit exceeded',
          detail: `Too many ${action} requests. Try again in ${Math.ceil(result.retryAfterMs / 1000)}s`,
        }
      });
    }
    res.setHeader('X-RateLimit-Remaining', result.remaining);
    next();
  };
}

module.exports = { middleware, check, LIMITS };
