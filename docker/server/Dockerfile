###############################
# Stage 1: Builder
###############################
FROM eclipse-temurin:11-jdk AS builder
WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    git-lfs \
    maven \
    netcat-openbsd \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Verify Java installation
RUN java -version && javac -version && echo $JAVA_HOME

# Clone the repository and build
RUN git clone --depth=1 https://gitlab.com/2009scape/2009scape.git && \
    cd 2009scape && \
    git lfs install && \
    git lfs pull && \
    # Create a maven settings file with optimized settings
    mkdir -p ~/.m2 && \
    echo "<settings><mirrors><mirror><id>central</id><url>https://repo1.maven.org/maven2</url><mirrorOf>central</mirrorOf></mirror></mirrors></settings>" > ~/.m2/settings.xml && \
    # Build the server using Maven
    cd Server && \
    mvn package -DskipTests

###############################
# Stage 2: Runtime
###############################
FROM eclipse-temurin:11-jdk

# Create non-root user
ARG USER_NAME=zezima
ARG USER_ID=1099
ARG GROUP_ID=1099

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    tini \
    netcat-openbsd \
    maven \
    supervisor \
    mysql-server \
    mysql-client \
    sudo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -g ${GROUP_ID} ${USER_NAME} \
    && useradd -u ${USER_ID} -g ${GROUP_ID} -m ${USER_NAME} \
    && echo "${USER_NAME} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${USER_NAME}

# Set up MySQL directories
RUN mkdir -p /var/lib/mysql /var/run/mysqld /docker-entrypoint-initdb.d \
    && chown -R mysql:mysql /var/lib/mysql /var/run/mysqld \
    && chmod 777 /var/run/mysqld

# Verify Java installation in runtime stage
RUN java -version && javac -version && echo $JAVA_HOME

# Set up working directory
WORKDIR /app

# Copy files from builder stage
COPY --from=builder --chown=${USER_NAME}:${USER_NAME} /app/2009scape /app/2009scape

# Copy configuration files
COPY --chown=root:root config/supervisord.conf /etc/supervisor/supervisord.conf
COPY --chown=root:root scripts/server/*.sh /app/scripts/
RUN chmod +x /app/scripts/*.sh

# Copy database initialization scripts
COPY --chown=root:mysql config/mysql/init/*.sh /docker-entrypoint-initdb.d/
RUN chmod +x /docker-entrypoint-initdb.d/*.sh

# Make sure the run script has execute permissions
RUN chmod +x /app/2009scape/run && \
    chmod -R 777 /app/2009scape && \
    chown -R ${USER_NAME}:${USER_NAME} /app

# Create directories for supervisor
RUN mkdir -p /etc/supervisor/conf.d /var/log/supervisor

# Create log files
RUN touch /var/log/supervisord.log \
    /var/log/mysql.log /var/log/mysql_err.log \
    /var/log/db-init.log /var/log/db-init_err.log \
    /var/log/2009scape-server.log /var/log/2009scape-server_err.log \
    /var/log/2009scape-management.log /var/log/2009scape-management_err.log \
    && chmod 666 /var/log/*.log

# Create volume for game data and logs
VOLUME ["/app/2009scape/data", "/app/2009scape/logs", "/var/lib/mysql"]

# Set optimized JVM options for the game server
ENV JAVA_OPTS="-Xmx2048m -Xms1024m -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:+HeapDumpOnOutOfMemoryError" \
    JAVA_HOME=/opt/java/openjdk \
    PATH="${JAVA_HOME}/bin:${PATH}" \
    MYSQL_ROOT_PASSWORD=root \
    MYSQL_USER=jordan \
    MYSQL_PASSWORD=123456 \
    MYSQL_DATABASE=2009scape \
    MYSQL_HOST=localhost

# Expose game server ports and MySQL
EXPOSE 43594 43595 43596 3306 5555

# Health check that ensures the server is running
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD nc -z localhost 43594 || exit 1

# Use tini as init system with supervisor
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]