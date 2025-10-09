#!/bin/bash

echo "🔍 Checking nginx status and logs..."

echo "📊 API Gateway container status:"
docker compose -f docker-compose.prod.yml --env-file .env.prod ps api-gateway

echo ""
echo "📋 API Gateway logs:"
docker compose -f docker-compose.prod.yml --env-file .env.prod logs --tail=20 api-gateway

echo ""
echo "🔧 Testing nginx configuration:"
docker exec memo-api-gateway nginx -t 2>&1 || echo "Nginx config test failed"

echo ""
echo "🌐 Port check:"
netstat -tlnp | grep :8080 || echo "Port 8080 not listening"