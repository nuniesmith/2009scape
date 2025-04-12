FROM eclipse-temurin:latest

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