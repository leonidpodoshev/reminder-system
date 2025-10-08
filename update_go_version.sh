# From reminder-system/ directory

# Update all Go service Dockerfiles to use Go 1.23
for service in reminder-service notification-service scheduler-service user-service; do
    sed -i '' 's/golang:1.21-alpine/golang:1.23-alpine/g' $service/Dockerfile
done

# Verify the change
grep "FROM golang" */Dockerfile