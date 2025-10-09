#!/bin/bash

echo "🔍 Diagnosing docbox system issues..."

echo "1️⃣ Checking port usage:"
echo "Port 80 (HTTP):"
sudo netstat -tlnp | grep :80 || echo "Port 80 not in use"
echo ""
echo "Port 443 (HTTPS):"
sudo netstat -tlnp | grep :443 || echo "Port 443 not in use"
echo ""

echo "2️⃣ Checking nginx processes:"
ps aux | grep nginx | grep -v grep || echo "No nginx processes found"
echo ""

echo "3️⃣ Checking Docker containers using port 80/443:"
docker ps --format "table {{.Names}}\t{{.Ports}}" | grep -E "(80|443)" || echo "No Docker containers using port 80/443"
echo ""

echo "4️⃣ Checking if docbox containers are running:"
docker ps | grep -i docbox || echo "No docbox containers found"
echo ""

echo "5️⃣ Checking system nginx status:"
sudo systemctl status nginx || echo "System nginx not running"
echo ""

echo "6️⃣ Testing docbox connectivity:"
curl -I http://192.168.87.100/ 2>/dev/null || echo "Cannot connect to port 80"
curl -I https://192.168.87.100/ 2>/dev/null || echo "Cannot connect to port 443"
echo ""

echo "7️⃣ Checking our Memo system ports:"
echo "Memo API Gateway (should be 8080):"
docker ps | grep memo-api-gateway
echo ""
echo "Memo Frontend (should be 3001):"
docker ps | grep memo-frontend