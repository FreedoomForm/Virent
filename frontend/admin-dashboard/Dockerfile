# SparkRentals Admin Dashboard Dockerfile
FROM node:20-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci --no-audit --no-fund || npm install --no-audit --no-fund

COPY . .

ARG REACT_APP_API_URL
ARG REACT_APP_REST_API_KEY

ENV REACT_APP_API_URL=$REACT_APP_API_URL
ENV REACT_APP_REST_API_KEY=$REACT_APP_REST_API_KEY

RUN CI=true DISABLE_ESLINT_PLUGIN=true npm run build

FROM nginx:alpine
COPY --from=builder /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
