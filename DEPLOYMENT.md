# Memo System - Production Deployment Guide

## Prerequisites

### Ubuntu Server Setup
1. **Update system:**
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **Install Docker:**
   ```bash
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   sudo usermod -aG docker $USER
   ```

3. **Install Docker Compose V2:**
   ```bash
   # Docker Compose V2 is included with Docker Desktop
   # For Ubuntu Server, it's included with recent Docker installations
   # Verify installation:
   docker compose version
   ```

4. **Reboot to apply Docker group changes:**
   ```bash
   sudo reboot
   ```

## Deployment Steps

### 1. Transfer Files to Ubuntu Server
```bash
# On your local machine, copy the entire reminder-system folder to your Ubuntu server
scp -r reminder-system/ user@your-ubuntu-server-ip:/home/user/
```

### 2. Configure Production Environment
```bash
# SSH into your Ubuntu server
ssh user@your-ubuntu-server-ip

# Navigate to the project directory
cd /home/user/reminder-system

# Edit production environment file
nano .env.prod

# Update these critical settings:
# - Change all passwords (POSTGRES_PASSWORD, RABBITMQ_PASSWORD, etc.)
# - Update SMTP settings for your email
# - Set JWT_SECRET to a long, random string
```

### 3. Deploy the System
```bash
# Run the deployment script
sudo ./deploy.sh
```

### 4. Configure Network Access

#### On Ubuntu Server:
```bash
# Check the server's IP address
ip addr show

# Optional: Set up firewall rules
sudo ufw allow 80/tcp
sudo ufw allow 3000/tcp
sudo ufw enable
```

#### On Client Machines (Windows/Mac/Linux):
Add the Ubuntu server to your hosts file:

**Linux/Mac:**
```bash
echo "YOUR_UBUNTU_SERVER_IP memo" | sudo tee -a /etc/hosts
```

**Windows:**
1. Open `C:\Windows\System32\drivers\etc\hosts` as Administrator
2. Add line: `YOUR_UBUNTU_SERVER_IP memo`

### 5. Access the System
- **Main Application:** http://memo:3000
- **API:** http://memo
- **API Health Check:** http://memo/health

## Management Commands

```bash
# Start the system
./manage.sh start

# Stop the system
./manage.sh stop

# Restart the system
./manage.sh restart

# View logs
./manage.sh logs

# Check status
./manage.sh status

# Update system (rebuild and restart)
./manage.sh update

# Backup database
./manage.sh backup
```

## Monitoring and Maintenance

### View Logs
```bash
# All services
./manage.sh logs

# Specific service
docker logs memo-reminder-service -f
```

### Database Access
```bash
# Connect to PostgreSQL
docker exec -it memo-postgres psql -U memo_user -d memo_db
```

### System Resources
```bash
# Check Docker container resource usage
docker stats

# Check disk usage
df -h
docker system df
```

### Backup and Restore
```bash
# Create backup
./manage.sh backup

# Restore from backup
docker exec -i memo-postgres psql -U memo_user -d memo_db < memo_backup_YYYYMMDD_HHMMSS.sql
```

## Security Considerations

1. **Change default passwords** in `.env.prod`
2. **Set up SSL/TLS** for production (consider using Caddy or Let's Encrypt)
3. **Configure firewall** to only allow necessary ports
4. **Regular backups** of the database
5. **Monitor logs** for suspicious activity
6. **Keep Docker images updated** regularly

## Troubleshooting

### Services won't start
```bash
# Check service status
./manage.sh status

# Check logs for errors
./manage.sh logs

# Restart specific service
docker compose -f docker-compose.prod.yml restart memo-reminder-service
```

### Can't access via http://memo
1. Verify hosts file entry on client machine
2. Check Ubuntu server firewall: `sudo ufw status`
3. Verify services are running: `./manage.sh status`
4. Test direct IP access: `http://YOUR_SERVER_IP`

### Database issues
```bash
# Reset database (WARNING: This deletes all data)
docker-compose -f docker-compose.prod.yml down -v
docker-compose -f docker-compose.prod.yml up -d
```

## Performance Optimization

### For production use:
1. **Increase container resources** if needed
2. **Set up log rotation** to prevent disk space issues
3. **Monitor memory usage** and adjust if necessary
4. **Consider using external database** for high-load scenarios

## Updates and Maintenance

### Regular maintenance tasks:
```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Clean up Docker
docker system prune -f

# Update application
git pull  # if using git
./manage.sh update
```