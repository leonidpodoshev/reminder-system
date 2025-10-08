# From reminder-system/ directory

# Fix all go.mod files at once
for service in reminder-service notification-service scheduler-service user-service; do
    if [ -f "$service/go.mod" ]; then
        echo "Fixing $service/go.mod..."
        # Use a more specific sed pattern
        sed -i '' 's/^go 1\.24\.5/go 1.21/' $service/go.mod
        # Show the result
        echo "New version:"
        head -3 $service/go.mod
        echo ""
    fi
done