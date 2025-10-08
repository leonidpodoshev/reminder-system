#!/bin/bash

# Memo System Management Script

COMPOSE_FILE="docker-compose.prod.yml"
ENV_FILE=".env.prod"

case "$1" in
    start)
        echo "🚀 Starting Memo system..."
        docker-compose -f $COMPOSE_FILE --env-file $ENV_FILE up -d
        ;;
    stop)
        echo "🛑 Stopping Memo system..."
        docker-compose -f $COMPOSE_FILE --env-file $ENV_FILE down
        ;;
    restart)
        echo "🔄 Restarting Memo system..."
        docker-compose -f $COMPOSE_FILE --env-file $ENV_FILE restart
        ;;
    logs)
        echo "📋 Showing logs..."
        docker-compose -f $COMPOSE_FILE --env-file $ENV_FILE logs -f
        ;;
    status)
        echo "📊 System status:"
        docker-compose -f $COMPOSE_FILE --env-file $ENV_FILE ps
        ;;
    update)
        echo "🔄 Updating Memo system..."
        docker-compose -f $COMPOSE_FILE --env-file $ENV_FILE down
        docker-compose -f $COMPOSE_FILE --env-file $ENV_FILE up -d --build
        ;;
    backup)
        echo "💾 Creating database backup..."
        docker exec memo-postgres pg_dump -U memo_user memo_db > "memo_backup_$(date +%Y%m%d_%H%M%S).sql"
        echo "✅ Backup created: memo_backup_$(date +%Y%m%d_%H%M%S).sql"
        ;;
    *)
        echo "Memo System Management"
        echo ""
        echo "Usage: $0 {start|stop|restart|logs|status|update|backup}"
        echo ""
        echo "Commands:"
        echo "  start   - Start all services"
        echo "  stop    - Stop all services"
        echo "  restart - Restart all services"
        echo "  logs    - Show live logs"
        echo "  status  - Show service status"
        echo "  update  - Update and rebuild services"
        echo "  backup  - Create database backup"
        exit 1
        ;;
esac