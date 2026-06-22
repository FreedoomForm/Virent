# SparkRentals REST API Dockerfile
#
# Multi-stage build for smaller image
# Per Backend Design System §22: documented deployment

# ===== Stage 1: Build =====
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files first for better caching
COPY package*.json ./
RUN npm ci --no-audit --no-fund || npm install --no-audit --no-fund

# Copy source
COPY . .

# ===== Stage 2: Runtime =====
FROM node:20-alpine AS runtime

# Install curl for healthcheck
RUN apk add --no-cache curl tini

WORKDIR /app

# Copy from builder
COPY --from=builder /app ./

# Create uploads dir
RUN mkdir -p /app/uploads /app/logs

# Use non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 -G nodejs
RUN chown -R nodejs:nodejs /app
USER nodejs

EXPOSE 8393

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8393/health || exit 1

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["node", "app.js"]
