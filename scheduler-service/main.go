// main.go - Scheduler Service
package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	amqp "github.com/rabbitmq/amqp091-go"
)

// Reminder structure (matches reminder service)
type Reminder struct {
	ID               string    `json:"id"`
	UserID           string    `json:"user_id"`
	Title            string    `json:"title"`
	Description      string    `json:"description"`
	DateTime         time.Time `json:"datetime"`
	NotificationType string    `json:"notification_type"`
	Email            string    `json:"email,omitempty"`
	Phone            string    `json:"phone,omitempty"`
	Status           string    `json:"status"`
	CreatedAt        time.Time `json:"created_at"`
	UpdatedAt        time.Time `json:"updated_at"`
}

// NotificationMessage for RabbitMQ
type NotificationMessage struct {
	ReminderID       string    `json:"reminder_id"`
	Title            string    `json:"title"`
	Description      string    `json:"description"`
	DateTime         time.Time `json:"datetime"`
	NotificationType string    `json:"notification_type"`
	Email            string    `json:"email,omitempty"`
	Phone            string    `json:"phone,omitempty"`
}

var (
	rabbitConn         *amqp.Connection
	rabbitCh           *amqp.Channel
	reminderServiceURL string
)

func main() {
	// Load configuration
	reminderServiceURL = getEnv("REMINDER_SERVICE_URL", "http://reminder-service:8081")

	// Initialize RabbitMQ
	initRabbitMQ()
	defer rabbitConn.Close()
	defer rabbitCh.Close()

	// Start scheduler
	go runScheduler()

	// Initialize Gin router for health checks
	router := gin.Default()

	router.GET("/health", healthCheck)
	router.POST("/trigger", triggerManualCheck) // Manual trigger for testing

	// Start server
	port := getEnv("PORT", "8083")

	log.Printf("Scheduler Service starting on port %s", port)
	if err := router.Run(":" + port); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}

func initRabbitMQ() {
	rabbitURL := getEnv("RABBITMQ_URL", "amqp://guest:guest@rabbitmq:5672/")

	var err error
	rabbitConn, err = amqp.Dial(rabbitURL)
	if err != nil {
		log.Fatal("Failed to connect to RabbitMQ:", err)
	}

	rabbitCh, err = rabbitConn.Channel()
	if err != nil {
		log.Fatal("Failed to open channel:", err)
	}

	// Declare notifications queue
	_, err = rabbitCh.QueueDeclare(
		"notifications", // queue name
		true,            // durable
		false,           // delete when unused
		false,           // exclusive
		false,           // no-wait
		nil,             // arguments
	)
	if err != nil {
		log.Fatal("Failed to declare queue:", err)
	}

	log.Println("RabbitMQ connected successfully")
}

func runScheduler() {
	// Check for due reminders every minute
	ticker := time.NewTicker(1 * time.Minute)
	defer ticker.Stop()

	log.Println("Scheduler started, checking every minute...")

	// Run immediately on startup
	resetStuckProcessingReminders()
	checkAndProcessReminders()

	for range ticker.C {
		resetStuckProcessingReminders()
		checkAndProcessReminders()
	}
}

func resetStuckProcessingReminders() {
	log.Println("Checking for stuck processing reminders...")

	url := fmt.Sprintf("%s/api/reminders/reset-stuck", reminderServiceURL)

	req, err := http.NewRequest("POST", url, nil)
	if err != nil {
		log.Printf("Error creating reset request: %v", err)
		return
	}

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		log.Printf("Error resetting stuck reminders: %v", err)
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		log.Printf("Unexpected status code when resetting stuck reminders: %d", resp.StatusCode)
	}
}

func checkAndProcessReminders() {
	log.Println("Checking for due reminders...")

	reminders, err := fetchPendingReminders()
	if err != nil {
		log.Printf("Error fetching pending reminders: %v", err)
		return
	}

	if len(reminders) == 0 {
		log.Println("No pending reminders found")
		return
	}

	log.Printf("Found %d pending reminder(s)", len(reminders))

	for _, reminder := range reminders {
		// Check if reminder is due
		now := time.Now()
		if reminder.DateTime.Before(now) || reminder.DateTime.Equal(now) {
			log.Printf("Processing reminder: %s - %s", reminder.ID, reminder.Title)

			// First, update status to "processing" to prevent duplicate processing
			if err := updateReminderStatus(reminder.ID, "processing"); err != nil {
				log.Printf("Error updating reminder status to processing for %s: %v", reminder.ID, err)
				continue
			}

			// Send notification
			if err := sendNotification(reminder); err != nil {
				log.Printf("Error sending notification for reminder %s: %v", reminder.ID, err)
				// Update status to failed
				updateReminderStatus(reminder.ID, "failed")
			} else {
				log.Printf("Notification sent for reminder: %s", reminder.ID)
				// Update status to sent
				updateReminderStatus(reminder.ID, "sent")
			}
		}
	}
}

func fetchPendingReminders() ([]Reminder, error) {
	url := fmt.Sprintf("%s/api/reminders/pending", reminderServiceURL)

	resp, err := http.Get(url)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch reminders: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("unexpected status code: %d", resp.StatusCode)
	}

	var reminders []Reminder
	if err := json.NewDecoder(resp.Body).Decode(&reminders); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	return reminders, nil
}

func sendNotification(reminder Reminder) error {
	message := NotificationMessage{
		ReminderID:       reminder.ID,
		Title:            reminder.Title,
		Description:      reminder.Description,
		DateTime:         reminder.DateTime,
		NotificationType: reminder.NotificationType,
		Email:            reminder.Email,
		Phone:            reminder.Phone,
	}

	body, err := json.Marshal(message)
	if err != nil {
		return fmt.Errorf("failed to marshal message: %w", err)
	}

	err = rabbitCh.Publish(
		"",              // exchange
		"notifications", // routing key (queue name)
		false,           // mandatory
		false,           // immediate
		amqp.Publishing{
			DeliveryMode: amqp.Persistent,
			ContentType:  "application/json",
			Body:         body,
		},
	)

	if err != nil {
		return fmt.Errorf("failed to publish message: %w", err)
	}

	return nil
}

func updateReminderStatus(reminderID, status string) error {
	url := fmt.Sprintf("%s/api/reminders/%s", reminderServiceURL, reminderID)

	payload := map[string]string{"status": status}
	jsonData, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal payload: %w", err)
	}

	req, err := http.NewRequest("PUT", url, bytes.NewBuffer(jsonData))
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("unexpected status code: %d", resp.StatusCode)
	}

	return nil
}

func healthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":  "healthy",
		"service": "scheduler-service",
		"time":    time.Now(),
	})
}

func triggerManualCheck(c *gin.Context) {
	go checkAndProcessReminders()
	c.JSON(http.StatusOK, gin.H{"message": "Manual check triggered"})
}

func getEnv(key, defaultValue string) string {
	value := os.Getenv(key)
	if value == "" {
		return defaultValue
	}
	return value
}
