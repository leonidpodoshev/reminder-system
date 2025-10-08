#!/bin/bash
# create-dockerfiles.sh
# Run this from the project root: reminder-system/

echo "🚀 Creating missing Dockerfiles for Go services..."

# Check we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Error: docker-compose.yml not found!"
    echo "Please run this script from the project root (reminder-system/)"
    exit 1
fi

# Create Dockerfile for reminder-service
echo "📄 Creating reminder-service/Dockerfile..."
cat > reminder-service/Dockerfile << 'EOF'
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Install git for go mod download
RUN apk add --no-cache git

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# Final stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copy binary from builder
COPY --from=builder /app/main .

EXPOSE 8081

CMD ["./main"]
EOF

# Create Dockerfile for notification-service
echo "📄 Creating notification-service/Dockerfile..."
cat > notification-service/Dockerfile << 'EOF'
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Install git for go mod download
RUN apk add --no-cache git

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# Final stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copy binary from builder
COPY --from=builder /app/main .

EXPOSE 8082

CMD ["./main"]
EOF

# Create Dockerfile for scheduler-service
echo "📄 Creating scheduler-service/Dockerfile..."
cat > scheduler-service/Dockerfile << 'EOF'
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Install git for go mod download
RUN apk add --no-cache git

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# Final stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copy binary from builder
COPY --from=builder /app/main .

EXPOSE 8083

CMD ["./main"]
EOF

# Create Dockerfile for user-service
echo "📄 Creating user-service/Dockerfile..."
cat > user-service/Dockerfile << 'EOF'
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Install git for go mod download
RUN apk add --no-cache git

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# Final stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copy binary from builder
COPY --from=builder /app/main .

EXPOSE 8084

CMD ["./main"]
EOF

echo ""
echo "✅ All Dockerfiles created successfully!"
echo ""
echo "Created files:"
echo "  - reminder-service/Dockerfile"
echo "  - notification-service/Dockerfile"
echo "  - scheduler-service/Dockerfile"
echo "  - user-service/Dockerfile"
echo ""
echo "Next steps:"
echo "1. Create .env file: cp .env.example .env"
echo "2. Edit .env with your settings (optional)"
echo "3. Build and start: docker-compose up -d"
echo ""