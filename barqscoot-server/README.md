# BarqScoot Local Server

> REST API server for the BarqScoot Android app. Runs on your Windows PC.

## Why this exists

BarqScoot's original Flutter app expects a backend API. To do a fair side-by-side comparison with Virent (which has its own backend), we run a local BarqScoot server on the same PC. Both apps then connect to `localhost` — same network conditions, same comparison.

## Quick start

```bash
cd barqscoot-server
npm install
npm start
```

The server starts on port **8443**. Open `http://localhost:8443/health` to verify.

## Connect the BarqScoot Android app

1. Run the BarqScoot APK (downloaded from the Windows desktop app)
2. In the app's settings, set the API base URL to:
   - **Emulator:** `http://10.0.2.2:8443`
   - **Physical device on same WiFi:** `http://<YOUR_PC_IP>:8443` (find via `ipconfig`)
3. Sign up with any phone number — OTP is printed in the server console

## API endpoints

```text
GET  /health                       — health check
POST /auth/phone/send-code         — send OTP (printed to server console)
POST /auth/phone/verify            — verify OTP, returns JWT + user
GET  /scooters/nearby?lat=&lng=    — list nearby scooters
GET  /scooters/:id                 — scooter detail
POST /trips/start                  — start a ride
POST /trips/end                    — end a ride
GET  /trips                        — trip history
GET  /users/me                     — current user profile
GET  /wallet                       — balance + transactions
POST /wallet/topup                 — top up balance
```

## Comparison with Virent backend

| Property | Virent (Node.js + MongoDB) | BarqScoot (this server) |
|----------|----------------------------|--------------------------|
| Database | MongoDB (persistent) | In-memory (resets on restart) |
| Auth | Email/password + OTP + Google OAuth + 2FA TOTP | Phone OTP only |
| Scooters | Real MQTT/IoT integration | Static demo list |
| Trips | Real cost calc with zones + tax + promos | Simple per-minute rate |
| WebSocket | Yes (live dashboard updates) | No |
| Production-ready | Yes | No (demo only) |

This server exists purely so you can test the BarqScoot Android app side-by-side with Virent. It is NOT production-ready.
