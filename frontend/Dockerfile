# Flutter Environment-Aware Docker Image (Based on rebar-ahmad.medium.com article)
FROM nginx:stable

# Install Flutter dependencies and tools
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter SDK (specific version 3.27.1)
RUN git clone https://github.com/flutter/flutter.git -b 3.27.1 /flutter
ENV PATH="/flutter/bin:${PATH}"

# Pre-download Flutter web tools and enable web
RUN flutter doctor
RUN flutter config --enable-web

# Set working directory
WORKDIR /app

# Copy Flutter application
COPY . .

# Install dependencies
RUN flutter pub get

# Generate code (freezed, json_serializable, etc.)
RUN dart run build_runner build --delete-conflicting-outputs

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Copy and make entrypoint executable
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/ || exit 1

# Expose port
EXPOSE 8080

# Set custom entrypoint
ENTRYPOINT ["/entrypoint.sh"]