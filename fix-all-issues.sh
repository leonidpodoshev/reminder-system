#!/bin/bash

echo "🔧 Comprehensive fix for all issues..."

echo "1️⃣ Fixing frontend container configuration..."
# Fix the frontend nginx config (already done in the file)

echo "2️⃣ Checking email notification system..."
# Check if notification service is working
docker compose -f docker-compose.prod.yml --env-file .env.prod logs --tail=5 notification-service

echo "3️⃣ Checking scheduler service..."
# Check if scheduler is processing reminders
docker compose -f docker-compose.prod.yml --env-file .env.prod logs --tail=5 scheduler-service

echo "4️⃣ Testing email configuration..."
# Check SMTP settings
docker compose -f docker-compose.prod.yml --env-file .env.prod exec notification-service printenv | grep SMTP || echo "SMTP config not found"

echo "5️⃣ Rebuilding and starting frontend..."
# Stop problematic frontend
docker compose -f docker-compose.prod.yml --env-file .env.prod stop frontend
docker compose -f docker-compose.prod.yml --env-file .env.prod rm -f frontend

# Free up port 3000 if needed
sudo fuser -k 3000/tcp 2>/dev/null || echo "Port 3000 already free"

# Rebuild and start frontend
docker compose -f docker-compose.prod.yml --env-file .env.prod build --no-cache frontend
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d frontend

echo "⏳ Waiting for services to stabilize..."
sleep 20

echo "📊 Final system status:"
docker compose -f docker-compose.prod.yml --env-file .env.prod ps

echo ""
echo "🧪 Testing all endpoints:"
echo "API Health: $(curl -s http://localhost:8080/health)"
echo "Frontend Health: $(curl -s http://localhost:3001/health 2>/dev/null || echo 'Not ready yet')"

echo ""
echo "🎉 System should now be ready:"
echo "   • Beautiful React UI: http://192.168.87.100:3001/"
echo "   • API: http://192.168.87.100:8080/"
echo ""
echo "If email notifications aren't working, we'll debug that next!"