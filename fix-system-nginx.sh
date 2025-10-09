#!/bin/bash

echo "🔧 Fixing system nginx for docbox..."

echo "1️⃣ Checking system nginx status:"
sudo systemctl status nginx

echo ""
echo "2️⃣ Testing nginx configuration:"
sudo nginx -t

echo ""
echo "3️⃣ Checking what's using port 80:"
sudo netstat -tlnp | grep :80

echo ""
echo "4️⃣ Checking nginx error logs:"
sudo tail -20 /var/log/nginx/error.log

echo ""
echo "5️⃣ Restarting system nginx:"
sudo systemctl restart nginx

echo ""
echo "6️⃣ Checking nginx status after restart:"
sudo systemctl status nginx

echo ""
echo "7️⃣ Testing docbox connectivity:"
sleep 3
curl -I http://192.168.87.100/ 2>/dev/null && echo "✅ HTTP working" || echo "❌ HTTP still not working"
curl -I https://192.168.87.100/ 2>/dev/null && echo "✅ HTTPS working" || echo "❌ HTTPS still not working"

echo ""
echo "8️⃣ If still not working, checking nginx sites:"
echo "Available sites:"
ls -la /etc/nginx/sites-available/ | grep docbox || echo "No docbox site found"
echo ""
echo "Enabled sites:"
ls -la /etc/nginx/sites-enabled/ | grep docbox || echo "No docbox site enabled"

echo ""
echo "9️⃣ Checking if nginx is listening on correct ports:"
sudo ss -tlnp | grep nginx