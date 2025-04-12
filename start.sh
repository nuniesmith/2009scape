#!/bin/bash

# start.sh - Script to manage 2009scape Docker environment

# Print with colors for better readability
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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
    echo "  start    Start the 2009Scape containers (default)"
    echo "  stop     Stop the 2009Scape containers"
    echo "  restart  Restart the 2009Scape containers"
    echo "  status   Show the status of 2009Scape containers"
    echo
    echo "Options:"
    echo "  -f, --file FILE    Specify the docker-compose file (default: docker-compose.yml)"
    echo "  -h, --help         Show this help message"
    echo
}

# Function to display container status
show_status() {
    echo -e "${BLUE}Container Status:${NC}"
    
    # Check app container
    if docker ps --format '{{.Names}}' | grep -q "2009scape_app"; then
        echo -e "${GREEN}App container (2009scape_app): Running${NC}"
    elif docker ps -a --format '{{.Names}}' | grep -q "2009scape_app"; then
        echo -e "${RED}App container (2009scape_app): Stopped${NC}"
    else
        echo -e "${YELLOW}App container (2009scape_app): Not created${NC}"
    fi
    
    # Check database container
    if docker ps --format '{{.Names}}' | grep -q "2009scape_db"; then
        echo -e "${GREEN}Database container (2009scape_db): Running${NC}"
    elif docker ps -a --format '{{.Names}}' | grep -q "2009scape_db"; then
        echo -e "${RED}Database container (2009scape_db): Stopped${NC}"
    else
        echo -e "${YELLOW}Database container (2009scape_db): Not created${NC}"
    fi
    
    # If running, show more details
    if docker ps --format '{{.Names}}' | grep -q "2009scape_app"; then
        echo
        echo -e "${BLUE}Server Information:${NC}"
        echo -e "Connect to 2009Scape server at: ${GREEN}localhost:43595${NC}"
        echo -e "Database is accessible at: ${GREEN}localhost:3306${NC}"
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        start|stop|restart|status)
            COMMAND="$1"
            shift
            ;;
        -f|--file)
            COMPOSE_FILE="$2"
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

# Handle different commands
case $COMMAND in
    start)
        # Create necessary directories if they don't exist
        mkdir -p Server/db_exports

        # Check if global.sql exists
        if [ ! -f ./Server/db_exports/global.sql ]; then
            echo -e "${YELLOW}Warning: global.sql not found in Server/db_exports/.${NC}"
            echo -e "${YELLOW}Make sure to provide this file or the database initialization will fail.${NC}"
        fi

        # Build and start the containers
        echo -e "${YELLOW}Building and starting containers...${NC}"
        docker-compose -f "$COMPOSE_FILE" up -d --build

        # Check if containers are running
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}2009Scape containers started successfully!${NC}"
            echo -e "${GREEN}App container: 2009scape_app (port 43595)${NC}"
            echo -e "${GREEN}Database container: 2009scape_db (port 3306)${NC}"
            echo
            echo -e "${BLUE}Connect to 2009Scape server at: ${GREEN}localhost:43595${NC}"
            echo
            echo -e "${YELLOW}You can view logs with: docker-compose logs -f${NC}"
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
        
        echo -e "${YELLOW}Starting containers again...${NC}"
        docker-compose -f "$COMPOSE_FILE" up -d --build
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}2009Scape containers restarted successfully!${NC}"
            echo -e "${GREEN}App container: 2009scape_app (port 43595)${NC}"
            echo -e "${GREEN}Database container: 2009scape_db (port 3306)${NC}"
        else
            echo -e "${RED}Failed to restart containers. Check the error messages above.${NC}"
            exit 1
        fi
        ;;
esac

exit 0