#!/bin/bash

echo "🔍 Checking frontend status..."
echo ""

echo "📊 Frontend container status:"
docker compose -f docker-compose.prod.yml --env-file .env.prod ps frontend
echo ""

echo "📋 Frontend logs:"
docker compose -f docker-compose.prod.yml --env-file .env.prod logs frontend
echo ""

echo "🐳 All containers:"
docker ps -a | grep memo-frontend
echo ""

echo "🌐 Port check:"
netstat -tlnp | grep :3001 || echo "Port 3001 not in use"
echo ""

echo "🔧 Attempting to restart frontend..."
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d frontend

echo "⏳ Waiting 10 seconds..."
sleep 10

echo "📊 Frontend status after restart:"
docker compose -f docker-compose.prod.yml --env-file .env.prod ps frontend