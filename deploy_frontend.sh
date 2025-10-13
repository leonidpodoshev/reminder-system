#!/bin/bash

echo "🛑 Disabling problematic frontend container..."

# Stop and remove the frontend container
git pull
docker compose -f docker-compose.prod.yml build --no-cache frontend
docker compose -f docker-compose.prod.yml stop frontend
docker compose -f docker-compose.prod.yml rm -f frontend  
docker compose -f docker-compose.prod.yml up -d frontend

echo "⏳ Waiting for restart..."
sleep 5

echo "📊 System status:"
docker compose -f docker-compose.prod.yml --env-file .env.prod ps

