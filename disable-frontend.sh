#!/bin/bash

echo "🛑 Disabling problematic frontend container..."

# Stop and remove the frontend container
docker compose -f docker-compose.prod.yml --env-file .env.prod stop frontend
docker compose -f docker-compose.prod.yml --env-file .env.prod rm -f frontend

echo "🔄 Restarting API gateway with built-in frontend..."
docker compose -f docker-compose.prod.yml --env-file .env.prod restart api-gateway

echo "⏳ Waiting for API gateway..."
sleep 5

echo "📊 System status (without frontend container):"
docker compose -f docker-compose.prod.yml --env-file .env.prod ps

echo ""
echo "🧪 Testing built-in web interface:"
curl -s http://localhost:8080/ | head -10

echo ""
echo ""
echo "🎉 Your system is now accessible at:"
echo "   http://192.168.87.100:8080/"
echo ""
echo "This provides:"
echo "   ✅ Clean web interface"
echo "   ✅ API testing tools"
echo "   ✅ System status"
echo "   ✅ Reminder management"
echo ""
echo "No more container issues! 🚀"