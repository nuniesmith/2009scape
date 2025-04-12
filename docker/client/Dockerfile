###############################
# Stage 1: Builder
###############################
FROM rust:1.86-alpine AS builder

# Build arguments for customization
ARG BUILD_MODE=release
ARG SKIP_TESTS=true

# Install build dependencies
RUN apk add --no-cache \
    git \
    build-base \
    pkgconfig \
    openssl-dev \
    ca-certificates \
    musl-dev

WORKDIR /app

# Copy Cargo files
COPY Cargo.toml Cargo.lock* ./

# Cache dependencies
RUN mkdir -p src && \
    mkdir -p src/bin && \
    echo "fn main() {println!(\"placeholder\");}" > src/bin/client.rs && \
    echo "pub fn placeholder() {}" > src/lib.rs && \
    cargo build --release && \
    rm -rf src

# Copy actual source code
COPY src ./src

# Build the application
RUN if [ "$SKIP_TESTS" = "false" ]; then \
        cargo test --release; \
    fi && \
    cargo build --release

###############################
# Stage 2: Runtime
###############################
FROM alpine:latest

# Build arguments for customization
ARG USER_NAME=bob
ARG USER_ID=1098
ARG GROUP_ID=1098
ARG VNC_PASSWORD=password
ARG SCREEN_RESOLUTION=1024x768x16

# Install runtime dependencies
RUN apk add --no-cache \
    ca-certificates \
    openssl \
    x11vnc \
    xvfb \
    supervisor \
    python3 \
    curl \
    tini \
    netcat-openbsd \
    procps \
    unzip

# Create non-root user
RUN addgroup -g ${GROUP_ID} ${USER_NAME} && \
    adduser -D -u ${USER_ID} -G ${USER_NAME} ${USER_NAME}

# Set up working directory
WORKDIR /app

# Copy the built binary from builder stage
COPY --from=builder /app/target/release/client /app/

# Get latest noVNC
RUN mkdir -p /app/noVNC && \
    curl -L -o /tmp/novnc.zip https://github.com/novnc/noVNC/archive/v1.3.0.zip && \
    unzip /tmp/novnc.zip -d /tmp && \
    mv /tmp/noVNC-1.3.0/* /app/noVNC/ && \
    rm -rf /tmp/novnc.zip /tmp/noVNC-1.3.0

# Copy web UI and config files
COPY web/dist /app/web
COPY config /app/config

# Create supervisor configuration
RUN mkdir -p /etc/supervisor.d
COPY <<EOF /etc/supervisor.d/services.ini
[supervisord]
nodaemon=true
user=root

[program:xvfb]
command=Xvfb :1 -screen 0 %(ENV_SCREEN_RESOLUTION)s
autorestart=true
priority=10

[program:x11vnc]
command=x11vnc -xkb -noxrecord -noxfixes -noxdamage -display :1 -forever -shared -passwd %(ENV_VNC_PASSWORD)s
autorestart=true
priority=20

[program:novnc]
command=python3 /app/noVNC/utils/novnc_proxy --vnc localhost:5900 --listen 6080
autorestart=true
priority=30

[program:client]
command=/app/client
environment=DISPLAY=:1,SERVER_HOST=%(ENV_RS2009_SERVER_HOST)s,SERVER_PORT=%(ENV_RS2009_SERVER_PORT)s,WEBSOCKET_PORT=%(ENV_RS2009_WEBSOCKET_PORT)s
autorestart=true
user=%(ENV_USER_NAME)s
priority=40
EOF

# Create directories and set permissions
RUN mkdir -p /home/${USER_NAME}/.vnc /home/${USER_NAME}/.config && \
    echo "${VNC_PASSWORD}" | x11vnc -storepasswd /home/${USER_NAME}/.vnc/passwd && \
    chmod 600 /home/${USER_NAME}/.vnc/passwd && \
    chown -R ${USER_NAME}:${USER_NAME} /home/${USER_NAME} && \
    chown -R ${USER_NAME}:${USER_NAME} /app

# Create cache directories if they don't exist
RUN mkdir -p /app/cache && chown -R ${USER_NAME}:${USER_NAME} /app/cache

# Expose ports
EXPOSE 5900 6080 8080

# Set environment variables
ENV USER_NAME=${USER_NAME} \
    VNC_PASSWORD=${VNC_PASSWORD} \
    SCREEN_RESOLUTION=${SCREEN_RESOLUTION} \
    RS2009_SERVER_HOST=app \
    RS2009_SERVER_PORT=43594 \
    RS2009_WEBSOCKET_PORT=8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
  CMD nc -z localhost 6080 || exit 1

# Use tini as init system with supervisor
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor.d/services.ini"]