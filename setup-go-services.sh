#!/bin/bash
# setup-go-services.sh
# Run this from the project root: reminder-system/

set -e  # Exit on error

echo "🚀 Setting up Go services..."

# Check we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Error: docker-compose.yml not found!"
    echo "Please run this script from the project root (reminder-system/)"
    exit 1
fi

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo "❌ Go is not installed!"
    echo "Install Go from: https://go.dev/dl/"
    echo ""
    echo "Alternatively, you can skip this and let Docker handle it."
    echo "Just make sure main.go files exist in each service directory."
    exit 1
fi

echo "✅ Go version: $(go version)"
echo ""

# Setup Reminder Service
echo "📦 Setting up reminder-service..."
cd reminder-service

if [ ! -f "go.mod" ]; then
    echo "  Creating go.mod..."
    go mod init reminder-service
    go get github.com/gin-gonic/gin@v1.9.1
    go get gorm.io/gorm@v1.25.5
    go get gorm.io/driver/postgres@v1.5.4
    go get github.com/google/uuid@v1.4.0
    go get github.com/rabbitmq/amqp091-go@v1.9.0
fi

if [ ! -f "main.go" ]; then
    echo "  ⚠️  Warning: main.go not found in reminder-service!"
    echo "  Please copy the Reminder Service code from the artifacts."
fi

cd ..

# Setup Notification Service
echo "📦 Setting up notification-service..."
cd notification-service

if [ ! -f "go.mod" ]; then
    echo "  Creating go.mod..."
    go mod init notification-service
    go get github.com/gin-gonic/gin@v1.9.1
    go get github.com/rabbitmq/amqp091-go@v1.9.0
fi

if [ ! -f "main.go" ]; then
    echo "  ⚠️  Warning: main.go not found in notification-service!"
    echo "  Please copy the Notification Service code from the artifacts."
fi

cd ..

# Setup Scheduler Service
echo "📦 Setting up scheduler-service..."
cd scheduler-service

if [ ! -f "go.mod" ]; then
    echo "  Creating go.mod..."
    go mod init scheduler-service
    go get github.com/gin-gonic/gin@v1.9.1
    go get github.com/rabbitmq/amqp091-go@v1.9.0
fi

if [ ! -f "main.go" ]; then
    echo "  ⚠️  Warning: main.go not found in scheduler-service!"
    echo "  Please copy the Scheduler Service code from the artifacts."
fi

cd ..

# Setup User Service
echo "📦 Setting up user-service..."
cd user-service

if [ ! -f "go.mod" ]; then
    echo "  Creating go.mod..."
    go mod init user-service
    go get github.com/gin-gonic/gin@v1.9.1
    go get gorm.io/gorm@v1.25.5
    go get gorm.io/driver/postgres@v1.5.4
    go get github.com/golang-jwt/jwt/v5@v5.1.0
    go get golang.org/x/crypto@v0.16.0
fi

if [ ! -f "main.go" ]; then
    echo "  ⚠️  Warning: main.go not found in user-service!"
    echo "  You'll need to create this service or disable it in docker-compose.yml"
fi

cd ..

echo ""
echo "✅ Go modules initialized!"
echo ""
echo "📋 Next steps:"
echo ""
echo "1. Copy the Go service code (main.go) to each service directory:"
echo "   - reminder-service/main.go"
echo "   - notification-service/main.go"
echo "   - scheduler-service/main.go"
echo "   - user-service/main.go (optional)"
echo ""
echo "2. Verify all files exist:"
echo "   ls -la */main.go"
echo "   ls -la */go.mod"
echo ""
echo "3. Create .env file:"
echo "   cp .env.example .env"
echo ""
echo "4. Start services:"
echo "   docker-compose up -d"
echo ""