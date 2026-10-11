# Use lightweight node alpine base
FROM node:20-alpine

# Set node environment
ENV NODE_ENV=production

WORKDIR /app

# 1. Cache npm dependencies layer: copy package files first
COPY package*.json ./

# Install only production dependencies cleanly
RUN npm install --omit=dev

# 2. Security: Switch to built-in non-root 'node' user
USER node

# 3. Copy application files with proper ownership
COPY --chown=node:node . .

EXPOSE 4000

# Exec form CMD for signal handling
CMD ["node", "index.js"]
