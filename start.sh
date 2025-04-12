#!/bin/bash

# start.sh - Script to manage 2009scape Docker environment

# Print with colors for better readability
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default docker-compose file location
COMPOSE_FILE="docker-compose.yml"
COMMAND="start"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to display usage information
show_help() {
    echo "Usage: $0 [OPTIONS] [COMMAND]"
    echo
    echo "Commands:"
    echo "  start      Start the 2009Scape containers (default)"
    echo "  stop       Stop the 2009Scape containers"
    echo "  restart    Restart the 2009Scape containers"
    echo "  status     Show the status of 2009Scape containers"
    echo "  logs       View logs for all containers or specific container"
    echo
    echo "Options:"
    echo "  -f, --file FILE    Specify the docker-compose file (default: docker-compose.yml)"
    echo "  -c, --container    Specify container for logs (app, db, client, nginx)"
    echo "  -h, --help         Show this help message"
    echo
}

# Function to display container status
show_status() {
    echo -e "${BLUE}Container Status:${NC}"
    
    # Check app container
    if docker ps --format '{{.Names}}' | grep -q "2009scape_app"; then
        echo -e "${GREEN}Game Server (2009scape_app): Running${NC}"
    elif docker ps -a --format '{{.Names}}' | grep -q "2009scape_app"; then
        echo -e "${RED}Game Server (2009scape_app): Stopped${NC}"
    else
        echo -e "${YELLOW}Game Server (2009scape_app): Not created${NC}"
    fi
    
    # Check database container
    if docker ps --format '{{.Names}}' | grep -q "2009scape_db"; then
        echo -e "${GREEN}Database (2009scape_db): Running${NC}"
    elif docker ps -a --format '{{.Names}}' | grep -q "2009scape_db"; then
        echo -e "${RED}Database (2009scape_db): Stopped${NC}"
    else
        echo -e "${YELLOW}Database (2009scape_db): Not created${NC}"
    fi
    
    # Check client container
    if docker ps --format '{{.Names}}' | grep -q "2009scape_client"; then
        echo -e "${GREEN}Web Client (2009scape_client): Running${NC}"
    elif docker ps -a --format '{{.Names}}' | grep -q "2009scape_client"; then
        echo -e "${RED}Web Client (2009scape_client): Stopped${NC}"
    else
        echo -e "${YELLOW}Web Client (2009scape_client): Not created${NC}"
    fi
    
    # Check nginx container
    if docker ps --format '{{.Names}}' | grep -q "2009scape_nginx"; then
        echo -e "${GREEN}Web Server (2009scape_nginx): Running${NC}"
    elif docker ps -a --format '{{.Names}}' | grep -q "2009scape_nginx"; then
        echo -e "${RED}Web Server (2009scape_nginx): Stopped${NC}"
    else
        echo -e "${YELLOW}Web Server (2009scape_nginx): Not created${NC}"
    fi
    
    # If running, show more details
    if docker ps --format '{{.Names}}' | grep -q "2009scape_app"; then
        echo
        echo -e "${BLUE}Access Information:${NC}"
        
        # Web interface info
        if docker ps --format '{{.Names}}' | grep -q "2009scape_nginx"; then
            echo -e "→ ${CYAN}Web Interface:${NC} ${GREEN}http://localhost${NC} (or domain names in hosts file)"
            echo -e "  ${CYAN}Direct Web Client:${NC} ${GREEN}http://localhost/client/${NC}"
            echo -e "  ${CYAN}Status Page:${NC} ${GREEN}http://localhost/status${NC}"
        elif docker ps --format '{{.Names}}' | grep -q "2009scape_client"; then
            echo -e "→ ${CYAN}Direct Web Client:${NC} ${GREEN}http://localhost:6080${NC}"
        fi
        
        # Game server info
        echo -e "→ ${CYAN}Game Server:${NC} ${GREEN}localhost:43595${NC} (for direct client connections)"
        
        # Database info
        if docker ps --format '{{.Names}}' | grep -q "2009scape_db"; then
            echo -e "→ ${CYAN}Database:${NC} ${GREEN}localhost:3306${NC}"
            echo -e "  ${CYAN}Username:${NC} jordan"
            echo -e "  ${CYAN}Password:${NC} 567326"
        fi
    fi
}

# Set default container name for logs
CONTAINER=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        start|stop|restart|status|logs)
            COMMAND="$1"
            shift
            ;;
        -f|--file)
            COMPOSE_FILE="$2"
            shift 2
            ;;
        -c|--container)
            CONTAINER="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# For status command, we don't need to check for Docker installation
if [ "$COMMAND" = "status" ]; then
    show_status
    exit 0
fi

# Special handling for logs command
if [ "$COMMAND" = "logs" ]; then
    # Check if Docker is installed first
    if ! command_exists docker; then
        echo -e "${RED}Error: Docker is not installed. Please install Docker first.${NC}"
        exit 1
    fi
    
    # Check if Docker Compose is installed
    if ! command_exists docker-compose; then
        echo -e "${RED}Error: Docker Compose is not installed. Please install Docker Compose first.${NC}"
        exit 1
    fi

    # View logs for specific container or all
    if [ -n "$CONTAINER" ]; then
        case $CONTAINER in
            app)
                docker logs -f 2009scape_app
                ;;
            db)
                docker logs -f 2009scape_db
                ;;
            client)
                docker logs -f 2009scape_client
                ;;
            nginx)
                docker logs -f 2009scape_nginx
                ;;
            *)
                echo -e "${RED}Unknown container: $CONTAINER${NC}"
                echo -e "Valid containers: app, db, client, nginx"
                exit 1
                ;;
        esac
    else
        # Show logs for all containers
        docker-compose -f "$COMPOSE_FILE" logs -f
    fi
    exit 0
fi

# Check if docker-compose file exists
if [ ! -f "$COMPOSE_FILE" ]; then
    echo -e "${RED}Error: Docker Compose file '$COMPOSE_FILE' not found.${NC}"
    exit 1
fi

# Check if Docker is installed
if ! command_exists docker; then
    echo -e "${RED}Error: Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

# Check if Docker Compose is installed
if ! command_exists docker-compose; then
    echo -e "${RED}Error: Docker Compose is not installed. Please install Docker Compose first.${NC}"
    exit 1
fi

# Check if Docker daemon is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Error: Docker daemon is not running. Please start Docker and try again.${NC}"
    exit 1
fi

echo -e "${GREEN}Docker environment checks passed.${NC}"

# Function to prepare nginx directories and files
prepare_nginx() {
    # Create necessary directories
    mkdir -p config/nginx
    mkdir -p config/html
    
    # Check if default.conf exists, if not create it
    if [ ! -f ./config/nginx/default.conf ]; then
        echo -e "${YELLOW}Creating default NGINX configuration...${NC}"
        # Copy our default.conf to the config/nginx directory
        cp ./default.conf ./config/nginx/default.conf 2>/dev/null || {
            echo -e "${YELLOW}Warning: default.conf not found, creating a basic one.${NC}"
            # Basic conf if our template isn't available
            cat > ./config/nginx/default.conf << 'EOF'
server {
    listen 80;
    server_name localhost;

    location / {
        proxy_pass http://client:6080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }

    location /status {
        root /usr/share/nginx/html;
        try_files /status.html =404;
    }
}
EOF
        }
    fi
    
    # Check if status.html exists, if not create it
    if [ ! -f ./config/html/status.html ]; then
        echo -e "${YELLOW}Creating status page...${NC}"
        # Copy our status.html to the config/html directory
        cp ./status.html ./config/html/status.html 2>/dev/null || {
            echo -e "${YELLOW}Warning: status.html not found, creating a basic one.${NC}"
            # Basic status page if our template isn't available
            cat > ./config/html/status.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>2009scape Status</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
        h1 { color: #5D87A1; }
        .status { padding: 10px; margin: 10px 0; border-radius: 4px; }
        .online { background-color: #DFF2BF; color: #4F8A10; }
        .offline { background-color: #FFBABA; color: #D8000C; }
    </style>
</head>
<body>
    <h1>2009scape Server Status</h1>
    <div class="status online">Game Server: Online</div>
    <div class="status online">Web Client: Online</div>
    <div class="status online">Database: Online</div>
    <p>For more information, please visit the <a href="https://gitlab.com/2009scape/2009scape">2009scape GitLab project</a>.</p>
</body>
</html>
EOF
        }
    fi
}

# Handle different commands
case $COMMAND in
    start)
        # Create necessary directories if they don't exist
        mkdir -p server/db_exports
        
        # Prepare NGINX files if needed
        prepare_nginx

        # Check if global.sql exists
        if [ ! -f ./Server/db_exports/global.sql ]; then
            echo -e "${YELLOW}Warning: global.sql not found in server/db_exports/.${NC}"
            echo -e "${YELLOW}Make sure to provide this file or the database initialization will fail.${NC}"
        fi

        # Build and start the containers
        echo -e "${YELLOW}Building and starting containers...${NC}"
        docker-compose -f "$COMPOSE_FILE" up -d --build

        # Check if containers are running
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}2009Scape containers started successfully!${NC}"
            
            # Check which containers are actually running and report
            if docker ps --format '{{.Names}}' | grep -q "2009scape_app"; then
                echo -e "${GREEN}→ Game Server: 2009scape_app (port 43595)${NC}"
            fi
            
            if docker ps --format '{{.Names}}' | grep -q "2009scape_db"; then
                echo -e "${GREEN}→ Database: 2009scape_db (port 3306)${NC}"
            fi
            
            if docker ps --format '{{.Names}}' | grep -q "2009scape_client"; then
                echo -e "${GREEN}→ Web Client: 2009scape_client (ports 6080, 5900)${NC}"
            fi
            
            if docker ps --format '{{.Names}}' | grep -q "2009scape_nginx"; then
                echo -e "${GREEN}→ Web Server: 2009scape_nginx (port 80)${NC}"
            fi
            
            echo
            echo -e "${BLUE}Access Information:${NC}"
            
            # Web interface info
            if docker ps --format '{{.Names}}' | grep -q "2009scape_nginx"; then
                echo -e "→ ${CYAN}Web Interface:${NC} ${GREEN}http://localhost${NC}"
                echo -e "  ${CYAN}Status Page:${NC} ${GREEN}http://localhost/status${NC}"
            elif docker ps --format '{{.Names}}' | grep -q "2009scape_client"; then
                echo -e "→ ${CYAN}Web Client:${NC} ${GREEN}http://localhost:6080${NC}"
            fi
            
            # Game server info
            echo -e "→ ${CYAN}Game Server:${NC} ${GREEN}localhost:43595${NC} (for direct client connections)"
            
            echo
            echo -e "${YELLOW}You can view logs with: ./start.sh logs${NC}"
            echo -e "${YELLOW}View status anytime with: ./start.sh status${NC}"
        else
            echo -e "${RED}Failed to start containers. Check the error messages above.${NC}"
            exit 1
        fi
        ;;
    stop)
        echo -e "${YELLOW}Stopping 2009Scape containers...${NC}"
        docker-compose -f "$COMPOSE_FILE" down
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}2009Scape containers stopped successfully.${NC}"
        else
            echo -e "${RED}Failed to stop containers. Check the error messages above.${NC}"
            exit 1
        fi
        ;;
    restart)
        echo -e "${YELLOW}Restarting 2009Scape containers...${NC}"
        docker-compose -f "$COMPOSE_FILE" down
        if [ $? -ne 0 ]; then
            echo -e "${RED}Failed to stop containers.${NC}"
        fi
        
        # Prepare NGINX files if needed
        prepare_nginx
        
        echo -e "${YELLOW}Starting containers again...${NC}"
        docker-compose -f "$COMPOSE_FILE" up -d --build
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}2009Scape containers restarted successfully!${NC}"
            
            # Check which containers are actually running and report
            if docker ps --format '{{.Names}}' | grep -q "2009scape_app"; then
                echo -e "${GREEN}→ Game Server: 2009scape_app (port 43595)${NC}"
            fi
            
            if docker ps --format '{{.Names}}' | grep -q "2009scape_db"; then
                echo -e "${GREEN}→ Database: 2009scape_db (port 3306)${NC}"
            fi
            
            if docker ps --format '{{.Names}}' | grep -q "2009scape_client"; then
                echo -e "${GREEN}→ Web Client: 2009scape_client (ports 6080, 5900)${NC}"
            fi
            
            if docker ps --format '{{.Names}}' | grep -q "2009scape_nginx"; then
                echo -e "${GREEN}→ Web Server: 2009scape_nginx (port 80)${NC}"
            fi
            
            echo
            echo -e "${BLUE}Access Information:${NC}"
            
            # Web interface info
            if docker ps --format '{{.Names}}' | grep -q "2009scape_nginx"; then
                echo -e "→ ${CYAN}Web Interface:${NC} ${GREEN}http://localhost${NC}"
                echo -e "  ${CYAN}Status Page:${NC} ${GREEN}http://localhost/status${NC}"
            elif docker ps --format '{{.Names}}' | grep -q "2009scape_client"; then
                echo -e "→ ${CYAN}Web Client:${NC} ${GREEN}http://localhost:6080${NC}"
            fi
            
            # Game server info
            echo -e "→ ${CYAN}Game Server:${NC} ${GREEN}localhost:43595${NC} (for direct client connections)"
        else
            echo -e "${RED}Failed to restart containers. Check the error messages above.${NC}"
            exit 1
        fi
        ;;
esac

exit 0