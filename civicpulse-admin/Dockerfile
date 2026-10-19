# Multi-stage Dockerfile for CivicPulse Admin Dashboard (React + TypeScript + Vite)
# Stage 1: Build static distribution
FROM node:22-alpine AS builder

WORKDIR /app

# Copy package manifests first to leverage Docker layer caching
COPY package.json package-lock.json ./
RUN npm ci

# Copy project source files and build production SPA bundle
COPY . .
RUN npm run build

# Stage 2: Minimal hardened Nginx runner
FROM nginx:1.27-alpine AS runner

# Remove default nginx website
RUN rm -rf /usr/share/nginx/html/*

# Copy built artifacts and custom Nginx config
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=15s --timeout=5s --retries=3 --start-period=10s \
  CMD wget -q --spider http://localhost:80/health || exit 1

CMD ["nginx", "-g", "daemon off;"]
