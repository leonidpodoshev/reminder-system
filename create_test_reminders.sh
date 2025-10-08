# Create 3 reminders at different times
for i in 1 2 3; do
  TIME=$(date -u -v+${i}M +"%Y-%m-%dT%H:%M:%SZ")
  curl -X POST http://localhost:8080/api/reminders \
    -H "Content-Type: application/json" \
    -H "X-User-ID: test-user" \
    -d "{
      \"title\": \"Test Reminder $i\",
      \"description\": \"This is test number $i\",
      \"datetime\": \"$TIME\",
      \"notification_type\": \"email\",
      \"email\": \"your-email@gmail.com\"
    }"
  echo "Created reminder $i for $TIME"
done

echo ""
echo "✅ Created 3 reminders (1, 2, and 3 minutes from now)"
echo "📧 Watch your inbox!"