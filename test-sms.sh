#!/bin/bash

# Test SMS notification directly
curl -X POST "http://localhost:8080/api/reminders" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "SMS Test Reminder",
    "description": "Testing SMS notifications via Twilio",
    "datetime": "'$(date -u -d '+1 minute' +%Y-%m-%dT%H:%M:%SZ)'",
    "notification_type": "sms",
    "phone": "+1234567890"
  }'

echo "SMS test reminder created!"