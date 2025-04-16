###############################
# Stage 1: Builder
###############################
FROM eclipse-temurin:11-alpine AS builder

# Build arguments for customization
ARG BUILD_MODE=release
ARG SKIP_TESTS=true

# Install build dependencies
RUN apk add --no-cache \
    git \
    build-base \
    ca-certificates \
    gradle \
    wget \
    curl

# Clone the repository
WORKDIR /app
RUN git clone https://gitlab.com/2009scape/09launcher.git . && \
    chmod +x ./gradlew

# Try to build from source first, if that fails download a pre-built JAR
RUN (./gradlew build --no-daemon || \
     (echo "Regular build failed, trying with wrapper task..." && \
      ./gradlew wrapper --gradle-version=6.8 --distribution-type=bin && \
      ./gradlew build --no-daemon) || \
     (echo "Build failed, downloading pre-built JAR instead..." && \
      mkdir -p build/libs && \
      (wget -O build/libs/09launcher.jar https://gitlab.com/2009scape/09launcher/-/jobs/artifacts/master/raw/build/libs/09launcher.jar?job=build || \
       wget -O build/libs/09launcher.jar https://github.com/2009scape/09launcher/releases/download/latest/09launcher.jar || \
       curl -L -o build/libs/09launcher.jar https://gitlab.com/2009scape/09launcher/-/jobs/artifacts/master/download?job=build)))

# Verify that we have a JAR file
RUN ls -la build/libs/ && \
    echo "JAR file size: $(du -h build/libs/09launcher.jar | cut -f1)"

###############################
# Stage 2: Runtime
###############################
FROM alpine:3.18

# Build arguments for customization
ARG USER_NAME=player
ARG USER_ID=1098
ARG GROUP_ID=1098
# Default password should be overridden at runtime
ARG VNC_PASSWORD=password
ARG SCREEN_RESOLUTION=1024x768x24
# Version of noVNC to use
ARG NOVNC_VERSION=1.4.0

# Install additional dependencies needed for the launcher
RUN apk add --no-cache \
    ca-certificates \
    openjdk17-jre \
    openssl \
    x11vnc \
    xvfb \
    supervisor \
    python3 \
    curl \
    tini \
    netcat-openbsd \
    procps \
    git \
    unzip \
    libxtst \
    libxrender \
    fontconfig \
    freetype \
    ttf-dejavu \
    mesa-gl \
    xauth \
    adwaita-icon-theme \
    dbus \
    mesa \
    mesa-dri-gallium \
    pciutils-libs \
    libxext \
    libxcomposite \
    libxdamage && \
    # Create non-root user in the same layer
    addgroup -g ${GROUP_ID} ${USER_NAME} && \
    adduser -D -u ${USER_ID} -G ${USER_NAME} ${USER_NAME} && \
    # Create directories needed later
    mkdir -p /etc/supervisor.d /etc/supervisor/conf.d /app/noVNC /app/cache \
           /home/${USER_NAME}/.config \
           /home/${USER_NAME}/.09launcher \
           /tmp/.X11-unix

WORKDIR /app

# Copy the built launcher from builder stage
COPY --from=builder /app/build/libs/*.jar /app/09launcher.jar
RUN chmod 644 /app/09launcher.jar

# Add a debugging script to check environment setup
RUN printf '%s\n' \
'#!/bin/sh' \
'echo "Starting debug checks..."' \
'echo "Java version:"' \
'java -version' \
'echo "X11 setup:"' \
'echo $DISPLAY' \
'echo "User info:"' \
'id' \
'echo "Current directory:"' \
'pwd' \
'echo "Home directory:"' \
'ls -la $HOME' \
'echo "Java executable location:"' \
'which java' \
'echo "Python executable location:"' \
'which python3' \
'echo "NoVNC setup:"' \
'ls -la /app/noVNC/utils/' \
'echo "Supervisor config:"' \
'ls -la /etc/supervisor/conf.d/' \
'ls -la /etc/supervisor.d/' \
'echo "Testing X11 connection:"' \
'xauth info || echo "xauth not configured"' \
'echo "Debug checks complete."' \
> /app/debug.sh && chmod +x /app/debug.sh

# Create a script to generate the config.json file at startup
RUN printf '%s\n' \
'#!/bin/sh' \
'# Get the server hostname from environment or use default' \
'SERVER_HOST="${SERVER_HOST:-app}"' \
'SERVER_PORT="${SERVER_PORT:-43594}"' \
'JS5_PORT="${JS5_PORT:-43593}"' \
'WL_PORT="${WL_PORT:-5555}"' \
'WORLD="${WORLD:-1}"' \
'' \
'# Create the config directory if it does not exist' \
'mkdir -p /home/${USER_NAME}/.config/09launcher' \
'' \
'# Generate the config.json file with the correct server address' \
'cat > /home/${USER_NAME}/.config/09launcher/config.json << EOF' \
'{' \
'  "ip_address": "'$SERVER_HOST'",' \
'  "ip_management": "'$SERVER_HOST'",' \
'  "server_port": '$SERVER_PORT',' \
'  "wl_port": '$WL_PORT',' \
'  "js5_port": '$JS5_PORT',' \
'  "world": '$WORLD',' \
'  "customization": {' \
'    "login_theme": "scape main",' \
'    "right_click_menu": {' \
'      "background": {' \
'        "color": "#5D5447",' \
'        "opacity": "255"' \
'      },' \
'      "title_bar": {' \
'        "color": "#000000",' \
'        "opacity": "255",' \
'        "font_color": "#FFFFFF"' \
'      },' \
'      "border": {' \
'        "color": "#FFFFFF",' \
'        "opacity": "255"' \
'      },' \
'      "styles": {' \
'        "Presets provide default customizations.": "rs3, classic, or custom. custom allows you to define your own values above. Classic is standard 2009.",' \
'        "presets": "custom",' \
'        "rs3border": false' \
'      }' \
'    },' \
'    "xpdrops": {' \
'      "enabled": true,' \
'      "drop_mode": 0,' \
'      "track_mode": 0' \
'    },' \
'    "slayer": {' \
'      "enabled": true,' \
'      "color": "#635a38",' \
'      "opacity": "180"' \
'    },' \
'    "rendering_options": {' \
'      "technical": {' \
'        "render_distance_increase": true' \
'      },' \
'      "skybox": {' \
'        "skybox_color": "Coming in a future update..."' \
'      }' \
'    }' \
'  },' \
'  "debug": {' \
'    "item_debug": false,' \
'    "object_debug": false,' \
'    "npc_debug": false,' \
'    "hd_login_region_debug": false,' \
'    "hd_login_region_debug_verbose": false,' \
'    "cache_debug": false,' \
'    "world_map_debug": false' \
'  }' \
'}' \
'EOF' \
'' \
'# Ensure correct ownership of the config file' \
'chown -R ${USER_NAME}:${USER_NAME} /home/${USER_NAME}/.config' \
'' \
'echo "Generated config.json with server address: $SERVER_HOST:$SERVER_PORT"' \
> /app/generate-config.sh && \
chmod +x /app/generate-config.sh

# Add a startup script to ensure proper initialization
RUN printf '%s\n' \
'#!/bin/sh' \
'echo "Starting initialization script..."' \
'# Make sure directories exist with proper permissions' \
'mkdir -p /home/${USER_NAME}/.09launcher' \
'mkdir -p /home/${USER_NAME}/.config' \
'mkdir -p /home/${USER_NAME}/.cache' \
'mkdir -p /tmp/.X11-unix' \
'chmod 1777 /tmp/.X11-unix' \
'chown -R ${USER_NAME}:${USER_NAME} /home/${USER_NAME}' \
'# Run the debug script to verify environment' \
'/app/debug.sh > /var/log/startup_debug.log 2>&1' \
'# Generate the config.json file' \
'/app/generate-config.sh' \
'# Create .Xauthority file for the user' \
'touch /home/${USER_NAME}/.Xauthority' \
'chown ${USER_NAME}:${USER_NAME} /home/${USER_NAME}/.Xauthority' \
'chmod 600 /home/${USER_NAME}/.Xauthority' \
'# Make sure noVNC directory has proper permissions' \
'chmod -R 755 /app/noVNC' \
'echo "Initialization completed successfully"' \
'sleep 2' \
'exit 0' \
> /app/init.sh && chmod +x /app/init.sh

# Try to verify the JAR file is runnable
RUN JAVA_TOOL_OPTIONS="-Djava.awt.headless=true -Xmx1024m" java -jar /app/09launcher.jar --help || echo "JAR verification attempted"

# Copy the noVNC files and set proper permissions
RUN git clone --depth 1 --branch v${NOVNC_VERSION} https://github.com/novnc/noVNC.git /app/noVNC && \
    cd /app/noVNC/utils && chmod +x novnc_proxy && \
    # Create directories for VNC
    mkdir -p /home/${USER_NAME}/.vnc && \
    # Set up VNC password directly with no prompts
    x11vnc -storepasswd ${VNC_PASSWORD} /home/${USER_NAME}/.vnc/passwd && \
    chmod 600 /home/${USER_NAME}/.vnc/passwd && \
    chown -R ${USER_NAME}:${USER_NAME} /home/${USER_NAME}/.vnc

# Create environment file for 09launcher
RUN mkdir -p /etc/supervisor/env && \
    printf '%s\n' \
    "DISPLAY=:1" \
    "HOME=/home/${USER_NAME}" \
    "USER=${USER_NAME}" \
    "JAVA_TOOL_OPTIONS=-Xmx1024m -Djava.awt.headless=false" \
    > /etc/supervisor/env/09launcher.env && \
    chmod 644 /etc/supervisor/env/09launcher.env

# Create supervisor configuration with absolute paths to executables
RUN mkdir -p /var/log/supervisor && \
    printf '%s\n' \
"[supervisord]" \
"nodaemon=true" \
"logfile=/var/log/supervisord.log" \
"logfile_maxbytes=50MB" \
"logfile_backups=10" \
"loglevel=info" \
"pidfile=/var/run/supervisord.pid" \
"user=root" \
"childlogdir=/var/log/supervisor" \
"" \
"[include]" \
"files = /etc/supervisor/conf.d/*.conf" \
"" \
"[program:init]" \
"command=/app/init.sh" \
"autostart=true" \
"autorestart=false" \
"priority=5" \
"startretries=1" \
"startsecs=0" \
"user=root" \
"stdout_logfile=/var/log/init.log" \
"stderr_logfile=/var/log/init_err.log" \
"" \
"[program:xvfb]" \
"command=/usr/bin/Xvfb :1 -screen 0 %(ENV_SCREEN_RESOLUTION)s" \
"autostart=true" \
"autorestart=true" \
"priority=10" \
"stdout_logfile=/var/log/xvfb.log" \
"stderr_logfile=/var/log/xvfb_err.log" \
"" \
"[program:x11vnc]" \
"command=/usr/bin/x11vnc -xkb -noxrecord -noxfixes -noxdamage -display :1 -forever -shared -passwd %(ENV_VNC_PASSWORD)s" \
"autostart=true" \
"autorestart=true" \
"priority=20" \
"depends_on=xvfb" \
"stdout_logfile=/var/log/x11vnc.log" \
"stderr_logfile=/var/log/x11vnc_err.log" \
"" \
"[program:novnc]" \
"command=sh -c 'sleep 3 && /usr/bin/python3 /app/noVNC/utils/novnc_proxy --vnc localhost:5900 --listen 6080 --web /app/noVNC'" \
"autostart=true" \
"autorestart=true" \
"priority=30" \
"depends_on=x11vnc" \
"startsecs=10" \
"stdout_logfile=/var/log/novnc.log" \
"stderr_logfile=/var/log/novnc_err.log" \
"" \
"[program:09launcher]" \
"command=sh -c 'sleep 5 && /usr/bin/java -jar /app/09launcher.jar --debug'" \
"directory=/home/%(ENV_USER_NAME)s" \
"autostart=true" \
"autorestart=true" \
"priority=40" \
"user=%(ENV_USER_NAME)s" \
"depends_on=xvfb" \
"stdout_logfile=/var/log/09launcher.log" \
"stderr_logfile=/var/log/09launcher_err.log" \
"startretries=5" \
"stopasgroup=true" \
"killasgroup=true" \
"startsecs=10" \
"environment_file=/etc/supervisor/env/09launcher.env" \
"" \
"[group:vnc-client]" \
"programs=init,xvfb,x11vnc,novnc,09launcher" \
"priority=999" \
> /etc/supervisor/conf.d/services.conf

# Fix permissions for home directory and logs
RUN mkdir -p /var/log/supervisor && \
    mkdir -p /var/log && \
    touch /var/log/supervisord.log \
          /var/log/init.log /var/log/init_err.log \
          /var/log/xvfb.log /var/log/xvfb_err.log \
          /var/log/x11vnc.log /var/log/x11vnc_err.log \
          /var/log/novnc.log /var/log/novnc_err.log \
          /var/log/09launcher.log /var/log/09launcher_err.log \
          /var/log/startup_debug.log && \
    chown -R ${USER_NAME}:${USER_NAME} /var/log/09launcher* && \
    chown -R ${USER_NAME}:${USER_NAME} /home/${USER_NAME} && \
    chmod 755 /home/${USER_NAME} && \
    # Make sure the user can access the launcher JAR
    chown root:${USER_NAME} /app/09launcher.jar && \
    chmod 644 /app/09launcher.jar && \
    # Make sure the app directory is accessible
    chmod 755 /app && \
    chown -R ${USER_NAME}:${USER_NAME} /app/cache

# Create XDG runtime directory for the user
RUN mkdir -p /tmp/runtime-${USER_NAME} && \
    chown ${USER_NAME}:${USER_NAME} /tmp/runtime-${USER_NAME} && \
    chmod 700 /tmp/runtime-${USER_NAME}

# Expose ports
EXPOSE 5900 6080

# Set environment variables
ENV USER_NAME=${USER_NAME} \
    VNC_PASSWORD=${VNC_PASSWORD} \
    SCREEN_RESOLUTION=${SCREEN_RESOLUTION} \
    DISPLAY=:1 \
    JAVA_TOOL_OPTIONS="-Xmx1024m -Djava.awt.headless=false" \
    HOME=/home/${USER_NAME} \
    XDG_RUNTIME_DIR=/tmp/runtime-${USER_NAME}

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD nc -z localhost 6080 || exit 1

# Use tini as init system with supervisor
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/services.conf"]