#!/bin/bash

echo "🔧 Fixing the original React frontend..."

# First, let's see what's using port 3000
echo "🔍 Checking what's using port 3000:"
lsof -i :3000 || echo "Port 3000 is free"

# Stop and remove the problematic frontend container
echo "🛑 Stopping frontend container..."
docker compose -f docker-compose.prod.yml --env-file .env.prod stop frontend
docker compose -f docker-compose.prod.yml --env-file .env.prod rm -f frontend

# Kill any process using port 3000 (if needed)
echo "🔪 Freeing up port 3000..."
sudo fuser -k 3000/tcp 2>/dev/null || echo "Port 3000 already free"

# Rebuild the frontend with the fixed configuration
echo "🔨 Rebuilding frontend with fixed configuration..."
docker compose -f docker-compose.prod.yml --env-file .env.prod build --no-cache frontend

# Start the frontend
echo "🚀 Starting fixed frontend..."
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d frontend

echo "⏳ Waiting for frontend to start..."
sleep 15

echo "📊 Frontend status:"
docker compose -f docker-compose.prod.yml --env-file .env.prod ps frontend

echo ""
echo "📋 Frontend logs:"
docker compose -f docker-compose.prod.yml --env-file .env.prod logs --tail=10 frontend

echo ""
echo "🧪 Testing frontend connectivity:"
curl -f http://localhost:3001/health 2>/dev/null && echo "✅ Frontend health check passed" || echo "❌ Frontend health check failed"

echo ""
echo "🎉 If successful, your beautiful React frontend should be available at:"
echo "   http://192.168.87.100:3001/"
echo "   or http://memo:3001/ (after hosts setup)"