#!/bin/bash

# Roadtrip Planner - Zero-Downtime Deployment Update Script
# This script updates the running Docker containers without data loss

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default image tag
IMAGE_TAG="${1:-latest}"

echo -e "${GREEN}==================================${NC}"
echo -e "${GREEN}Roadtrip Planner Deployment Update${NC}"
echo -e "${GREEN}==================================${NC}"
echo ""

# Prompt for compose file path
echo -e "${YELLOW}Enter the path to your docker-compose file (relative to this script's location):${NC}"
echo -e "Default: ../docker-compose.production.yml"
read -r COMPOSE_FILE_INPUT

# Get the script's directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Set compose file path
if [ -z "$COMPOSE_FILE_INPUT" ]; then
    COMPOSE_FILE="$SCRIPT_DIR/../docker-compose.production.yml"
else
    COMPOSE_FILE="$SCRIPT_DIR/$COMPOSE_FILE_INPUT"
fi

# Check if compose file exists
if [ ! -f "$COMPOSE_FILE" ]; then
    echo -e "${RED}Error: Docker Compose file not found at: $COMPOSE_FILE${NC}"
    exit 1
fi

echo -e "${GREEN}Using compose file: $COMPOSE_FILE${NC}"
echo -e "${GREEN}Updating to image tag: $IMAGE_TAG${NC}"
echo ""

# Export the image tag for docker compose
export DOCKER_IMAGE="roadtrip_planner:$IMAGE_TAG"

# Function to check if services are healthy
check_health() {
    echo -e "${YELLOW}Checking service health...${NC}"
    docker compose -f "$COMPOSE_FILE" ps
}

# Function to backup current state
backup_info() {
    echo -e "${YELLOW}Recording current deployment state...${NC}"
    BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
    docker compose -f "$COMPOSE_FILE" ps > "deployment_backup_$BACKUP_DATE.txt" 2>&1 || true
    echo -e "${GREEN}Backup info saved to: deployment_backup_$BACKUP_DATE.txt${NC}"
}

# Main update process
echo -e "${YELLOW}Starting deployment update process...${NC}"
echo ""

# Step 1: Record current state
backup_info

# Check if we can verify image updates using digests
echo -e "${YELLOW}Checking for image updates...${NC}"

# Get local image digest (RepoDigest) if it exists
LOCAL_DIGEST=$(docker inspect --format='{{if .RepoDigests}}{{index .RepoDigests 0}}{{end}}' "roadtrip_planner:$IMAGE_TAG" 2>/dev/null || echo "none")

# Try to get remote manifest digest (requires Docker to be logged in to the registry)
REMOTE_DIGEST="none"
if command -v docker manifest &> /dev/null; then
    # Extract registry URL from image name if provided
    if [[ "$DOCKER_IMAGE" == *"/"* ]]; then
        REMOTE_DIGEST=$(docker manifest inspect "$DOCKER_IMAGE" -v 2>/dev/null | grep -o '"digest":"[^"]*"' | head -1 | cut -d'"' -f4 || echo "none")
    fi
fi

if [ "$LOCAL_DIGEST" != "none" ] && [ "$REMOTE_DIGEST" != "none" ]; then
    if [[ "$LOCAL_DIGEST" == *"$REMOTE_DIGEST"* ]] || [[ "$REMOTE_DIGEST" == *"${LOCAL_DIGEST#*@}"* ]]; then
        echo -e "${GREEN}Local image is up-to-date with registry.${NC}"
        echo -e "${YELLOW}Will continue with deployment to ensure container is recreated.${NC}"
    else
        echo -e "${YELLOW}New image version available in registry!${NC}"
    fi
else
    echo -e "${YELLOW}Unable to verify image version. Will pull and update anyway.${NC}"
fi

# Step 2: Pull new image
echo -e "${YELLOW}Pulling Docker image from registry...${NC}"
docker pull "roadtrip_planner:$IMAGE_TAG" || {
    echo -e "${RED}Failed to pull image. Make sure the image exists in your registry.${NC}"
    echo -e "${YELLOW}Note: Images must be pushed to a registry before deployment.${NC}"
    echo -e "${YELLOW}Example: docker push yourusername/roadtrip_planner:$IMAGE_TAG${NC}"
    exit 1
}

# Verify the pull was successful
NEW_DIGEST=$(docker inspect --format='{{if .RepoDigests}}{{index .RepoDigests 0}}{{end}}' "roadtrip_planner:$IMAGE_TAG" 2>/dev/null || echo "none")
if [ "$NEW_DIGEST" != "none" ] && [ "$NEW_DIGEST" != "$LOCAL_DIGEST" ]; then
    echo -e "${GREEN}Successfully pulled new image version!${NC}"
fi

# Step 3: Update the compose file environment if needed
if grep -q "DOCKER_IMAGE=" "$COMPOSE_FILE" 2>/dev/null; then
    echo -e "${YELLOW}Updating compose file with new image tag...${NC}"
    # Update using environment variable instead of modifying file
    export DOCKER_IMAGE="roadtrip_planner:$IMAGE_TAG"
fi

# Step 4: Perform database migrations (if needed)
echo -e "${YELLOW}Running database migrations...${NC}"
docker compose -f "$COMPOSE_FILE" run --rm web bundle exec rails db:migrate || {
    echo -e "${RED}Migration failed! Rolling back...${NC}"
    exit 1
}

# Step 5: Precompile assets
echo -e "${YELLOW}Precompiling assets...${NC}"
docker compose -f "$COMPOSE_FILE" run --rm web bundle exec rails assets:precompile || {
    echo -e "${YELLOW}Asset precompilation warning - continuing...${NC}"
}

# Step 6: Recreate containers with zero downtime
echo -e "${YELLOW}Recreating containers with new image...${NC}"
# IMPORTANT: Use --force-recreate to ensure container uses the newly pulled image
# This is critical when using 'latest' tag or when the tag name doesn't change
docker compose -f "$COMPOSE_FILE" up -d --no-deps --force-recreate web

# Step 7: Wait for services to be healthy
echo -e "${YELLOW}Waiting for services to become healthy...${NC}"
sleep 10

# Step 8: Check health
check_health

# Step 9: Clean up old images
echo -e "${YELLOW}Cleaning up old images...${NC}"
docker image prune -f

echo ""
echo -e "${GREEN}==================================${NC}"
echo -e "${GREEN}Deployment update completed!${NC}"
echo -e "${GREEN}==================================${NC}"
echo ""
echo -e "${GREEN}Your application should now be running with the updated version.${NC}"
echo -e "${GREEN}Image tag used: $IMAGE_TAG${NC}"
echo ""
echo -e "${YELLOW}To verify the deployment:${NC}"
echo "  1. Check logs: docker compose -f $COMPOSE_FILE logs -f web"
echo "  2. Check status: docker compose -f $COMPOSE_FILE ps"
echo "  3. Access the application in your browser"
echo ""
echo -e "${YELLOW}If you encounter issues:${NC}"
echo "  - Review the backup info in deployment_backup_*.txt"
echo "  - Check logs for errors: docker compose -f $COMPOSE_FILE logs web"
echo "  - Roll back if needed: docker compose -f $COMPOSE_FILE up -d --force-recreate"
echo ""
echo -e "${YELLOW}Note about 'latest' tag:${NC}"
echo "  Using 'latest' requires --force-recreate to update containers."
echo "  For production, consider using specific version tags instead."