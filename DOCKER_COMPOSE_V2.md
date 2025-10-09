# Docker Compose V2 Reference

## Command Syntax Changes

**Old V1 (deprecated):**
```bash
docker-compose up -d
docker-compose down
docker-compose logs -f
```

**New V2 (recommended):**
```bash
docker compose up -d
docker compose down  
docker compose logs -f
```

## Key Differences

1. **Command**: `docker compose` (space) instead of `docker-compose` (hyphen)
2. **Performance**: V2 is faster and more efficient
3. **Integration**: V2 is built into Docker CLI as a plugin
4. **Features**: Better error messages and new features

## Memo System Commands (V2)

### Development
```bash
# Start development environment
docker compose up -d

# Stop development environment  
docker compose down

# View logs
docker compose logs -f

# Restart specific service
docker compose restart reminder-service
```

### Production
```bash
# Start production environment
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d

# Stop production environment
docker compose -f docker-compose.prod.yml --env-file .env.prod down

# View production logs
docker compose -f docker-compose.prod.yml --env-file .env.prod logs -f

# Check status
docker compose -f docker-compose.prod.yml --env-file .env.prod ps
```

### Management Scripts (Already Updated)
```bash
# Use the management script (already uses V2)
./manage.sh start
./manage.sh stop
./manage.sh logs
./manage.sh status
```

## Verification

Check that you're using V2:
```bash
docker compose version
# Should show: Docker Compose version v2.x.x
```

## Migration Notes

- Both MacBook and Ubuntu server should use the same V2 syntax
- All scripts have been updated to use V2 commands
- V1 compatibility aliases may still work but V2 is recommended
- No functional changes to your containers or data