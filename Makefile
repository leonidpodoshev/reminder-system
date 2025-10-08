# ===================================
# Makefile
# ===================================
# Project Makefile for common tasks

.PHONY: help build up down restart logs clean test

# Default target
help:
	@echo "Available commands:"
	@echo "  make build       - Build all Docker images"
	@echo "  make up          - Start all services"
	@echo "  make down        - Stop all services"
	@echo "  make restart     - Restart all services"
	@echo "  make logs        - View logs (all services)"
	@echo "  make logs-f      - Follow logs (all services)"
	@echo "  make clean       - Remove all containers and volumes"
	@echo "  make test        - Run tests"
	@echo "  make monitoring  - Start with monitoring stack"
	@echo "  make tools       - Start with development tools"

# Build all services
build:
	docker-compose build

# Start all services
up:
	docker-compose up -d

# Start with monitoring
monitoring:
	docker-compose --profile monitoring up -d

# Start with tools
tools:
	docker-compose --profile tools up -d

# Start everything
all:
	docker-compose --profile monitoring --profile logging --profile tools up -d

# Stop all services
down:
	docker-compose down

# Restart all services
restart:
	docker-compose restart

# View logs
logs:
	docker-compose logs

# Follow logs
logs-f:
	docker-compose logs -f

# View specific service logs
logs-%:
	docker-compose logs -f $*

# Clean everything (CAUTION: This removes volumes!)
clean:
	docker-compose down -v
	docker system prune -f

# Run tests
test:
	@echo "Running Go tests..."
	@cd reminder-service && go test ./...
	@cd notification-service && go test ./...
	@cd scheduler-service && go test ./...
	@cd user-service && go test ./...
	@echo "Running frontend tests..."
	@cd frontend && npm test -- --passWithNoTests

# Database migration
migrate-up:
	@echo "Running database migrations..."
	docker-compose exec reminder-service /app/migrate up

migrate-down:
	@echo "Rolling back database migrations..."
	docker-compose exec reminder-service /app/migrate down

# Database backup
db-backup:
	@echo "Creating database backup..."
	docker-compose exec postgres pg_dump -U reminder reminder_db > backup_$(shell date +%Y%m%d_%H%M%S).sql

# Database restore
db-restore:
	@echo "Restoring database from backup..."
	@read -p "Enter backup file name: " file; \
	docker-compose exec -T postgres psql -U reminder reminder_db < $file

# Check service health
health:
	@echo "Checking service health..."
	@curl -s http://localhost:8084/health | jq . || echo "User Service: DOWN"
	@curl -s http://localhost:8081/health | jq . || echo "Reminder Service: DOWN"
	@curl -s http://localhost:8082/health | jq . || echo "Notification Service: DOWN"
	@curl -s http://localhost:8083/health | jq . || echo "Scheduler Service: DOWN"

# Development setup
dev-setup:
	@echo "Setting up development environment..."
	cp .env.example .env
	@echo "Please edit .env file with your configuration"
	mkdir -p api-gateway/conf.d api-gateway/ssl
	mkdir -p config/rabbitmq
	mkdir -p monitoring/prometheus monitoring/grafana/provisioning/datasources monitoring/grafana/dashboards
	mkdir -p scripts

# Install Go dependencies
go-deps:
	@echo "Installing Go dependencies..."
	cd reminder-service && go mod download
	cd notification-service && go mod download
	cd scheduler-service && go mod download
	cd user-service && go mod download

# Install frontend dependencies
frontend-deps:
	@echo "Installing frontend dependencies..."
	cd frontend && npm install

# Format code
format:
	@echo "Formatting Go code..."
	cd reminder-service && go fmt ./...
	cd notification-service && go fmt ./...
	cd scheduler-service && go fmt ./...
	cd user-service && go fmt ./...
	@echo "Formatting frontend code..."
	cd frontend && npm run format

# Lint code
lint:
	@echo "Linting Go code..."
	cd reminder-service && golangci-lint run
	cd notification-service && golangci-lint run
	cd scheduler-service && golangci-lint run
	cd user-service && golangci-lint run
	@echo "Linting frontend code..."
	cd frontend && npm run lint

# Generate API documentation
docs:
	@echo "Generating API documentation..."
	docker run --rm -v ${PWD}:/spec redocly/openapi-cli bundle api/openapi.yaml -o docs/api.html

