#!/bin/bash
# deploy_changed.sh — deploy only containers that changed

set -e

COMPOSE_FILE="docker-compose.prod.yml"
ENV_FILE=".env.prod"

echo "🚀 Checking for changes and deploying updated containers..."

# Pull latest changes
git pull

# Find services defined in docker-compose
SERVICES=$(docker compose -f $COMPOSE_FILE config --services)

# Track changed containers
CHANGED_CONTAINERS=()

# Check which services need rebuilding
for SERVICE in $SERVICES; do
  echo "🔍 Checking $SERVICE for changes..."

  # Try to build (it will skip if no changes)
  if docker compose -f $COMPOSE_FILE build --pull --quiet "$SERVICE"; then
    echo "✅ $SERVICE is up-to-date."
  else
    echo "⚙️ Changes detected in $SERVICE — rebuilding..."
    docker compose -f $COMPOSE_FILE build --no-cache "$SERVICE"
    CHANGED_CONTAINERS+=("$SERVICE")
  fi
done

# Restart changed containers
if [ ${#CHANGED_CONTAINERS[@]} -eq 0 ]; then
  echo "✨ No containers required rebuilding — system is already up-to-date."
else
  echo "🔁 Restarting changed containers: ${CHANGED_CONTAINERS[*]}"
  docker compose -f $COMPOSE_FILE stop "${CHANGED_CONTAINERS[@]}"
  docker compose -f $COMPOSE_FILE rm -f "${CHANGED_CONTAINERS[@]}"
  docker compose -f $COMPOSE_FILE up -d "${CHANGED_CONTAINERS[@]}"
fi

echo "📊 System status:"
docker compose -f $COMPOSE_FILE --env-file $ENV_FILE ps

echo "✅ Deployment complete!"
