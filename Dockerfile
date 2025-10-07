# syntax=docker/dockerfile:1

# -------- Base builder image --------
FROM node:20-alpine AS deps
WORKDIR /app

# Install dependencies based on lockfile
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund

# -------- Builder --------
FROM node:20-alpine AS builder
WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Disable telemetry
ENV NEXT_TELEMETRY_DISABLED=1

# Build
RUN npm run build

# -------- Production runtime (with Next standalone output) --------
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Create non-root user
RUN addgroup -g 1001 -S nodejs && adduser -S nextjs -u 1001

# Copy only the standalone production build
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
# Create public directory (Next.js will create it if needed)
RUN mkdir -p ./public

# Expose Next.js port
EXPOSE 3000
USER 1001

# Start the server
CMD ["node", "server.js"]
