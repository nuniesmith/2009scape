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

# Clone the repository instead of copying local files
RUN git clone https://gitlab.com/2009scape/09launcher.git .

# Set up VNC and noVNC
RUN mkdir -p /root/.vnc
RUN echo "password" | vncpasswd -f > /root/.vnc/passwd
RUN chmod 600 /root/.vnc/passwd

# Create directory structure for config files
RUN mkdir -p /app/config/html

# Copy the custom index.html from local config to noVNC
COPY ./config/html/index.html /usr/share/novnc/custom/index.html
RUN ln -s /usr/share/novnc/custom/index.html /usr/share/novnc/index.html

# Build the client
RUN gradle clean build

# Expose VNC and noVNC ports
EXPOSE 5900 6080

# Start supervisord
CMD ["/usr/bin/supervisord"]