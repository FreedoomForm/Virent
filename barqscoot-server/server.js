/**
 * BarqScoot Local Server — REST API for BarqScoot Android app
 *
 * Runs on the user's Windows PC. The BarqScoot Android app connects to it
 * via the local network (PC's IP address, port 8443).
 *
 * Endpoints mirror what BarqScoot's Flutter client expects:
 *   POST /auth/phone/send-code    — send OTP via SMS
 *   POST /auth/phone/verify       — verify OTP, return JWT
 *   GET  /scooters/nearby         — list scooters near a location
 *   POST /trips/start             — start a ride
 *   POST /trips/end               — end a ride
 *   GET  /users/me                — current user profile
 *   GET  /wallet                  — wallet balance and transactions
 *   GET  /health                  — health check
 *
 * Data is stored in-memory (resets on restart). This is a demo server
 * for side-by-side comparison with Virent — not for production.
 */

const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const crypto = require('crypto');

const app = express();
const PORT = process.env.PORT || 8443;

app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

// ============ In-memory data ============
const scooters = [
  { id: 's1', name: 'BarqScoot#1', lat: 41.3111, lng: 69.2406, battery: 92, status: 'available', rate_per_min: 1200 },
  { id: 's2', name: 'BarqScoot#2', lat: 41.3120, lng: 69.2410, battery: 78, status: 'available', rate_per_min: 1200 },
  { id: 's3', name: 'BarqScoot#3', lat: 41.3100, lng: 69.2390, battery: 45, status: 'low_battery', rate_per_min: 1200 },
  { id: 's4', name: 'BarqScoot#4', lat: 41.3130, lng: 69.2420, battery: 88, status: 'available', rate_per_min: 1200 },
  { id: 's5', name: 'BarqScoot#5', lat: 41.3090, lng: 69.2380, battery: 100, status: 'available', rate_per_min: 1200 },
];

const users = new Map();
const trips = new Map();
const otpCodes = new Map();
const transactions = new Map();

let currentUser = null;

// ============ Routes ============

app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'BarqScoot Local Server', version: '1.0.0', uptime: process.uptime() });
});

// ---- Auth ----
app.post('/auth/phone/send-code', (req, res) => {
  const { phone } = req.body;
  if (!phone) return res.status(400).json({ error: 'phone required' });
  const code = String(Math.floor(100000 + Math.random() * 900000));
  otpCodes.set(phone, { code, expires: Date.now() + 5 * 60 * 1000 });
  console.log(`[OTP] ${phone}: ${code} (valid 5 min)`);
  res.json({ success: true, message: 'OTP sent', verificationId: crypto.randomUUID() });
});

app.post('/auth/phone/verify', (req, res) => {
  const { phone, code } = req.body;
  const stored = otpCodes.get(phone);
  if (!stored || stored.code !== code || stored.expires < Date.now()) {
    return res.status(401).json({ error: 'Invalid or expired OTP' });
  }
  otpCodes.delete(phone);
  let user = users.get(phone);
  if (!user) {
    user = {
      id: crypto.randomUUID(),
      phone,
      name: `User ${phone.slice(-4)}`,
      email: null,
      balance: 50000,
      created_at: new Date().toISOString(),
      trips_count: 0,
    };
    users.set(phone, user);
    transactions.set(user.id, [
      { id: crypto.randomUUID(), type: 'bonus', amount: 50000, description: 'Welcome bonus', created_at: new Date().toISOString() },
    ]);
  }
  currentUser = user;
  const token = crypto.randomBytes(32).toString('hex');
  res.json({ success: true, token, user });
});

// ---- Scooters ----
app.get('/scooters/nearby', (req, res) => {
  const { lat, lng, radius = 2000 } = req.query;
  const userLat = parseFloat(lat) || 41.3111;
  const userLng = parseFloat(lng) || 69.2406;
  // Simple distance filter (demo only)
  const nearby = scooters.filter(s => {
    const dist = Math.sqrt(
      Math.pow((s.lat - userLat) * 111000, 2) +
      Math.pow((s.lng - userLng) * 111000 * Math.cos(userLat * Math.PI / 180), 2)
    );
    return dist <= radius;
  }).map(s => ({ ...s, distance: Math.round(Math.sqrt(Math.pow((s.lat - userLat) * 111000, 2) + Math.pow((s.lng - userLng) * 111000, 2))) }));
  res.json({ scooters: nearby });
});

app.get('/scooters/:id', (req, res) => {
  const scooter = scooters.find(s => s.id === req.params.id);
  if (!scooter) return res.status(404).json({ error: 'Scooter not found' });
  res.json({ scooter });
});

// ---- Trips ----
app.post('/trips/start', (req, res) => {
  if (!currentUser) return res.status(401).json({ error: 'Not authenticated' });
  const { scooter_id } = req.body;
  const scooter = scooters.find(s => s.id === scooter_id);
  if (!scooter) return res.status(404).json({ error: 'Scooter not found' });
  if (scooter.status !== 'available') return res.status(409).json({ error: 'Scooter not available' });
  scooter.status = 'in_use';
  const trip = {
    id: crypto.randomUUID(),
    user_id: currentUser.id,
    scooter_id,
    start_time: new Date().toISOString(),
    start_battery: scooter.battery,
    status: 'active',
    cost: 0,
  };
  trips.set(trip.id, trip);
  res.json({ success: true, trip });
});

app.post('/trips/end', (req, res) => {
  if (!currentUser) return res.status(401).json({ error: 'Not authenticated' });
  const { trip_id } = req.body;
  const trip = trips.get(trip_id);
  if (!trip || trip.status !== 'active') return res.status(404).json({ error: 'Active trip not found' });
  trip.end_time = new Date().toISOString();
  const duration_min = Math.max(1, Math.round((new Date(trip.end_time) - new Date(trip.start_time)) / 60000));
  const scooter = scooters.find(s => s.id === trip.scooter_id);
  trip.cost = duration_min * (scooter?.rate_per_min || 1200);
  trip.duration_min = duration_min;
  trip.status = 'completed';
  if (scooter) {
    scooter.status = 'available';
    scooter.battery = Math.max(0, scooter.battery - Math.round(duration_min * 2));
  }
  if (currentUser.balance >= trip.cost) {
    currentUser.balance -= trip.cost;
    currentUser.trips_count = (currentUser.trips_count || 0) + 1;
    const userTx = transactions.get(currentUser.id) || [];
    userTx.push({
      id: crypto.randomUUID(),
      type: 'trip_payment',
      amount: -trip.cost,
      description: `Trip ${trip.id.slice(0, 8)}`,
      created_at: new Date().toISOString(),
    });
    transactions.set(currentUser.id, userTx);
  }
  res.json({ success: true, trip });
});

app.get('/trips', (req, res) => {
  if (!currentUser) return res.status(401).json({ error: 'Not authenticated' });
  const userTrips = Array.from(trips.values()).filter(t => t.user_id === currentUser.id);
  res.json({ trips: userTrips });
});

// ---- User / Wallet ----
app.get('/users/me', (req, res) => {
  if (!currentUser) return res.status(401).json({ error: 'Not authenticated' });
  res.json({ user: currentUser });
});

app.get('/wallet', (req, res) => {
  if (!currentUser) return res.status(401).json({ error: 'Not authenticated' });
  const tx = transactions.get(currentUser.id) || [];
  res.json({ balance: currentUser.balance, currency: 'UZS', transactions: tx });
});

app.post('/wallet/topup', (req, res) => {
  if (!currentUser) return res.status(401).json({ error: 'Not authenticated' });
  const { amount } = req.body;
  if (!amount || amount <= 0) return res.status(400).json({ error: 'Invalid amount' });
  currentUser.balance += amount;
  const userTx = transactions.get(currentUser.id) || [];
  userTx.push({
    id: crypto.randomUUID(),
    type: 'topup',
    amount,
    description: 'Top-up',
    created_at: new Date().toISOString(),
  });
  transactions.set(currentUser.id, userTx);
  res.json({ success: true, new_balance: currentUser.balance });
});

// ============ Start ============
app.listen(PORT, '0.0.0.0', () => {
  console.log('=========================================================');
  console.log(`  BarqScoot Local Server`);
  console.log(`  Listening on http://0.0.0.0:${PORT}`);
  console.log(`  Health check: http://localhost:${PORT}/health`);
  console.log(`  Scooters nearby: http://localhost:${PORT}/scooters/nearby?lat=41.3111&lng=69.2406`);
  console.log('');
  console.log(`  For BarqScoot Android app:`);
  console.log(`    1. Find your PC's local IP (run 'ipconfig' in cmd)`);
  console.log(`    2. In the Android app, set API base URL to:`);
  console.log(`       http://<YOUR_PC_IP>:${PORT}`);
  console.log('=========================================================');
});
