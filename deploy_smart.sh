
#!/bin/bash
# deploy_smart.sh — deploy only containers whose source files changed
# Usage:
#   ./deploy_smart.sh           → normal deploy
#   ./deploy_smart.sh --dry-run → just show what would be rebuilt

set -e

COMPOSE_FILE="docker-compose.prod.yml"
ENV_FILE=".env.prod"
BRANCH="main"  # change if your main branch name differs

DRY_RUN=false
if [ "$1" == "--dry-run" ]; then
  DRY_RUN=true
  echo "🧪 Running in DRY RUN mode — no containers will be rebuilt or restarted."
fi

echo "🚀 Smart deploy started..."

# Step 1. Fetch latest remote info
git fetch origin "$BRANCH"

# Step 2. Detect changed files
CHANGED_FILES=$(git diff --name-only HEAD..origin/"$BRANCH" || true)

if [ -z "$CHANGED_FILES" ]; then
  echo "✅ No upstream changes — nothing to deploy."
  exit 0
fi

echo "⬇️ Pulling latest code..."
git pull origin "$BRANCH"

# Step 3. List all services defined in compose file
SERVICES=$(docker compose -f "$COMPOSE_FILE" config --services)
CHANGED_CONTAINERS=()

# Step 4. Check which services’ build contexts contain changed files
for SERVICE in $SERVICES; do
  echo "🔍 Checking $SERVICE..."

  # Get the build context path for each service
  CONTEXT=$(docker compose -f "$COMPOSE_FILE" config | \
    awk "/^services:/{f=0} f; /^  $SERVICE:/{f=1} /context:/ {print \$2; exit}")

  # Default context to "." if not found
  if [ -z "$CONTEXT" ]; then
    CONTEXT="."
  fi

  # Match any changed file within this context
  MATCH=$(echo "$CHANGED_FILES" | grep -E "^$CONTEXT(/|$)" || true)

  if [ -n "$MATCH" ]; then
    echo "⚙️  Changes detected in $SERVICE (context: $CONTEXT)"
    CHANGED_CONTAINERS+=("$SERVICE")
  else
    echo "✅ $SERVICE unaffected"
  fi
done

# Step 5. Rebuild/restart changed containers
if [ ${#CHANGED_CONTAINERS[@]} -eq 0 ]; then
  echo "✨ No containers need rebuilding — all up-to-date."
else
  echo "🔁 Containers to update: ${CHANGED_CONTAINERS[*]}"

  if [ "$DRY_RUN" = true ]; then
    echo "🧪 Dry run: would rebuild/restart ${CHANGED_CONTAINERS[*]}"
  else
    echo "⚙️  Rebuilding and restarting..."
    docker compose -f "$COMPOSE_FILE" build --no-cache "${CHANGED_CONTAINERS[@]}"
    docker compose -f "$COMPOSE_FILE" stop "${CHANGED_CONTAINERS[@]}"
    docker compose -f "$COMPOSE_FILE" rm -f "${CHANGED_CONTAINERS[@]}"
    docker compose -f "$COMPOSE_FILE" up -d "${CHANGED_CONTAINERS[@]}"
  fi
fi

echo "📊 System status:"
docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" ps

echo "✅ Smart deploy complete!"
