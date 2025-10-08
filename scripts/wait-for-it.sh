# ===================================
# scripts/wait-for-it.sh
# ===================================
#!/bin/bash
# Wait for service to be ready script

set -e

host="$1"
shift
cmd="$@"

until nc -z "$host" 2>/dev/null; do
  >&2 echo "Service $host is unavailable - sleeping"
  sleep 1
done

>&2 echo "Service $host is up - executing command"
exec $cmd

