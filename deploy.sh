#!/bin/bash

# Memo System Deployment Script for Ubuntu Server

set -e

echo "🚀 Starting Memo System deployment..."

# Check if running as root (needed for port 80)
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run as root (sudo) to bind to port 80"
    exit 1
fi

# Check if Docker and Docker Compose are installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Stop any existing containers
echo "🛑 Stopping existing containers..."
docker-compose -f docker-compose.prod.yml --env-file .env.prod down || true

# Build and start the production system
echo "🔨 Building and starting Memo system..."
docker-compose -f docker-compose.prod.yml --env-file .env.prod up -d --build

# Wait for services to be healthy
echo "⏳ Waiting for services to be ready..."
sleep 30

# Check service health
echo "🔍 Checking service health..."
docker-compose -f docker-compose.prod.yml --env-file .env.prod ps

# Test the API
echo "🧪 Testing API connectivity..."
if curl -f http://localhost/health > /dev/null 2>&1; then
    echo "✅ API Gateway is responding"
else
    echo "❌ API Gateway is not responding"
    exit 1
fi

echo ""
echo "🎉 Memo System deployed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Add 'memo' to your hosts file on client machines:"
echo "   echo 'YOUR_UBUNTU_SERVER_IP memo' >> /etc/hosts"
echo ""
echo "2. Access the system:"
echo "   - Frontend: http://memo:3000"
echo "   - API: http://memo"
echo ""
echo "3. Monitor logs:"
echo "   docker-compose -f docker-compose.prod.yml logs -f"
echo ""
echo "4. Update passwords in .env.prod for production security!"