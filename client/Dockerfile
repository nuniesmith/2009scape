###############################
# Stage 1: Builder
###############################
FROM eclipse-temurin:latest AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    gradle \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Clone repository and build
RUN git clone https://gitlab.com/2009scape/09launcher.git . && \
    gradle clean build

###############################
# Stage 2: Runtime
###############################
FROM eclipse-temurin:latest AS runtime

# Create non-root user
ARG USER_NAME=appuser
ARG USER_ID=1001
ARG GROUP_ID=1001

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    unzip \
    x11vnc \
    xvfb \
    fluxbox \
    supervisor \
    net-tools \
    novnc \
    python3 \
    curl \
    tini \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -g ${GROUP_ID} ${USER_NAME} \
    && useradd -u ${USER_ID} -g ${GROUP_ID} -m ${USER_NAME}

# Set up working directory
WORKDIR /app

# Copy built artifacts from builder stage
COPY --from=builder /app/build /app/build

# Set up VNC and noVNC
RUN mkdir -p /home/${USER_NAME}/.vnc && \
    echo "password" | vncpasswd -f > /home/${USER_NAME}/.vnc/passwd && \
    chmod 600 /home/${USER_NAME}/.vnc/passwd && \
    chown -R ${USER_NAME}:${USER_NAME} /home/${USER_NAME}/.vnc

# Create directory structure for config files
RUN mkdir -p /app/config/html

# Copy the config files
COPY --chown=${USER_NAME}:${USER_NAME} ./config/html/index.html /usr/share/novnc/custom/index.html
RUN ln -s /usr/share/novnc/custom/index.html /usr/share/novnc/index.html

# Set proper permissions
RUN chown -R ${USER_NAME}:${USER_NAME} /app

# Create supervisor configuration
COPY --chown=${USER_NAME}:${USER_NAME} ./config/mysql/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expose VNC and noVNC ports
EXPOSE 5900 6080

# Switch to non-root user
USER ${USER_NAME}

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD nc -z localhost 6080 || exit 1

# Use tini as init system
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]