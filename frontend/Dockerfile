# Multi-Stage Build für Flutter Web mit Nginx
FROM ghcr.io/cirruslabs/flutter:3.27.1 AS builder

# Set working directory
WORKDIR /app

# Copy pubspec files first for better Docker layer caching
COPY pubspec.yaml pubspec.lock ./

# Install dependencies
RUN flutter pub get

# Copy source code
COPY . .

# Build arguments for Supabase configuration
ARG SUPABASE_URL
ARG SUPABASE_ANON_KEY
ARG SUPABASE_SERVICE_ROLE_KEY

# Enable web platform (if not already enabled)
RUN flutter config --enable-web

# Build Flutter web app for production
RUN flutter build web --release --web-renderer canvaskit --base-href /

# Production stage with Nginx
FROM nginx:1.25-alpine

# Install curl for health checks
RUN apk --no-cache add curl

# Remove default nginx website
RUN rm -rf /usr/share/nginx/html/*

# Copy built Flutter web app
COPY --from=builder /app/build/web /usr/share/nginx/html

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/ || exit 1

# Expose port
EXPOSE 8080

# Start nginx
CMD ["nginx", "-g", "daemon off;"]