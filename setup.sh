#!/bin/bash

# Set up the 2009scape environment with both server and client

# Create necessary directories
mkdir -p server
mkdir -p client
mkdir -p Server/db_exports

# Create server Dockerfile
cat > server/Dockerfile << 'EOF'
# Starting out with the openjdk-11-slim image
FROM maven:3-openjdk-11-slim
# Set working directory to /app
WORKDIR /app
# Update apt; install git and git-lfs
RUN apt-get update && apt-get -qq -y install git git-lfs
# Clone the 2009scape repository
RUN git clone --depth=1 https://gitlab.com/2009scape/2009scape.git
# Fake it til you make it - let's go home
WORKDIR /app/2009scape
# Make sure ./run has permissions
RUN chmod +x run
# Run it
CMD ["./run"]
EOF

# Copy client files to the client directory
cp gradlew client/
cp build.gradle client/
cp gradle.properties client/
mkdir -p client/gradle/wrapper
# Make sure to copy any other necessary client files

# Copy or create supervisord.conf
cat > client/supervisord.conf << 'EOF'
[supervisord]
nodaemon=true
user=root

[program:xvfb]
command=/usr/bin/Xvfb :1 -screen 0 1280x800x24
autorestart=true
priority=100

[program:x11vnc]
command=/usr/bin/x11vnc -display :1 -xkb -forever -shared -rfbauth /root/.vnc/passwd
autorestart=true
priority=200

[program:fluxbox]
command=/usr/bin/fluxbox
environment=DISPLAY=:1
autorestart=true
priority=300

[program:novnc]
command=/usr/share/novnc/utils/launch.sh --vnc localhost:5900 --listen 6080
autorestart=true
priority=400

[program:2009scape-client]
command=java -jar /app/build/libs/2009scape-1.2.jar
environment=DISPLAY=:1
autorestart=true
priority=500
EOF

# Create client Dockerfile
cat > client/Dockerfile << 'EOF'
FROM eclipse-temurin:11-jdk

# Install necessary packages
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    x11vnc \
    xvfb \
    fluxbox \
    supervisor \
    net-tools \
    novnc \
    python3 \
    git \
    curl \
    gradle

# Set up working directory
WORKDIR /app

# Copy the client launcher files
COPY . /app/

# Set up VNC and noVNC
RUN mkdir -p /root/.vnc
RUN echo "password" | vncpasswd -f > /root/.vnc/passwd
RUN chmod 600 /root/.vnc/passwd

# Copy the supervisor configuration
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Create a simple index.html for noVNC
RUN mkdir -p /usr/share/novnc/custom
RUN echo '<html><head><title>2009scape Client</title></head><body><div style="text-align: center; margin-top: 20px;"><h1>2009scape Client</h1><p>Click the button below to launch the game client:</p><a href="/vnc.html?autoconnect=true&password=password" style="display: inline-block; background-color: #4CAF50; color: white; padding: 15px 32px; text-align: center; text-decoration: none; font-size: 16px; margin: 4px 2px; cursor: pointer; border-radius: 10px;">Launch Client</a></div></body></html>' > /usr/share/novnc/custom/index.html
RUN ln -s /usr/share/novnc/custom/index.html /usr/share/novnc/index.html

# Build the client
RUN gradle clean build

# Expose VNC and noVNC ports
EXPOSE 5900 6080

# Start supervisord
CMD ["/usr/bin/supervisord"]
EOF

# Create docker-compose.yml
cat > docker-compose.yml << 'EOF'
services:
  app:
    build: ./server
    container_name: "2009scape_app"
    depends_on:
      - database
    restart: unless-stopped
    volumes:
      - "2009scape_app:/app"
    ports:
      - "43595:43595"
    networks:
      - 2009scape_network

  database:
    image: mysql:5.7
    container_name: "2009scape_db"
    restart: always
    ports:
      - "3306:3306"
    volumes:
      - "2009scape_db:/var/lib/mysql"
      - "./Server/db_exports/global.sql:/docker-entrypoint-initdb.d/global.sql"
    environment:
      MYSQL_ALLOW_EMPTY_PASSWORD: "yes"
      MYSQL_ROOT_PASSWORD: "567326"
      MYSQL_ROOT_USER: "jordan"
    networks:
      - 2009scape_network

  client:
    build: ./client
    container_name: "2009scape_client"
    restart: unless-stopped
    ports:
      - "6080:6080"
      - "5900:5900"
    environment:
      - SERVER_HOST=app
      - SERVER_PORT=43595
      - DISPLAY=:1
    depends_on:
      - app
    networks:
      - 2009scape_network

volumes:
  2009scape_app:
  2009scape_db:

networks:
  2009scape_network:
    driver: bridge
EOF

# Make the script executable
chmod +x start.sh

echo "Setup completed! You can now run './start.sh' to start the 2009scape environment."
echo "After starting, access the client at http://localhost:6080/"