// main.go - Notification Service
package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"html/template"
	"log"
	"net/http"
	"net/smtp"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	amqp "github.com/rabbitmq/amqp091-go"
)

// NotificationRequest from RabbitMQ or HTTP
type NotificationRequest struct {
	ReminderID       string    `json:"reminder_id"`
	Title            string    `json:"title"`
	Description      string    `json:"description"`
	DateTime         time.Time `json:"datetime"`
	NotificationType string    `json:"notification_type"` // email or sms
	Email            string    `json:"email,omitempty"`
	Phone            string    `json:"phone,omitempty"`
}

// Email configuration
type EmailConfig struct {
	Host     string
	Port     string
	Username string
	Password string
	From     string
}

// SMS configuration (Twilio)
type SMSConfig struct {
	AccountSID string
	AuthToken  string
	FromPhone  string
	TwilioURL  string
}

var (
	emailConfig EmailConfig
	smsConfig   SMSConfig
	rabbitConn  *amqp.Connection
	rabbitCh    *amqp.Channel
)

func main() {
	// Load configurations
	loadConfigs()

	// Initialize RabbitMQ
	initRabbitMQ()
	defer rabbitConn.Close()
	defer rabbitCh.Close()

	// Start consuming from queue
	go consumeNotifications()

	// Initialize Gin router
	router := gin.Default()

	// Health check
	router.GET("/health", healthCheck)

	// Manual notification endpoints (for testing)
	api := router.Group("/api/notifications")
	{
		api.POST("/email", sendEmailHandler)
		api.POST("/sms", sendSMSHandler)
	}

	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = "8082"
	}

	log.Printf("Notification Service starting on port %s", port)
	if err := router.Run(":" + port); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}

func loadConfigs() {
	// Email config (SMTP for your home mail server)
	emailConfig = EmailConfig{
		Host:     getEnv("SMTP_HOST", "localhost"),
		Port:     getEnv("SMTP_PORT", "587"),
		Username: getEnv("SMTP_USERNAME", ""),
		Password: getEnv("SMTP_PASSWORD", ""),
		From:     getEnv("SMTP_FROM", "noreply@reminder.local"),
	}

	// SMS config (Twilio)
	smsConfig = SMSConfig{
		AccountSID: getEnv("TWILIO_ACCOUNT_SID", ""),
		AuthToken:  getEnv("TWILIO_AUTH_TOKEN", ""),
		FromPhone:  getEnv("TWILIO_FROM_PHONE", ""),
		TwilioURL:  "https://api.twilio.com/2010-04-01/Accounts/%s/Messages.json",
	}

	log.Println("Configuration loaded successfully")
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

	// Declare queue
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

func consumeNotifications() {
	msgs, err := rabbitCh.Consume(
		"notifications", // queue
		"",              // consumer
		false,           // auto-ack
		false,           // exclusive
		false,           // no-local
		false,           // no-wait
		nil,             // args
	)
	if err != nil {
		log.Fatal("Failed to register consumer:", err)
	}

	log.Println("Waiting for notification messages...")

	for msg := range msgs {
		var req NotificationRequest
		if err := json.Unmarshal(msg.Body, &req); err != nil {
			log.Printf("Error parsing message: %v", err)
			msg.Nack(false, false) // Don't requeue malformed messages
			continue
		}

		log.Printf("Processing notification: %s (%s)", req.ReminderID, req.NotificationType)

		var err error
		if req.NotificationType == "email" {
			err = sendEmail(req)
		} else if req.NotificationType == "sms" {
			err = sendSMS(req)
		}

		if err != nil {
			log.Printf("Error sending notification: %v", err)
			msg.Nack(false, true) // Requeue on failure
		} else {
			log.Printf("Notification sent successfully: %s", req.ReminderID)
			msg.Ack(false)
		}
	}
}

func sendEmail(req NotificationRequest) error {
	// Create email body from template
	emailBody, err := generateEmailBody(req)
	if err != nil {
		return fmt.Errorf("failed to generate email body: %w", err)
	}

	// Email headers
	subject := fmt.Sprintf("Reminder: %s", req.Title)
	headers := make(map[string]string)
	headers["From"] = emailConfig.From
	headers["To"] = req.Email
	headers["Subject"] = subject
	headers["MIME-Version"] = "1.0"
	headers["Content-Type"] = "text/html; charset=UTF-8"

	// Build message
	var message bytes.Buffer
	for k, v := range headers {
		message.WriteString(fmt.Sprintf("%s: %s\r\n", k, v))
	}
	message.WriteString("\r\n")
	message.WriteString(emailBody)

	// Send email via SMTP
	auth := smtp.PlainAuth("", emailConfig.Username, emailConfig.Password, emailConfig.Host)
	addr := fmt.Sprintf("%s:%s", emailConfig.Host, emailConfig.Port)

	err = smtp.SendMail(addr, auth, emailConfig.From, []string{req.Email}, message.Bytes())
	if err != nil {
		return fmt.Errorf("failed to send email: %w", err)
	}

	return nil
}

func sendSMS(req NotificationRequest) error {
	if smsConfig.AccountSID == "" || smsConfig.AuthToken == "" {
		return fmt.Errorf("Twilio credentials not configured")
	}

	// Create SMS body
	smsBody := fmt.Sprintf("Reminder: %s\n%s\nScheduled for: %s",
		req.Title,
		req.Description,
		req.DateTime.Format("Jan 02, 2006 at 3:04 PM"),
	)

	// Prepare Twilio API request
	apiURL := fmt.Sprintf(smsConfig.TwilioURL, smsConfig.AccountSID)
	data := fmt.Sprintf("To=%s&From=%s&Body=%s", req.Phone, smsConfig.FromPhone, smsBody)

	client := &http.Client{}
	httpReq, err := http.NewRequest("POST", apiURL, bytes.NewBufferString(data))
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	httpReq.SetBasicAuth(smsConfig.AccountSID, smsConfig.AuthToken)
	httpReq.Header.Add("Content-Type", "application/x-www-form-urlencoded")

	resp, err := client.Do(httpReq)
	if err != nil {
		return fmt.Errorf("failed to send SMS: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusCreated {
		return fmt.Errorf("Twilio API error: status %d", resp.StatusCode)
	}

	return nil
}

func generateEmailBody(req NotificationRequest) (string, error) {
	tmpl := `
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #4F46E5; color: white; padding: 20px; border-radius: 5px; }
        .content { padding: 20px; background-color: #f9f9f9; border-radius: 5px; margin-top: 20px; }
        .footer { margin-top: 20px; font-size: 12px; color: #666; }
        .datetime { font-weight: bold; color: #4F46E5; font-size: 18px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h2>🔔 Reminder Notification</h2>
        </div>
        <div class="content">
            <h3>{{.Title}}</h3>
            <p>{{.Description}}</p>
            <p class="datetime">📅 {{.DateTimeFormatted}}</p>
        </div>
        <div class="footer">
            <p>This is an automated reminder from your Reminder System.</p>
        </div>
    </div>
</body>
</html>
`

	t, err := template.New("email").Parse(tmpl)
	if err != nil {
		return "", err
	}

	data := struct {
		Title              string
		Description        string
		DateTimeFormatted  string
	}{
		Title:             req.Title,
		Description:       req.Description,
		DateTimeFormatted: req.DateTime.Format("Monday, January 2, 2006 at 3:04 PM"),
	}

	var buf bytes.Buffer
	if err := t.Execute(&buf, data); err != nil {
		return "", err
	}

	return buf.String(), nil
}

// HTTP Handlers for manual testing
func sendEmailHandler(c *gin.Context) {
	var req NotificationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := sendEmail(req); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Email sent successfully"})
}

func sendSMSHandler(c *gin.Context) {
	var req NotificationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := sendSMS(req); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "SMS sent successfully"})
}

func healthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":  "healthy",
		"service": "notification-service",
		"time":    time.Now(),
	})
}

func getEnv(key, defaultValue string) string {
	value := os.Getenv(key)
	if value == "" {
		return defaultValue
	}
	return value
}