# ==========================================
# STAGE 1: Builder (Heavy build environment)
# ==========================================
FROM node:20-alpine AS builder

WORKDIR /app

# Cache package dependencies
COPY package*.json ./
RUN npm install

# Copy source code and build production assets
COPY . .
RUN npm run build

# ==========================================
# STAGE 2: Runtime (Ultra-lightweight web server)
# ==========================================
FROM nginx:alpine AS runner

# Copy custom Nginx configuration for SPA routing
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy compiled static assets from builder stage
COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 80

# Nginx starts in foreground by default in official image
CMD ["nginx", "-g", "daemon off;"]
