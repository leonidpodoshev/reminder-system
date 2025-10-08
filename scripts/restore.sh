# ===================================
# scripts/restore.sh
# ===================================
#!/bin/bash
# Restore script for database and volumes

BACKUP_DIR="$1"

if [ -z "$BACKUP_DIR" ]; then
    echo "Usage: $0 <backup_directory>"
    exit 1
fi

if [ ! -d "$BACKUP_DIR" ]; then
    echo "Backup directory not found: $BACKUP_DIR"
    exit 1
fi

echo "Restoring from $BACKUP_DIR..."

# Stop services
docker-compose down

# Restore PostgreSQL
if [ -f "$BACKUP_DIR/postgres.sql" ]; then
    docker-compose up -d postgres
    sleep 10
    docker-compose exec -T postgres psql -U reminder reminder_db < "$BACKUP_DIR/postgres.sql"
fi

# Restore volumes
if [ -f "$BACKUP_DIR/postgres_data.tar.gz" ]; then
    docker run --rm -v reminder-system_postgres_data:/data -v $(pwd)/$BACKUP_DIR:/backup alpine tar xzf /backup/postgres_data.tar.gz -C /data
fi

if [ -f "$BACKUP_DIR/rabbitmq_data.tar.gz" ]; then
    docker run --rm -v reminder-system_rabbitmq_data:/data -v $(pwd)/$BACKUP_DIR:/backup alpine tar xzf /backup/rabbitmq_data.tar.gz -C /data
fi

# Start services
docker-compose up -d

echo "Restore completed"

