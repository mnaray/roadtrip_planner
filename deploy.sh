#!/bin/bash

# Roadtrip Planner Production Deployment Script
# Usage: ./deploy.sh <version> [compose-file-path]
# Example: ./deploy.sh v1.2.3 ./docker-compose.production.yml

set -e  # Exit immediately if a command exits with a non-zero status

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}[$(date +'%Y-%m-%d %H:%M:%S')] ${message}${NC}"
}

print_info() { print_message "$BLUE" "$1"; }
print_success() { print_message "$GREEN" "$1"; }
print_warning() { print_message "$YELLOW" "$1"; }
print_error() { print_message "$RED" "$1"; }

# Check if version argument is provided
if [ $# -eq 0 ]; then
    print_error "ERROR: Version argument is required!"
    echo ""
    echo "Usage: $0 <version> [compose-file-path]"
    echo "Example: $0 v1.2.3 ./docker-compose.production.yml"
    echo ""
    echo "The version should match the Docker image tag (e.g., v1.2.3 for mnaray/roadtrip-planner:v1.2.3)"
    exit 1
fi

VERSION=$1
COMPOSE_FILE=${2:-./docker-compose.production.yml}
IMAGE_NAME="mnaray/roadtrip-planner:${VERSION}"

print_info "Starting deployment for Roadtrip Planner version: ${VERSION}"
print_info "Using compose file: ${COMPOSE_FILE}"

# Verify compose file exists
if [ ! -f "${COMPOSE_FILE}" ]; then
    print_error "ERROR: Compose file '${COMPOSE_FILE}' not found!"
    echo ""
    echo "Please provide the correct path to your docker-compose.production.yml file."
    echo "You can download the latest version from:"
    echo "https://github.com/mnaray/roadtrip_planner/blob/main/docker-compose.production.yml"
    exit 1
fi

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    print_error "ERROR: Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose >/dev/null 2>&1 && ! docker compose version >/dev/null 2>&1; then
    print_error "ERROR: Neither 'docker-compose' nor 'docker compose' is available."
    print_error "Please install Docker Compose and try again."
    exit 1
fi

# Function to run docker compose command (handles both docker-compose and docker compose)
run_compose() {
    if command -v docker-compose >/dev/null 2>&1; then
        docker-compose -f "${COMPOSE_FILE}" "$@"
    else
        docker compose -f "${COMPOSE_FILE}" "$@"
    fi
}

print_info "Pulling new Docker image: ${IMAGE_NAME}"
if ! docker pull "${IMAGE_NAME}"; then
    print_error "ERROR: Failed to pull image ${IMAGE_NAME}"
    print_error "Please verify that:"
    print_error "  1. The version '${VERSION}' exists on Docker Hub"
    print_error "  2. You have internet connectivity"
    print_error "  3. The image name is correct: ${IMAGE_NAME}"
    exit 1
fi

print_success "Successfully pulled image: ${IMAGE_NAME}"

# Update the compose file to use the specific version
print_info "Updating compose file to use version ${VERSION}"
if command -v sed >/dev/null 2>&1; then
    # Create a backup of the original compose file
    cp "${COMPOSE_FILE}" "${COMPOSE_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Update the image tag in the compose file
    sed -i "s|mnaray/roadtrip-planner:.*|mnaray/roadtrip-planner:${VERSION}|g" "${COMPOSE_FILE}"
    print_success "Updated compose file with version ${VERSION}"
else
    print_warning "Warning: 'sed' command not found. Please manually update the image tag in ${COMPOSE_FILE}"
    print_warning "Change 'mnaray/roadtrip-planner:latest' to 'mnaray/roadtrip-planner:${VERSION}'"
    echo ""
    read -p "Press Enter when you have updated the compose file manually..."
fi

# Stop the current services gracefully
print_info "Stopping current services..."
run_compose down --timeout 30

# Pull any other updated images (like postgres)
print_info "Pulling updated base images..."
run_compose pull --quiet

# Start the services with the new image
print_info "Starting services with new version..."
run_compose up -d

# Wait for services to be healthy
print_info "Waiting for services to start..."
sleep 10

# Check service health
print_info "Checking service health..."
RETRIES=0
MAX_RETRIES=30

while [ $RETRIES -lt $MAX_RETRIES ]; do
    if run_compose ps --services --filter "status=running" | grep -q "web"; then
        print_success "Web service is running!"
        break
    fi
    
    RETRIES=$((RETRIES + 1))
    print_info "Waiting for services to start... (${RETRIES}/${MAX_RETRIES})"
    sleep 5
done

if [ $RETRIES -eq $MAX_RETRIES ]; then
    print_error "ERROR: Services failed to start properly after ${MAX_RETRIES} attempts"
    print_error "Checking service logs..."
    run_compose logs --tail=50
    exit 1
fi

# Run database migrations if needed
print_info "Running database migrations..."
if run_compose exec -T web rails db:migrate; then
    print_success "Database migrations completed successfully"
else
    print_warning "Warning: Database migrations failed or were not needed"
fi

# Final health check
print_info "Performing final health check..."
sleep 5

if run_compose ps --services --filter "status=running" | grep -q "web"; then
    print_success "✅ Deployment completed successfully!"
    print_success "✅ Roadtrip Planner ${VERSION} is now running"
    echo ""
    print_info "Service status:"
    run_compose ps
    echo ""
    print_info "To view logs: docker compose -f ${COMPOSE_FILE} logs -f"
    print_info "To stop services: docker compose -f ${COMPOSE_FILE} down"
else
    print_error "❌ Deployment verification failed"
    print_error "Services may not be running properly. Check logs with:"
    print_error "docker compose -f ${COMPOSE_FILE} logs"
    exit 1
fi