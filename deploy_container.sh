#!/bin/bash

# Usage: ./deploy_container.sh <container_name>
# Example: ./deploy_container.sh frontend

CONTAINER_NAME=$1

if [ -z "$CONTAINER_NAME" ]; then
  echo "❌ Error: You must specify a container name."
  echo "Usage: $0 <container_name>"
  exit 1
fi

echo "🛑 Disabling problematic container: $CONTAINER_NAME..."

# Pull latest code
git pull

# Build the specified container without cache
docker compose -f docker-compose.prod.yml build --no-cache "$CONTAINER_NAME"

# Stop and remove the container
docker compose -f docker-compose.prod.yml stop "$CONTAINER_NAME"
docker compose -f docker-compose.prod.yml rm -f "$CONTAINER_NAME"

# Start the container again
docker compose -f docker-compose.prod.yml up -d "$CONTAINER_NAME"

echo "⏳ Waiting for restart..."
sleep 5

echo "📊 System status:"
docker compose -f docker-compose.prod.yml --env-file .env.prod ps
