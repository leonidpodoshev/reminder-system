#!/bin/bash

echo "🔧 Attempting to fix docbox system..."

echo "1️⃣ Ensuring Memo system is using correct ports only..."
docker compose -f docker-compose.prod.yml --env-file .env.prod ps

echo ""
echo "2️⃣ Restarting system nginx (if it exists)..."
sudo systemctl restart nginx 2>/dev/null && echo "✅ System nginx restarted" || echo "ℹ️ No system nginx found"

echo ""
echo "3️⃣ Checking for docbox containers..."
DOCBOX_CONTAINERS=$(docker ps -a | grep -i docbox | awk '{print $1}')
if [ ! -z "$DOCBOX_CONTAINERS" ]; then
    echo "Found docbox containers, restarting them..."
    echo "$DOCBOX_CONTAINERS" | xargs docker restart
    echo "✅ Docbox containers restarted"
else
    echo "ℹ️ No docbox containers found"
fi

echo ""
echo "4️⃣ Looking for docbox docker-compose files..."
find /home -name "*docker-compose*" -type f 2>/dev/null | grep -i docbox || echo "No docbox compose files found in /home"

echo ""
echo "5️⃣ Checking if docbox is a systemd service..."
sudo systemctl status docbox 2>/dev/null || echo "No docbox systemd service found"

echo ""
echo "6️⃣ Testing connectivity after fixes..."
sleep 5
curl -I http://192.168.87.100/ 2>/dev/null && echo "✅ HTTP working" || echo "❌ HTTP still not working"
curl -I https://192.168.87.100/ 2>/dev/null && echo "✅ HTTPS working" || echo "❌ HTTPS still not working"

echo ""
echo "🎯 Next steps:"
echo "1. Run the diagnostic script to see current status"
echo "2. If docbox is still not working, we may need to:"
echo "   - Find the docbox installation directory"
echo "   - Restart its specific services"
echo "   - Check its nginx/proxy configuration"