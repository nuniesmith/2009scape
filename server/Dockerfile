###############################
# Stage 1: Builder
###############################
FROM eclipse-temurin:latest AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    git-lfs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Clone the repository
RUN git clone --depth=1 https://gitlab.com/2009scape/2009scape.git

###############################
# Stage 2: Runtime
###############################
FROM eclipse-temurin:latest AS runtime

# Create non-root user
ARG USER_NAME=gameuser
ARG USER_ID=1001
ARG GROUP_ID=1001

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    tini \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -g ${GROUP_ID} ${USER_NAME} \
    && useradd -u ${USER_ID} -g ${GROUP_ID} -m ${USER_NAME}

# Set up working directory
WORKDIR /app

# Copy files from builder stage
COPY --from=builder --chown=${USER_NAME}:${USER_NAME} /app/2009scape /app/2009scape

# Make sure the run script has execute permissions
RUN chmod +x /app/2009scape/run && \
    chown -R ${USER_NAME}:${USER_NAME} /app

# Set environment variables
ENV JAVA_OPTS="-Xmx1024m -Xms512m"

# Switch to non-root user
USER ${USER_NAME}

# Working directory for execution
WORKDIR /app/2009scape

# Expose game server ports
EXPOSE 43594 43595 43596

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD nc -z localhost 43594 || exit 1

# Use tini as init system
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["./run"]