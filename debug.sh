#!/bin/bash

# Debug script for Ubuntu server deployment issues

echo "🔍 Debugging Memo System deployment..."
echo ""

echo "📊 Container Status:"
docker compose -f docker-compose.prod.yml --env-file .env.prod ps
echo ""

echo "📋 Reminder Service Logs:"
docker compose -f docker-compose.prod.yml --env-file .env.prod logs reminder-service
echo ""

echo "📋 Database Logs:"
docker compose -f docker-compose.prod.yml --env-file .env.prod logs postgres
echo ""

echo "🔗 Network Connectivity Test:"
echo "Testing if reminder service can reach database..."
docker exec memo-reminder-service ping -c 2 memo-postgres 2>/dev/null || echo "❌ Cannot reach database"
echo ""

echo "💾 Database Status:"
docker exec memo-postgres pg_isready -U reminder -d reminder_db 2>/dev/null || echo "❌ Database not ready"
echo ""

echo "🌐 Port Check:"
echo "Checking if ports are available..."
netstat -tlnp | grep -E ':(80|8080|8081|8082|8083|5432)' || echo "No conflicting ports found"