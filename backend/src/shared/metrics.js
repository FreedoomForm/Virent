/**
 * metrics.js — Prometheus-compatible metrics endpoint
 *
 * Per Backend Design System §20 (Observability): metrics are mandatory.
 * Per constitution §28 law 49: Observability DB обязательна.
 *
 * Exposes /metrics endpoint in Prometheus text format.
 * Metrics collected:
 *   - http_requests_total{method,route,status}
 *   - http_request_duration_seconds{method,route}
 *   - http_active_connections
 *   - db_connections_active
 *   - db_queries_total{operation}
 *   - cache_hits_total / cache_misses_total
 *   - ws_active_connections
 *   - trips_active
 *   - scooters_by_status{status}
 *   - users_total
 *   - otp_codes_active
 */

const cache = require('../shared/cache.js');

const counters = new Map();
const histograms = new Map();
const gauges = new Map();

function incCounter(name, labels = {}) {
  const key = `${name}:${JSON.stringify(labels)}`;
  counters.set(key, (counters.get(key) || 0) + 1);
}

function observeHistogram(name, value, labels = {}) {
  const key = `${name}:${JSON.stringify(labels)}`;
  if (!histograms.has(key)) histograms.set(key, { count: 0, sum: 0, values: [] });
  const h = histograms.get(key);
  h.count++;
  h.sum += value;
  h.values.push(value);
  if (h.values.length > 1000) h.values.shift();
}

function setGauge(name, value, labels = {}) {
  const key = `${name}:${JSON.stringify(labels)}`;
  gauges.set(key, value);
}

function formatPrometheus() {
  const lines = [];
  const seenMetrics = new Set();

  // Counters
  for (const [key, value] of counters) {
    const [name, labelsStr] = key.split(':', 2);
    const labels = JSON.parse(labelsStr);
    const labelStr = Object.entries(labels).map(([k, v]) => `${k}="${v}"`).join(',');
    if (!seenMetrics.has(name)) {
      lines.push(`# TYPE ${name} counter`);
      seenMetrics.add(name);
    }
    lines.push(`${name}{${labelStr}} ${value}`);
  }

  // Gauges
  for (const [key, value] of gauges) {
    const [name, labelsStr] = key.split(':', 2);
    const labels = JSON.parse(labelsStr);
    const labelStr = Object.entries(labels).map(([k, v]) => `${k}="${v}"`).join(',');
    if (!seenMetrics.has(name)) {
      lines.push(`# TYPE ${name} gauge`);
      seenMetrics.add(name);
    }
    lines.push(`${name}{${labelStr}} ${value}`);
  }

  // Histograms (simplified — just count and sum)
  for (const [key, h] of histograms) {
    const [name, labelsStr] = key.split(':', 2);
    const labels = JSON.parse(labelsStr);
    const labelStr = Object.entries(labels).map(([k, v]) => `${k}="${v}"`).join(',');
    const baseName = name.replace('_seconds', '');
    if (!seenMetrics.has(name)) {
      lines.push(`# TYPE ${name} histogram`);
      seenMetrics.add(name);
    }
    lines.push(`${name}_count{${labelStr}} ${h.count}`);
    lines.push(`${name}_sum{${labelStr}} ${h.sum.toFixed(4)}`);
    // Simple quantiles
    if (h.values.length > 0) {
      const sorted = [...h.values].sort((a, b) => a - b);
      const p50 = sorted[Math.floor(sorted.length * 0.5)];
      const p95 = sorted[Math.floor(sorted.length * 0.95)];
      const p99 = sorted[Math.floor(sorted.length * 0.99)];
      lines.push(`${name}{${labelStr},quantile="0.5"} ${p50.toFixed(4)}`);
      lines.push(`${name}{${labelStr},quantile="0.95"} ${p95.toFixed(4)}`);
      lines.push(`${name}{${labelStr},quantile="0.99"} ${p99.toFixed(4)}`);
    }
  }

  // Cache stats
  const cacheStats = cache.globalCache.stats();
  lines.push(`# TYPE cache_hit_rate gauge`);
  lines.push(`cache_hit_rate ${cacheStats.hitRate.toFixed(4)}`);
  lines.push(`# TYPE cache_size gauge`);
  lines.push(`cache_size ${cacheStats.size}`);

  return lines.join('\n') + '\n';
}

/**
 * Middleware to collect HTTP metrics
 */
function metricsMiddleware(req, res, next) {
  const start = Date.now();
  const route = req.route?.path || req.path || 'unknown';
  const method = req.method;

  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    const status = res.statusCode;
    incCounter('http_requests_total', { method, route, status: String(status) });
    observeHistogram('http_request_duration_seconds', duration, { method, route });
  });

  next();
}

/**
 * Periodically update DB-based gauges
 */
async function updateDbGauges() {
  try {
    const { getDb } = require('../shared/db.js');
    const db = await getDb();
    const [scooters, users, trips, otpCodes] = await Promise.all([
      db.collection('scooters').aggregate([{ $group: { _id: '$status', count: { $sum: 1 } } }]).toArray(),
      db.collection('users').countDocuments(),
      db.collection('trips').countDocuments({ status: 'active' }),
      db.collection('otp_codes').countDocuments({ used: false, expires_at: { $gt: new Date() } }),
    ]);
    for (const s of scooters) {
      setGauge('scooters_by_status', s.count, { status: s._id || 'unknown' });
    }
    setGauge('users_total', users);
    setGauge('trips_active', trips);
    setGauge('otp_codes_active', otpCodes);
  } catch (e) {
    // Silent fail — don't crash app
  }
}

// Update DB gauges every 60 seconds
setInterval(updateDbGauges, 60000);
// Initial update after 5 seconds
setTimeout(updateDbGauges, 5000);

module.exports = {
  metricsMiddleware,
  formatPrometheus,
  incCounter,
  observeHistogram,
  setGauge,
  updateDbGauges,
};
