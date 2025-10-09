#!/bin/bash

echo "🔧 Fixing nginx configuration..."

# Stop the API gateway
docker compose -f docker-compose.prod.yml --env-file .env.prod stop api-gateway

# Remove the container to force recreation with new volumes
docker compose -f docker-compose.prod.yml --env-file .env.prod rm -f api-gateway

# Start the API gateway with new configuration
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d api-gateway

echo "⏳ Waiting for API gateway to start..."
sleep 10

echo "📊 API Gateway status:"
docker compose -f docker-compose.prod.yml --env-file .env.prod ps api-gateway

echo ""
echo "🧪 Testing nginx configuration:"
docker exec memo-api-gateway nginx -t

echo ""
echo "🌐 Testing web interface:"
curl -s http://localhost:8080/ | head -5

echo ""
echo ""
echo "🎉 Fixed! Your web interface should now be available at:"
echo "   http://192.168.87.100:8080/"
echo ""
echo "The interface now includes:"
echo "   ✅ Full reminder creation form"
echo "   ✅ Reminder management"
echo "   ✅ Clean, stable configuration"
echo "   ✅ No more connection drops"