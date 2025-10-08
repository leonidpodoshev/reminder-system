# ===================================
# README-DOCKER.md
# ===================================
# Docker Compose Usage Guide

## Quick Start

### 1. Initial Setup
```bash
# Copy environment template
cp .env.example .env

# Edit .env with your configuration
nano .env

# Create necessary directories
make dev-setup
```

### 2. Start Services

**Basic services (default):**
```bash
docker-compose up -d
```

**With monitoring (Prometheus + Grafana):**
```bash
docker-compose --profile monitoring up -d
```

**With logging (ELK Stack):**
```bash
docker-compose --profile logging up -d
```

**With development tools (pgAdmin):**
```bash
docker-compose --profile tools up -d
```

**Everything:**
```bash
make all
```

### 3. Access Services

| Service | URL | Credentials |
|---------|-----|-------------|
| Frontend | http://localhost:3000 | - |
| API Gateway | http://localhost:8080 | - |
| RabbitMQ Management | http://localhost:15672 | guest/guest |
| Prometheus | http://localhost:9090 | - |
| Grafana | http://localhost:3001 | admin/admin |
| pgAdmin | http://localhost:5050 | admin@reminder.local/admin |
| Kibana | http://localhost:5601 | - |

## Common Commands

### Service Management
```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# Restart a specific service
docker-compose restart reminder-service

# View logs
docker-compose logs -f reminder-service

# Scale a service
docker-compose up -d --scale reminder-service=3
```

### Development
```bash
# Rebuild a service
docker-compose build reminder-service

# Rebuild without cache
docker-compose build --no-cache reminder-service

# Execute command in running container
docker-compose exec reminder-service sh

# Run one-off command
docker-compose run --rm reminder-service go test
```

### Database Operations
```bash
# Access PostgreSQL
docker-compose exec postgres psql -U reminder reminder_db

# Backup database
make db-backup

# Restore database
make db-restore

# View database logs
docker-compose logs postgres
```

### Monitoring
```bash
# Check service health
make health

# View resource usage
docker stats

# Inspect a container
docker inspect reminder-service
```

## Profiles Explained

### monitoring
Includes:
- Prometheus (metrics collection)
- Grafana (visualization)

### logging
Includes:
- Elasticsearch (log storage)
- Kibana (log visualization)

### tools
Includes:
- pgAdmin (database management)

## Troubleshooting

### Services won't start
```bash
# Check logs
docker-compose logs

# Check specific service
docker-compose logs reminder-service

# Verify configuration
docker-compose config
```

### Port conflicts
```bash
# Change ports in .env file
nano .env

# Or use docker-compose.override.yml
```

### Database connection issues
```bash
# Verify database is running
docker-compose ps postgres

# Check database logs
docker-compose logs postgres

# Test connection
docker-compose exec postgres psql -U reminder -d reminder_db -c "SELECT 1"
```

### Clear everything and start fresh
```bash
# WARNING: This removes all data!
make clean
docker-compose up -d
```

## Performance Tuning

### Resource Limits
Add to service definition:
```yaml
deploy:
  resources:
    limits:
      cpus: '0.5'
      memory: 512M
    reservations:
      cpus: '0.25'
      memory: 256M
```

### Scaling
```bash
# Scale reminder service to 3 instances
docker-compose up -d --scale reminder-service=3

# Load balance with nginx
```
