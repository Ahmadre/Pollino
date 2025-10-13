#!/bin/bash -eu

echo "Building Flutter app with runtime environment variables..."
echo "SUPABASE_URL: ${SUPABASE_URL}"

# Build Flutter web app with runtime environment variables
flutter build web --release \
    --base-href / \
    --dart-define WEB_APP_URL="${WEB_APP_URL}" \
    --dart-define SUPABASE_URL="${SUPABASE_URL}" \
    --dart-define SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}" \
    --dart-define SUPABASE_SERVICE_ROLE_KEY="${SUPABASE_SERVICE_ROLE_KEY}"

# Copy built files to nginx web directory
chmod -R 755 /usr/share/nginx/html
rm -rf /usr/share/nginx/html/* 2>/dev/null || true
cp -r /app/build/web/* /usr/share/nginx/html/

echo "Starting Nginx server..."
nginx -g "daemon off;"