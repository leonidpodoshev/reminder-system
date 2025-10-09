#!/bin/bash

echo "🔄 Updating web interface with full reminder creation..."

# Restart API gateway with enhanced interface
docker compose -f docker-compose.prod.yml --env-file .env.prod restart api-gateway

echo "⏳ Waiting for API gateway to restart..."
sleep 5

echo "📊 API Gateway status:"
docker compose -f docker-compose.prod.yml --env-file .env.prod ps api-gateway

echo ""
echo "🧪 Testing enhanced interface:"
curl -s http://localhost:8080/ | grep -o '<title>.*</title>'

echo ""
echo ""
echo "🎉 Enhanced web interface is now available at:"
echo "   http://192.168.87.100:8080/"
echo ""
echo "New features:"
echo "   ✅ Full reminder creation form"
echo "   ✅ Email and SMS notification options"
echo "   ✅ Date/time picker"
echo "   ✅ Reminder list with status"
echo "   ✅ Real-time updates"
echo "   ✅ Clean, responsive design"
echo ""
echo "You can now create reminders directly from the web interface! 🚀"