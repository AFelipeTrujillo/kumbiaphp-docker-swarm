#!/bin/bash

# Script to deploy on Docker Swarm

set -e

# Load configuration
if [ -f config.env ]; then
    set -a  # Export all variables
    source config.env
    set +a  # Stop exporting
else
    echo "config.env file not found. Run ./build.sh first."
    exit 1
fi

# Function to show help
show_help() {
    echo "Usage: ./deploy.sh [options]"
    echo ""
    echo "Options:"
    echo "  --init                 Initialize Docker Swarm (first time only)"
    echo "  --update               Update existing services"
    echo "  --remove               Remove complete stack"
    echo "  --logs [service]       Show logs (kumbia-app, mysql, phpmyadmin)"
    echo "  --status               Show services status"
    echo "  -h, --help             Show this help"
    echo ""
    echo "Examples:"
    echo "  ./deploy.sh --init     # First time"
    echo "  ./deploy.sh            # Deploy/update"
    echo "  ./deploy.sh --logs     # View all logs"
    echo "  ./deploy.sh --logs kumbia-app  # View specific logs"
}

# Function to initialize Swarm
init_swarm() {
    echo "Initializing Docker Swarm..."
    
    if ! docker info | grep -q "Swarm: active"; then
        docker swarm init
        echo "Docker Swarm initialized"
    else
        echo "Docker Swarm is already active"
    fi
    
    # Create overlay network if it doesn't exist
    if ! docker network ls | grep -q kumbia_network; then
        docker network create --driver overlay --attachable kumbia_network
        echo "Network kumbia_network created"
    else
        echo "Network kumbia_network already exists"
    fi
}

# Function to deploy
deploy() {
    echo "Deploying application on Docker Swarm..."
    
    # Check and install KumbiaPHP in app/ folder if it doesn't exist
    if [ ! -d "app" ] || [ -z "$(ls -A app 2>/dev/null)" ]; then
        echo "Downloading KumbiaPHP $KUMBIAPHP_VERSION..."
        rm -rf app
        git clone https://github.com/KumbiaPHP/KumbiaPHP.git app --branch $KUMBIAPHP_VERSION
        echo "KumbiaPHP installed in ./app/"
    else
        echo "KumbiaPHP is already installed in ./app/"
    fi
    
    echo "Configuration:"
    echo "   - KumbiaPHP: $KUMBIAPHP_VERSION"
    echo "   - MySQL: $MYSQL_VERSION"
    echo "   - PHP: $PHP_VERSION"
    echo "   - Web Server: $WEBSERVER"
    echo "   - Replicas: $REPLICAS"
    echo "   - Application Port: $APP_PORT"
    echo "   - MySQL Port: $MYSQL_PORT"
    echo "   - phpMyAdmin Port: $PHPMYADMIN_PORT"
    
    # Verify that variables are exported (debug)
    echo "Verifying environment variables..."
    echo "   APP_PORT exported: $(printenv APP_PORT)"
    echo "   PHPMYADMIN_PORT exported: $(printenv PHPMYADMIN_PORT)"
    
    # Deploy stack
    docker stack deploy -c docker-compose.yml kumbia-stack
    
    echo "Application deployed!"
    echo ""
    echo "Available URLs:"
    echo "   - Application: http://localhost:$APP_PORT"
    echo "   - phpMyAdmin: http://localhost:$PHPMYADMIN_PORT"
    echo ""
    echo "To view status: ./deploy.sh --status"
    echo "To view logs: ./deploy.sh --logs"
}

# Function to show status
show_status() {
    echo "Services status:"
    echo ""
    docker stack services kumbia-stack
    echo ""
    echo "Containers:"
    docker stack ps kumbia-stack
}

# Function to show logs
show_logs() {
    local service=$1
    
    if [ -z "$service" ]; then
        echo "Logs from all services:"
        echo ""
        echo "=== Logs from kumbia-app ==="
        docker service logs kumbia-stack_kumbia-app --tail 50
        echo ""
        echo "=== Logs from mysql ==="
        docker service logs kumbia-stack_mysql --tail 50
        echo ""
        echo "=== Logs from phpmyadmin ==="
        docker service logs kumbia-stack_phpmyadmin --tail 50
    else
        echo "Logs from $service:"
        docker service logs kumbia-stack_$service --tail 100 --follow
    fi
}

# Function to remove stack
remove_stack() {
    echo "Removing stack kumbia-stack..."
    docker stack rm kumbia-stack
    echo "Stack removed"
    
    echo "Cleaning orphaned volumes..."
    docker volume prune -f
    echo "Cleanup completed"
}

# Procesar argumentos
case "${1:-deploy}" in
    --init)
        init_swarm
        deploy
        ;;
    deploy|"")
        # Check if Swarm is active
        if ! docker info | grep -q "Swarm: active"; then
            echo "Docker Swarm is not active. Run: ./deploy.sh --init"
            exit 1
        fi
        deploy
        ;;
    --update)
        echo "Updating services..."
        deploy
        ;;
    --remove)
        remove_stack
        ;;
    --logs)
        show_logs $2
        ;;
    --status)
        show_status
        ;;
    -h|--help)
        show_help
        ;;
    *)
        echo "Unknown option: $1"
        show_help
        exit 1
        ;;
esac 