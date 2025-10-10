#!/bin/bash

echo "🚀 Deploying multiple email address support..."

echo "1️⃣ Rebuilding services with multiple email support..."
docker compose -f docker-compose.prod.yml --env-file .env.prod build --no-cache frontend notification-service

echo ""
echo "2️⃣ Restarting services..."
docker compose -f docker-compose.prod.yml --env-file .env.prod restart frontend notification-service

echo ""
echo "3️⃣ Waiting for services to stabilize..."
sleep 15

echo ""
echo "4️⃣ Checking service status:"
docker compose -f docker-compose.prod.yml --env-file .env.prod ps frontend notification-service

echo ""
echo "5️⃣ Testing the enhanced system:"
echo "Frontend: $(curl -s http://localhost:3001/health 2>/dev/null && echo '✅ Ready' || echo '❌ Not ready')"
echo "API: $(curl -s http://localhost:8090/health)"

echo ""
echo "🎉 Multiple email support deployed!"
echo ""
echo "✨ New Features:"
echo "   📧 Multiple email recipients per reminder"
echo "   🔍 Real-time email validation"
echo "   👥 Visual recipient preview"
echo "   ✅ Enhanced form validation"
echo ""
echo "📋 How to use:"
echo "   1. Go to http://192.168.87.100:3001/"
echo "   2. Create a new reminder"
echo "   3. In the Email field, enter multiple addresses like:"
echo "      user1@example.com, user2@example.com"
echo "      or user3@example.com; user4@example.com"
echo "   4. See the recipient preview below the field"
echo "   5. All recipients will receive the reminder!"
echo ""
echo "🏠 Home network access:"
echo "   http://memo:3001/ (after hosts file setup)"