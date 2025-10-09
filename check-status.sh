#!/bin/bash

echo "🔍 Checking system status..."
echo ""

echo "📊 Docker Compose Status:"
docker compose -f docker-compose.prod.yml --env-file .env.prod ps
echo ""

echo "🐳 All Docker Containers:"
docker ps -a | grep memo
echo ""

echo "📋 Recent Logs from All Services:"
docker compose -f docker-compose.prod.yml --env-file .env.prod logs --tail=10
echo ""

echo "🔗 Docker Networks:"
docker network ls | grep memo
echo ""

echo "💾 Docker Volumes:"
docker volume ls | grep reminder-system
echo ""

echo "🌐 Port Usage:"
netstat -tlnp | grep -E ':(80|8080|8081|8082|8083|5432)' || echo "No ports in use"