#!/bin/bash

# Script to build KumbiaPHP application with Docker

set -e

# Load configuration
if [ -f config.env ]; then
    set -a  # Export all variables
    source config.env
    set +a  # Stop exporting
fi

# Function to show help
show_help() {
    echo "Usage: ./build.sh [options]"
    echo ""
    echo "Options:"
    echo "  -k, --kumbiaphp-version VERSION   KumbiaPHP version (default: $KUMBIAPHP_VERSION)"
    echo "  -m, --mysql-version VERSION       MySQL version (default: $MYSQL_VERSION)"
    echo "  -p, --php-version VERSION         PHP version (default: $PHP_VERSION)"
    echo "  -r, --replicas NUMBER             Number of replicas (default: $REPLICAS)"
    echo "  --no-cache                        Build without cache"
    echo "  -h, --help                        Show this help"
    echo ""
    echo "Examples:"
    echo "  ./build.sh                                    # Use default values"
    echo "  ./build.sh -k v1.2.1 -m 8.0 -p 8.2           # Specific versions"
    echo "  ./build.sh --no-cache                        # Rebuild from scratch"
}

# Default values from config.env
KUMBIAPHP_VERSION=${KUMBIAPHP_VERSION:-1.2.1}
MYSQL_VERSION=${MYSQL_VERSION:-8.0}
PHP_VERSION=${PHP_VERSION:-8.4.1}
REPLICAS=${REPLICAS:-3}
NO_CACHE=""

# Process arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -k|--kumbiaphp-version)
            KUMBIAPHP_VERSION="$2"
            shift 2
            ;;
        -m|--mysql-version)
            MYSQL_VERSION="$2"
            shift 2
            ;;
        -p|--php-version)
            PHP_VERSION="$2"
            shift 2
            ;;
        -r|--replicas)
            REPLICAS="$2"
            shift 2
            ;;
        --no-cache)
            NO_CACHE="--no-cache"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

echo "Building KumbiaPHP application..."
echo "KumbiaPHP Version: $KUMBIAPHP_VERSION"
echo "MySQL Version: $MYSQL_VERSION"
echo "PHP Version: $PHP_VERSION"
echo "Replicas: $REPLICAS"

# Create necessary directories for bind mounts
echo "Creating necessary directories..."
if [ ! -d "app" ]; then
    mkdir -p app
    echo "Created app/ directory"
else
    echo "app/ directory already exists"
fi
mkdir -p mysql/data
echo "Directories ready: app/, mysql/data/"

# Update config.env with new versions
cat > config.env << EOF
# Version configuration
KUMBIAPHP_VERSION=$KUMBIAPHP_VERSION
MYSQL_VERSION=$MYSQL_VERSION
PHP_VERSION=$PHP_VERSION

# Database configuration
MYSQL_ROOT_PASSWORD=kumbia_root_pass
MYSQL_DATABASE=kumbia_db
MYSQL_USER=kumbia_user
MYSQL_PASSWORD=kumbia_pass

# Application configuration
APP_NAME=kumbia-app
APP_PORT=8180
MYSQL_PORT=8181
PHPMYADMIN_PORT=8182

# Docker Swarm configuration
REPLICAS=$REPLICAS
NETWORK_NAME=kumbia_network
EOF

# Build image
echo "Building Docker image..."
docker build $NO_CACHE \
    --build-arg PHP_VERSION=$PHP_VERSION \
    --build-arg KUMBIAPHP_VERSION=$KUMBIAPHP_VERSION \
    -t kumbia-app:latest .

echo "Build completed!"
echo ""
echo "To deploy on Docker Swarm, run:"
echo "  ./deploy.sh" 