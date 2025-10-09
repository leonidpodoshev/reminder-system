#!/bin/bash

echo "🔍 Checking for port conflicts between Memo and docbox..."

echo "1️⃣ What's using port 80 (should be system nginx for docbox):"
sudo lsof -i :80

echo ""
echo "2️⃣ What's using port 443 (should be system nginx for HTTPS):"
sudo lsof -i :443

echo ""
echo "3️⃣ Our Memo system ports (should be 8080 and 3001):"
echo "Port 8080 (Memo API):"
sudo lsof -i :8080
echo ""
echo "Port 3001 (Memo Frontend):"
sudo lsof -i :3001

echo ""
echo "4️⃣ Docker containers and their ports:"
docker ps --format "table {{.Names}}\t{{.Ports}}"

echo ""
echo "5️⃣ System nginx processes:"
ps aux | grep nginx | grep -v grep

echo ""
echo "6️⃣ If there's a conflict, we need to:"
echo "   - Stop any Docker containers using port 80/443"
echo "   - Ensure system nginx can bind to port 80/443"
echo "   - Restart system nginx"