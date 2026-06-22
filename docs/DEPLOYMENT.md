# Virent — Production Deployment Guide

## Option 1: Docker Compose (recommended for small-medium)

```bash
# 1. Clone
git clone https://github.com/FreedoomForm/Virent.git
cd Virent

# 2. Configure
cp .env.example .env
# Edit .env with production values:
#   MONGO_ROOT_PASSWORD=strong-password
#   JWT_SECRET=random-256-bit-secret
#   SMS_PROVIDER=eskiz
#   CLICK_MERCHANT_ID=your-id
#   etc.

# 3. Build and start
docker-compose up -d --build

# 4. Seed initial data (admin, cities, scooters)
docker-compose exec rest-api node /app/scripts/seed-db.js

# 5. Check health
curl http://localhost:8393/health
```

## Option 2: Manual deployment

### Backend
```bash
cd backend
npm install --production
# Set env vars in .env
node app.js
# Or with PM2:
pm2 start app.js --name sparkrentals-api -- -i max
```

### Frontend (webb-client)
```bash
cd frontend/webb-client
REACT_APP_WEBB_CLIENT_API_URL=https://api.yourdomain.com/v1 \
REACT_APP_WEBB_CLIENT_API=your-api-key \
npm run build
# Serve build/ with nginx
```

### Frontend (admin-dashboard)
```bash
cd frontend/admin-dashboard
REACT_APP_API_URL=https://api.yourdomain.com/v1 \
REACT_APP_REST_API_KEY=admin-api-key \
npm run build
# Serve build/ with nginx on different port/subdomain
```

### Mobile
```bash
cd mobile
# Set .env with production API URL
echo 'API_BASE_URL=https://api.yourdomain.com/v1' > .env
# Build APK via GitHub Actions or EAS:
eas build --platform android --profile preview
```

## Nginx configuration

See `infra/nginx/conf.d/default.conf` for full config.

Key settings:
- Rate limiting: 30 req/s for API, 5 req/min for auth
- SSL termination with Let's Encrypt
- Security headers (HSTS, X-Frame-Options, etc.)
- Gzip compression
- Static asset caching (1 year)

## MongoDB backup

```bash
# Daily backup cron:
0 2 * * * /path/to/backend/scripts/backup-mongodb.sh

# Monthly restore test:
# 1. Restore to test cluster
# 2. Run tests against restored data
# 3. Verify data integrity
# 4. Delete test cluster
```

## Monitoring

- Health: `GET /health`
- Metrics: `GET /metrics` (Prometheus format)
- System info: `GET /v1/system/info` (admin JWT)
- Logs: Structured JSON, view with `docker-compose logs rest-api`

## SSL certificates (Let's Encrypt)

```bash
# With certbot:
certbot certonly --webroot -w /var/www/html -d api.yourdomain.com
# Or with Docker:
docker run -it --rm -v /etc/letsencrypt:/etc/letsencrypt \
  -v /var/www/html:/var/www/html \
  certbot/certbot certonly --webroot -w /var/www/html -d api.yourdomain.com
```

## Scaling considerations

1. **MongoDB**: Add replica set for HA, read replicas for admin analytics
2. **Redis**: Add for L2 cache, session store, rate limiter
3. **CDN**: Serve frontend static assets via CloudFlare/CloudFront
4. **Load balancer**: Multiple API instances behind nginx/HAProxy
5. **MQTT broker**: Scale Mosquitto with cluster mode for >1000 scooters
6. **Search**: Migrate to Elasticsearch for >100K records
7. **Analytics**: Move heavy queries to ClickHouse/BigQuery
