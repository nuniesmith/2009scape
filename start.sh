#!/bin/bash

# Default service name is 'app' if not provided
SERVICE_NAME=${1:-app}

echo "Starting service: $SERVICE_NAME"

# Clear terminal, stop, rebuild and start the service
clear && docker compose down $SERVICE_NAME && docker compose build $SERVICE_NAME && docker compose up $SERVICE_NAME