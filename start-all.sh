#!/bin/bash
set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Script version
VERSION="1.1.0"

# Docker Compose command - support both v1 and v2 CLI
if docker compose version &>/dev/null; then
    DOCKER_COMPOSE="docker compose"
elif docker-compose --version &>/dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    echo -e "${RED}Error: Neither 'docker compose' nor 'docker-compose' found.${NC}"
    echo -e "Please install Docker Compose: https://docs.docker.com/compose/install/"
    exit 1
fi

# Function to display help
function show_help {
    echo -e "${BLUE}${BOLD}2009Scape Docker Management Script v${VERSION}${NC}"
    echo
    echo -e "Usage: ${GREEN}./start.sh${NC} ${YELLOW}<command>${NC} ${YELLOW}[service]${NC} ${YELLOW}[options]${NC}"
    echo
    echo -e "${BLUE}${BOLD}Commands:${NC}"
    echo -e "  ${GREEN}start${NC}      Start one or all services"
    echo -e "  ${GREEN}stop${NC}       Stop one or all services"
    echo -e "  ${GREEN}restart${NC}    Restart one or all services"
    echo -e "  ${GREEN}status${NC}     Check status of one or all services"
    echo -e "  ${GREEN}logs${NC}       View logs for one or all services"
    echo -e "  ${GREEN}rebuild${NC}    Rebuild and start one or all services"
    echo -e "  ${GREEN}pull${NC}       Pull latest images for services"
    echo -e "  ${GREEN}prune${NC}      Remove unused Docker resources"
    echo -e "  ${GREEN}backup${NC}     Backup volumes (database, app data)"
    echo -e "  ${GREEN}restore${NC}    Restore from backup"
    echo -e "  ${GREEN}exec${NC}       Execute a command in a running container"
    echo -e "  ${GREEN}health${NC}     Check health status of services"
    echo -e "  ${GREEN}version${NC}    Show version information"
    echo
    echo -e "${BLUE}${BOLD}Services:${NC}"
    echo -e "  ${YELLOW}app${NC}        Game server application"
    echo -e "  ${YELLOW}database${NC}   MySQL database server"
    echo -e "  ${YELLOW}client${NC}     Web-based game client"
    echo -e "  ${YELLOW}web${NC}        Web server (nginx)"
    echo -e "  ${YELLOW}all${NC}        All services (default if not specified)"
    echo
    echo -e "${BLUE}${BOLD}Options:${NC}"
    echo -e "  ${YELLOW}-d, --detach${NC}     Run containers in detached mode"
    echo -e "  ${YELLOW}-f, --force${NC}      Force rebuild of containers"
    echo -e "  ${YELLOW}-c, --clean${NC}      Remove orphaned containers"
    echo -e "  ${YELLOW}-t, --tail=N${NC}     Show last N lines of logs (default: 100)"
    echo -e "  ${YELLOW}--debug${NC}          Enable debug mode (verbose output)"
    echo -e "  ${YELLOW}-h, --help${NC}       Show this help message"
    echo
    echo -e "${BLUE}${BOLD}Examples:${NC}"
    echo -e "  ${GREEN}./start.sh${NC} ${YELLOW}start all${NC}          # Start all services"
    echo -e "  ${GREEN}./start.sh${NC} ${YELLOW}start app -d${NC}       # Start only the app service in detached mode"
    echo -e "  ${GREEN}./start.sh${NC} ${YELLOW}logs client -t 50${NC}  # Show last 50 log lines for the client service"
    echo -e "  ${GREEN}./start.sh${NC} ${YELLOW}rebuild app -d${NC}     # Rebuild and start app service in detached mode"
    echo -e "  ${GREEN}./start.sh${NC} ${YELLOW}exec app bash${NC}      # Open a bash shell in the app container"
    echo -e "  ${GREEN}./start.sh${NC} ${YELLOW}backup${NC}             # Backup all volumes"
    echo
}

# Function to check Docker runtime
function check_docker {
    if ! command -v docker &>/dev/null; then
        echo -e "${RED}Error: Docker is not installed or not in PATH${NC}"
        echo -e "Please install Docker: https://docs.docker.com/get-docker/"
        exit 1
    fi

    if ! docker info &>/dev/null; then
        echo -e "${RED}Error: Docker daemon is not running or current user lacks permissions${NC}"
        echo -e "Try running Docker service or adding your user to the 'docker' group"
        exit 1
    fi
}

# Function to check for docker-compose.yml
function check_compose_file {
    if [[ ! -f "docker-compose.yml" && ! -f "compose.yaml" ]]; then
        echo -e "${RED}Error: No docker-compose.yml or compose.yaml file found in current directory${NC}"
        echo -e "Make sure you're running this script from the project root directory"
        exit 1
    fi
}

# Function to check service health
function check_health {
    local service=$1
    local container_name

    if [[ "$service" == "all" ]]; then
        echo -e "${BLUE}${BOLD}Checking health of all services:${NC}"
        local services=("app" "database" "client" "web")
        for svc in "${services[@]}"; do
            check_health "$svc"
        done
        return
    fi

    case "$service" in
        app)
            container_name="2009scape_app"
            ;;
        database)
            container_name="2009scape_db"
            ;;
        client)
            container_name="2009scape_client"
            ;;
        web)
            container_name="2009scape_web"
            ;;
        *)
            echo -e "${RED}Error: Unknown service '$service'${NC}"
            return 1
            ;;
    esac

    # Check if container is running
    if ! docker ps -q -f "name=$container_name" | grep -q .; then
        echo -e "${service}: ${RED}Not running${NC}"
        return
    fi

    # Check health status if available
    local health_status=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "no health check")
    
    case "$health_status" in
        "healthy")
            echo -e "${service}: ${GREEN}Healthy${NC}"
            ;;
        "unhealthy")
            echo -e "${service}: ${RED}Unhealthy${NC}"
            ;;
        "starting")
            echo -e "${service}: ${YELLOW}Starting${NC}"
            ;;
        "no health check")
            local status=$(docker inspect --format='{{.State.Status}}' "$container_name")
            if [[ "$status" == "running" ]]; then
                echo -e "${service}: ${CYAN}Running (no health check)${NC}"
            else
                echo -e "${service}: ${YELLOW}${status}${NC}"
            fi
            ;;
        *)
            echo -e "${service}: ${YELLOW}${health_status}${NC}"
            ;;
    esac
}

# Function to backup volumes
function backup_volumes {
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_dir="backups/${timestamp}"
    
    echo -e "${BLUE}Creating backup in ${backup_dir}...${NC}"
    mkdir -p "${backup_dir}"
    
    # Backup MySQL database
    echo -e "${YELLOW}Backing up database...${NC}"
    docker exec 2009scape_db mysqldump -u jordan -p567326 --all-databases > "${backup_dir}/database_dump.sql" 2>/dev/null || {
        echo -e "${RED}Failed to backup database${NC}"
    }
    
    # Backup app data
    echo -e "${YELLOW}Backing up app data...${NC}"
    docker run --rm -v 2009scape_app_data:/source -v $(pwd)/${backup_dir}:/backup alpine tar -czf /backup/app_data.tar.gz -C /source . || {
        echo -e "${RED}Failed to backup app data${NC}"
    }
    
    # Backup client config
    echo -e "${YELLOW}Backing up client configuration...${NC}"
    docker run --rm -v 2009scape_client_config:/source -v $(pwd)/${backup_dir}:/backup alpine tar -czf /backup/client_config.tar.gz -C /source . || {
        echo -e "${RED}Failed to backup client configuration${NC}"
    }
    
    echo -e "${GREEN}Backup completed: ${backup_dir}${NC}"
}

# Function to restore from backup
function restore_from_backup {
    local backup_path=$1
    
    if [[ -z "$backup_path" ]]; then
        echo -e "${RED}Error: No backup path specified${NC}"
        echo -e "Usage: ${GREEN}./start.sh${NC} ${YELLOW}restore <backup_dir>${NC}"
        return 1
    fi
    
    if [[ ! -d "$backup_path" ]]; then
        echo -e "${RED}Error: Backup directory not found: ${backup_path}${NC}"
        return 1
    fi
    
    # Stop services
    echo -e "${YELLOW}Stopping services for restore...${NC}"
    $DOCKER_COMPOSE down
    
    # Restore database
    if [[ -f "${backup_path}/database_dump.sql" ]]; then
        echo -e "${YELLOW}Restoring database...${NC}"
        $DOCKER_COMPOSE up -d database
        sleep 10  # Give database time to start
        docker exec -i 2009scape_db mysql -u jordan -p567326 < "${backup_path}/database_dump.sql" || {
            echo -e "${RED}Failed to restore database${NC}"
        }
    else
        echo -e "${RED}Database dump not found in backup${NC}"
    fi
    
    # Restore app data
    if [[ -f "${backup_path}/app_data.tar.gz" ]]; then
        echo -e "${YELLOW}Restoring app data...${NC}"
        docker run --rm -v 2009scape_app_data:/dest -v $(pwd)/${backup_path}:/backup alpine sh -c "rm -rf /dest/* && tar -xzf /backup/app_data.tar.gz -C /dest" || {
            echo -e "${RED}Failed to restore app data${NC}"
        }
    else
        echo -e "${RED}App data backup not found${NC}"
    fi
    
    # Restore client config
    if [[ -f "${backup_path}/client_config.tar.gz" ]]; then
        echo -e "${YELLOW}Restoring client configuration...${NC}"
        docker run --rm -v 2009scape_client_config:/dest -v $(pwd)/${backup_path}:/backup alpine sh -c "rm -rf /dest/* && tar -xzf /backup/client_config.tar.gz -C /dest" || {
            echo -e "${RED}Failed to restore client configuration${NC}"
        }
    else
        echo -e "${RED}Client configuration backup not found${NC}"
    fi
    
    echo -e "${GREEN}Restore completed${NC}"
    echo -e "${YELLOW}Starting services...${NC}"
    $DOCKER_COMPOSE up -d
}

# Set defaults
COMMAND="start"
SERVICE="all"
DETACHED=""
FORCE=""
CLEAN=""
LOG_TAIL="100"
DEBUG=""
EXEC_COMMAND=""

# Parse arguments
if [[ $# -gt 0 ]]; then
    case "$1" in
        start|stop|restart|status|logs|rebuild|pull|prune|backup|restore|exec|health|version)
            COMMAND="$1"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            # Check if first argument is a service name
            if [[ "$1" =~ ^(app|database|client|web|all)$ ]]; then
                SERVICE="$1"
                shift
            else
                echo -e "${RED}Error: Unknown command '$1'${NC}"
                show_help
                exit 1
            fi
            ;;
    esac
fi

# Check if service is specified as second argument
if [[ $# -gt 0 && "$1" =~ ^(app|database|client|web|all)$ ]]; then
    SERVICE="$1"
    shift
fi

# Special case for exec command which needs the exec command
if [[ "$COMMAND" == "exec" && $# -gt 0 ]]; then
    EXEC_COMMAND="$*"
    shift $#
elif [[ "$COMMAND" == "exec" && $# -eq 0 ]]; then
    echo -e "${RED}Error: No command specified for exec${NC}"
    echo -e "Usage: ${GREEN}./start.sh${NC} ${YELLOW}exec <service> <command>${NC}"
    exit 1
fi

# Special case for restore command which needs the backup path
if [[ "$COMMAND" == "restore" && $# -gt 0 ]]; then
    BACKUP_PATH="$1"
    shift
fi

# Parse options
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -d|--detach)
            DETACHED="-d"
            shift
            ;;
        -f|--force)
            FORCE="--no-cache"
            shift
            ;;
        -c|--clean)
            CLEAN="--remove-orphans"
            shift
            ;;
        -t|--tail=*)
            if [[ "$1" == "--tail="* ]]; then
                LOG_TAIL="${1#*=}"
            else
                LOG_TAIL="$2"
                shift
            fi
            shift
            ;;
        --debug)
            DEBUG="true"
            set -x  # Enable debug output
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Unknown option '$1'${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Check Docker environment
check_docker

# Check for compose file (except for version command)
if [[ "$COMMAND" != "version" ]]; then
    check_compose_file
fi

# Execute command
case "$COMMAND" in
    start)
        if [ "$SERVICE" = "all" ]; then
            echo -e "${GREEN}Starting all services...${NC}"
            if [ -n "$FORCE" ]; then
                $DOCKER_COMPOSE build $FORCE
            fi
            $DOCKER_COMPOSE up $DETACHED $CLEAN
        else
            echo -e "${GREEN}Starting service: ${BLUE}$SERVICE${NC}"
            if [ -n "$FORCE" ]; then
                $DOCKER_COMPOSE build $FORCE $SERVICE
            fi
            $DOCKER_COMPOSE up $DETACHED $SERVICE
        fi
        ;;
    stop)
        if [ "$SERVICE" = "all" ]; then
            echo -e "${YELLOW}Stopping all services...${NC}"
            $DOCKER_COMPOSE down $CLEAN
        else
            echo -e "${YELLOW}Stopping service: ${BLUE}$SERVICE${NC}"
            $DOCKER_COMPOSE stop $SERVICE
        fi
        ;;
    restart)
        if [ "$SERVICE" = "all" ]; then
            echo -e "${YELLOW}Restarting all services...${NC}"
            $DOCKER_COMPOSE restart
        else
            echo -e "${YELLOW}Restarting service: ${BLUE}$SERVICE${NC}"
            $DOCKER_COMPOSE restart $SERVICE
        fi
        ;;
    status)
        echo -e "${BLUE}${BOLD}Checking status of containers:${NC}"
        if [ "$SERVICE" = "all" ]; then
            $DOCKER_COMPOSE ps
        else
            $DOCKER_COMPOSE ps $SERVICE
        fi
        ;;
    logs)
        if [ "$SERVICE" = "all" ]; then
            echo -e "${BLUE}${BOLD}Showing logs for all services:${NC}"
            $DOCKER_COMPOSE logs --tail=$LOG_TAIL -f
        else
            echo -e "${BLUE}${BOLD}Showing logs for service: ${GREEN}$SERVICE${NC}"
            $DOCKER_COMPOSE logs --tail=$LOG_TAIL -f $SERVICE
        fi
        ;;
    rebuild)
        if [ "$SERVICE" = "all" ]; then
            echo -e "${GREEN}Rebuilding and starting all services...${NC}"
            $DOCKER_COMPOSE down $CLEAN
            $DOCKER_COMPOSE build $FORCE
            $DOCKER_COMPOSE up $DETACHED
        else
            echo -e "${GREEN}Rebuilding and starting service: ${BLUE}$SERVICE${NC}"
            $DOCKER_COMPOSE stop $SERVICE
            $DOCKER_COMPOSE rm -f $SERVICE
            $DOCKER_COMPOSE build $FORCE $SERVICE
            $DOCKER_COMPOSE up $DETACHED $SERVICE
        fi
        ;;
    pull)
        if [ "$SERVICE" = "all" ]; then
            echo -e "${BLUE}Pulling latest images for all services...${NC}"
            $DOCKER_COMPOSE pull
        else
            echo -e "${BLUE}Pulling latest image for service: ${GREEN}$SERVICE${NC}"
            $DOCKER_COMPOSE pull $SERVICE
        fi
        ;;
    prune)
        echo -e "${YELLOW}Cleaning up unused Docker resources...${NC}"
        docker system prune -f
        echo -e "${GREEN}Cleaned up unused Docker resources${NC}"
        ;;
    backup)
        backup_volumes
        ;;
    restore)
        restore_from_backup "$BACKUP_PATH"
        ;;
    exec)
        echo -e "${BLUE}Executing command in ${SERVICE} container: ${YELLOW}${EXEC_COMMAND}${NC}"
        $DOCKER_COMPOSE exec $SERVICE $EXEC_COMMAND
        ;;
    health)
        check_health "$SERVICE"
        ;;
    version)
        echo -e "${BLUE}${BOLD}2009Scape Docker Management Script v${VERSION}${NC}"
        echo
        echo -e "${YELLOW}Docker version:${NC}"
        docker --version
        echo
        echo -e "${YELLOW}Docker Compose version:${NC}"
        $DOCKER_COMPOSE version
        ;;
esac

# Show helpful message after starting services
if [[ "$COMMAND" == "start" || "$COMMAND" == "rebuild" ]] && [[ -n "$DETACHED" ]]; then
    echo
    echo -e "${GREEN}${BOLD}Services started in detached mode. Use these commands to interact:${NC}"
    echo -e "  ${YELLOW}./start.sh status${NC}         # Check container status"
    echo -e "  ${YELLOW}./start.sh logs${NC}           # View logs from all services"
    echo -e "  ${YELLOW}./start.sh health${NC}         # Check health status of services"
    
    if [[ "$SERVICE" == "all" || "$SERVICE" == "client" ]]; then
        echo
        echo -e "${GREEN}${BOLD}To access the web client:${NC}"
        echo -e "  ${YELLOW}http://localhost:6080${NC}     # Direct noVNC connection"
        echo -e "  ${YELLOW}http://localhost${NC}          # Via Nginx (if configured)"
    fi
    
    if [[ "$SERVICE" == "all" || "$SERVICE" == "app" ]]; then
        echo
        echo -e "${GREEN}${BOLD}Game server information:${NC}"
        echo -e "  ${YELLOW}Server port: 43594${NC}"
        echo -e "  ${YELLOW}Management ports: 43595-43596${NC}"
    fi

    # Check service health after startup if not debugging
    if [[ -z "$DEBUG" ]]; then
        echo
        echo -e "${BLUE}${BOLD}Initial health check:${NC}"
        sleep 5  # Give services a moment to start
        check_health "$SERVICE"
    fi
fi