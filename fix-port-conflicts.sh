#!/bin/bash

echo "🔧 Fixing port conflicts between Memo and docbox systems..."

echo "1️⃣ Stopping Memo system to free up conflicting ports..."
docker compose -f docker-compose.prod.yml --env-file .env.prod down

echo ""
echo "2️⃣ Restarting docbox system (document_manager)..."
# Find and restart docbox containers
docker restart document_manager-backend-1 document_manager-frontend-1

echo ""
echo "3️⃣ Waiting for docbox to stabilize..."
sleep 10

echo ""
echo "4️⃣ Starting Memo system with new ports (API: 8090, Frontend: 3001)..."
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d

echo ""
echo "5️⃣ Waiting for Memo system to start..."
sleep 20

echo ""
echo "6️⃣ Checking final port assignments:"
echo "Port 8081 (should be docbox backend only):"
sudo lsof -i :8081
echo ""
echo "Port 8090 (should be Memo API):"
sudo lsof -i :8090
echo ""
echo "Port 3000 (should be docbox frontend):"
sudo lsof -i :3000
echo ""
echo "Port 3001 (should be Memo frontend):"
sudo lsof -i :3001

echo ""
echo "7️⃣ Testing both systems:"
echo "Testing docbox (should work now):"
curl -I http://192.168.87.100/ 2>/dev/null && echo "✅ Docbox HTTP working" || echo "❌ Docbox HTTP still not working"

echo ""
echo "Testing Memo API (new port 8090):"
curl -s http://localhost:8090/health && echo "✅ Memo API working on port 8090" || echo "❌ Memo API not responding"

echo ""
echo "Testing Memo Frontend:"
curl -I http://localhost:3001/health 2>/dev/null && echo "✅ Memo Frontend working" || echo "❌ Memo Frontend not responding"

echo ""
echo "🎉 If successful, your systems should now be accessible at:"
echo "   • Docbox: https://docbox/ (original URL)"
echo "   • Memo API: http://memo:8090/ (changed from 8080)"
echo "   • Memo Frontend: http://memo:3001/ (unchanged)"
echo ""
echo "Note: You may need to update your hosts file or bookmarks to use port 8090 for Memo API"