# ===================================
# scripts/health-check.sh
# ===================================
#!/bin/bash
# Health check script for services

SERVICE_URL="${1:-http://localhost:8080}"

response=$(curl -s -o /dev/null -w "%{http_code}" "$SERVICE_URL/health")

if [ "$response" = "200" ]; then
    echo "Service is healthy"
    exit 0
else
    echo "Service is unhealthy (HTTP $response)"
    exit 1
fi

