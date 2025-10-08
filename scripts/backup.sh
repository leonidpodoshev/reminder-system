# ===================================
# scripts/backup.sh
# ===================================
#!/bin/bash
# Backup script for database and volumes

BACKUP_DIR="./backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "Creating backup in $BACKUP_DIR..."

# Backup PostgreSQL
docker-compose exec -T postgres pg_dump -U reminder reminder_db > "$BACKUP_DIR/postgres.sql"

# Backup RabbitMQ definitions
docker-compose exec -T rabbitmq rabbitmqctl export_definitions /tmp/definitions.json
docker cp reminder-rabbitmq:/tmp/definitions.json "$BACKUP_DIR/rabbitmq-definitions.json"

# Backup volumes
docker run --rm -v reminder-system_postgres_data:/data -v $(pwd)/$BACKUP_DIR:/backup alpine tar czf /backup/postgres_data.tar.gz -C /data .
docker run --rm -v reminder-system_rabbitmq_data:/data -v $(pwd)/$BACKUP_DIR:/backup alpine tar czf /backup/rabbitmq_data.tar.gz -C /data .

echo "Backup completed: $BACKUP_DIR"

