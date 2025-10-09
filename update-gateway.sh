#!/bin/bash

echo "🔄 Updating API Gateway with built-in frontend..."

# Restart API gateway with new configuration
docker compose -f docker-compose.prod.yml --env-file .env.prod restart api-gateway

echo "⏳ Waiting for API gateway to restart..."
sleep 5

echo "📊 API Gateway status:"
docker compose -f docker-compose.prod.yml --env-file .env.prod ps api-gateway

echo ""
echo "🧪 Testing new frontend:"
curl -s http://localhost:8080/ | head -5

echo ""
echo ""
echo "🎉 Frontend is now available at:"
echo "   http://192.168.87.100:8080/"
echo "   or http://memo:8080/ (after hosts setup)"
echo ""
echo "This provides:"
echo "   ✅ Simple web interface"
echo "   ✅ API testing tools"  
echo "   ✅ System status"
echo "   ✅ Direct access to all functionality"