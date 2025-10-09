#!/bin/bash

echo "🚀 Starting services step by step..."

# Start infrastructure services first
echo "1️⃣ Starting infrastructure (postgres, redis, rabbitmq)..."
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d postgres redis rabbitmq

echo "⏳ Waiting 20 seconds for infrastructure..."
sleep 20

echo "📊 Infrastructure status:"
docker compose -f docker-compose.prod.yml --env-file .env.prod ps postgres redis rabbitmq
echo ""

# Start application services
echo "2️⃣ Starting application services..."
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d user-service

echo "⏳ Waiting 10 seconds..."
sleep 10

docker compose -f docker-compose.prod.yml --env-file .env.prod up -d reminder-service

echo "⏳ Waiting 10 seconds..."
sleep 10

echo "📊 Application services status:"
docker compose -f docker-compose.prod.yml --env-file .env.prod ps user-service reminder-service
echo ""

# Start remaining services
echo "3️⃣ Starting remaining services..."
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d

echo "⏳ Final wait..."
sleep 15

echo "📊 Final status:"
docker compose -f docker-compose.prod.yml --env-file .env.prod ps

echo ""
echo "🧪 Testing API:"
curl -f http://localhost:8080/health || echo "❌ API not responding"