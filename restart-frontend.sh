#!/bin/bash

echo "🔄 Restarting frontend with new port..."

# Remove the failed frontend container
docker compose -f docker-compose.prod.yml --env-file .env.prod rm -f frontend

# Start frontend with new configuration
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d frontend

echo "⏳ Waiting for frontend to start..."
sleep 10

echo "📊 Frontend status:"
docker compose -f docker-compose.prod.yml --env-file .env.prod ps frontend

echo ""
echo "🎉 Frontend should now be available at:"
echo "   http://localhost:3001"
echo "   or http://memo:3001 (after hosts file setup)"