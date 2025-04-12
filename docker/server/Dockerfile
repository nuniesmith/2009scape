###############################
# Stage 1: Builder
###############################
FROM eclipse-temurin:11-jdk AS builder
WORKDIR /app

# Install build dependencies including Gradle
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    git-lfs \
    wget \
    unzip \
    netcat \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    # Install Gradle 6.8
    && wget https://services.gradle.org/distributions/gradle-6.8-bin.zip -P /tmp \
    && unzip -d /opt/gradle /tmp/gradle-6.8-bin.zip \
    && ln -s /opt/gradle/gradle-6.8/bin/gradle /usr/bin/gradle \
    && rm /tmp/gradle-6.8-bin.zip

# Set Gradle environment variables
ENV GRADLE_HOME=/opt/gradle/gradle-6.8
ENV PATH=${GRADLE_HOME}/bin:${PATH}

# Clone the repository and build
RUN git clone --depth=1 https://gitlab.com/2009scape/2009scape.git && \
    cd 2009scape && \
    git lfs install && \
    git lfs pull && \
    # Create a gradle.properties file with optimized settings
    echo "org.gradle.jvmargs=-Xmx2048m -XX:MaxPermSize=512m -XX:+HeapDumpOnOutOfMemoryError" > gradle.properties && \
    echo "org.gradle.daemon=false" >> gradle.properties && \
    echo "org.gradle.parallel=true" >> gradle.properties && \
    # Build the server
    gradle build --no-daemon

###############################
# Stage 2: Runtime
###############################
FROM eclipse-temurin:11-jre AS runtime

# Create non-root user
ARG USER_NAME=zezima
ARG USER_ID=1099
ARG GROUP_ID=1099

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    tini \
    netcat \
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

# Create volume for game data and logs
VOLUME ["/app/2009scape/data", "/app/2009scape/logs"]

# Set optimized JVM options for the game server
ENV JAVA_OPTS="-Xmx2048m -Xms1024m -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:+HeapDumpOnOutOfMemoryError"

# Switch to non-root user
USER ${USER_NAME}

# Working directory for execution
WORKDIR /app/2009scape

# Expose game server ports
EXPOSE 43594 43595 43596

# Health check that ensures the server is running
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD nc -z localhost 43594 || exit 1

# Use tini as init system
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["./run"]