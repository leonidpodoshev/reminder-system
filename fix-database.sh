#!/bin/bash

# Fix database user issue on Ubuntu server

echo "🔧 Fixing database user issue..."

# Stop the services
echo "🛑 Stopping services..."
docker compose -f docker-compose.prod.yml --env-file .env.prod down

# Remove the postgres volume to start fresh
echo "🗑️ Removing old database volume..."
docker volume rm reminder-system_postgres_data 2>/dev/null || echo "Volume doesn't exist, continuing..."

# Start only the database first
echo "🚀 Starting database..."
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d postgres

# Wait for database to be ready
echo "⏳ Waiting for database to initialize..."
sleep 15

# Check if database is ready
echo "🔍 Checking database status..."
docker exec memo-postgres pg_isready -U reminder -d reminder_db

if [ $? -eq 0 ]; then
    echo "✅ Database is ready!"
else
    echo "❌ Database is not ready. Let's create the user manually..."
    
    # Create the user and database manually
    docker exec memo-postgres psql -U postgres -c "CREATE USER reminder WITH PASSWORD 'reminder';"
    docker exec memo-postgres psql -U postgres -c "CREATE DATABASE reminder_db OWNER reminder;"
    docker exec memo-postgres psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE reminder_db TO reminder;"
    
    echo "✅ User and database created manually"
fi

# Now start all services
echo "🚀 Starting all services..."
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d

# Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 30

# Check status
echo "📊 Final status:"
docker compose -f docker-compose.prod.yml --env-file .env.prod ps

echo ""
echo "🎉 Database fix complete!"
echo "Test the API: curl http://localhost:8080/health"