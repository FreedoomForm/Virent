# Cloudflare Tunnel — PC as Global Server

Your PC becomes a **global server** — no VPS needed. Mobile apps connect
from anywhere in the world via a free Cloudflare Tunnel URL.

## How it works

```
+----------------------------+         +-----------------+
|  Your PC (Virent .exe)     |         |  Cloudflare     |
|                            |         |  Edge Network   |
|  +--------+  +----------+  |         |                 |
|  |Flutter |  | Embedded |  | tunnel  |  https://...    |<---- Mobile apps
|  | UI     |  | server   |<--------->|  trycloudflare  |      (anywhere)
|  |        |  | :8443    |  |         |                 |
|  +--------+  +----------+  |         |                 |
|              |             |         |                 |
|  cloudflared +-------------+         |                 |
+----------------------------+         +-----------------+
```

1. The Virent desktop app starts an HTTP server on port 8443.
2. `cloudflared` opens a persistent outbound connection to Cloudflare's
   edge network. No inbound ports need to be opened on your router.
3. Cloudflare assigns a public `https://*.trycloudflare.com` URL that
   forwards traffic to your PC through the tunnel.
4. Mobile apps (anywhere in the world) point at that URL.

## Quick start

1. Run the Virent desktop app (the embedded server starts on :8443).
2. From the repo root, run:

   ```bash
   bash start-tunnel.sh
   ```

3. The script prints a public URL, for example:

   ```
   https://virent-abc123.trycloudflare.com
   ```

4. In the mobile app, go to **Settings -> Server URL** and paste that
   URL.

5. Keep the terminal window open. Closing it tears down the tunnel.

## Commands

```bash
bash start-tunnel.sh            # start tunnel (prints public URL)
bash start-tunnel.sh --stop     # stop the running tunnel
bash start-tunnel.sh --status   # check whether cloudflared is running
```

The script auto-detects the OS (Windows / macOS / Linux) and downloads
`cloudflared` on first run if it isn't already installed.

## Environment overrides

| Variable     | Default | Purpose                                  |
|--------------|---------|------------------------------------------|
| `VIRENT_PORT`| `8443`  | Local port the tunnel forwards to        |

## Persistent URL (optional)

The quick-tunnel URL is random and changes every time you restart the
script. For a stable URL:

1. Create a free Cloudflare account and a named tunnel:

   ```bash
   cloudflared tunnel login
   cloudflared tunnel create virent
   cloudflared tunnel route dns virent virent.yourdomain.com
   ```

2. Add an ingress rule pointing the tunnel at `http://localhost:8443`:

   ```ini
   # ~/.cloudflared/config.yml
   tunnel: <tunnel-id>
   credentials-file: /root/.cloudflared/<tunnel-id>.json
   ingress:
     - hostname: virent.yourdomain.com
       service: http://localhost:8443
     - service: http_status:404
   ```

3. Run it:

   ```bash
   cloudflared tunnel run virent
   ```

Mobile apps then point at `https://virent.yourdomain.com` permanently.

## Security notes

- The quick-tunnel URL is unguessable but unauthenticated. Anyone who
  knows it can hit `/health` (and any other public endpoint). Sensitive
  admin endpoints (`/admin/...`) should be guarded by an admin token in
  production.
- All traffic between Cloudflare's edge and the mobile app is HTTPS, even
  though the link between your PC and Cloudflare uses HTTP. Cloudflare
  terminates TLS.
- The link between your PC and Cloudflare is *outbound only* — no ports
  need to be opened on your router / firewall. Your PC's IP address is
  never exposed to mobile clients.

## Troubleshooting

| Symptom                                   | Fix                                                       |
|-------------------------------------------|-----------------------------------------------------------|
| `ERROR: Virent server is not reachable`   | Start the Virent desktop app first.                       |
| Tunnel starts but mobile app can't connect| Make sure the URL in Settings is the full `https://...`.  |
| URL changes on every restart              | Set up a named tunnel (see "Persistent URL" above).       |
| `cloudflared: command not found`          | The script auto-downloads it; if it fails, install        |
|                                           | manually from cloudflare.com.                             |

## Comparison: embedded server vs. Cloudflare Tunnel vs. standalone backend

| Setup                         | Best for                              | Cost  |
|-------------------------------|---------------------------------------|-------|
| Embedded server only          | Home / office demos on a single WiFi  | Free  |
| Embedded + Cloudflare Tunnel  | One PC, mobile apps anywhere          | Free  |
| Standalone backend on a VPS   | 24/7 fleet, multi-admin, autoscale    | ~$5/mo|

All three expose the same API surface, so the mobile app's `Settings ->
Server URL` is the only thing that changes between them.
