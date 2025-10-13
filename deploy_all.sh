#!/bin/bash

# deploy_all.sh — rebuild and restart all containers

echo "🚀 Deploying ALL containers..."

# Pull latest changes from Git
git pull

# Rebuild all images without cache
docker compose -f docker-compose.prod.yml build --no-cache

# Stop and remove all running containers
docker compose -f docker-compose.prod.yml down

# Start all containers in detached mode
docker compose -f docker-compose.prod.yml up -d

echo "⏳ Waiting for restart..."
sleep 5

echo "📊 System status:"
docker compose -f docker-compose.prod.yml --env-file .env.prod ps

echo "✅ Deployment complete!"
