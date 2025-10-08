// main.go - Reminder Service
package main

import (
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

// Reminder model
type Reminder struct {
	ID               string    `json:"id" gorm:"primaryKey"`
	UserID           string    `json:"user_id" gorm:"index"`
	Title            string    `json:"title" gorm:"not null"`
	Description      string    `json:"description"`
	DateTime         time.Time `json:"datetime" gorm:"column:date_time;not null"`
	NotificationType string    `json:"notification_type" gorm:"not null"` // email or sms
	Email            string    `json:"email,omitempty"`
	Phone            string    `json:"phone,omitempty"`
	Status           string    `json:"status" gorm:"default:'pending'"` // pending, processing, sent, failed
	CreatedAt        time.Time `json:"created_at"`
	UpdatedAt        time.Time `json:"updated_at"`
}

// CreateReminderRequest DTO
type CreateReminderRequest struct {
	Title            string `json:"title" binding:"required"`
	Description      string `json:"description"`
	DateTime         string `json:"datetime" binding:"required"`
	NotificationType string `json:"notification_type" binding:"required,oneof=email sms"`
	Email            string `json:"email"`
	Phone            string `json:"phone"`
}

// UpdateReminderRequest DTO
type UpdateReminderRequest struct {
	Title            string `json:"title"`
	Description      string `json:"description"`
	DateTime         string `json:"datetime"`
	NotificationType string `json:"notification_type" binding:"omitempty,oneof=email sms"`
	Email            string `json:"email"`
	Phone            string `json:"phone"`
	Status           string `json:"status" binding:"omitempty,oneof=pending processing sent failed"`
}

// RabbitMQ message structure
type ReminderNotification struct {
	ReminderID       string    `json:"reminder_id"`
	Title            string    `json:"title"`
	Description      string    `json:"description"`
	DateTime         time.Time `json:"datetime"`
	NotificationType string    `json:"notification_type"`
	Email            string    `json:"email,omitempty"`
	Phone            string    `json:"phone,omitempty"`
}

var db *gorm.DB

func main() {
	// Initialize database
	initDB()

	// Initialize Gin router
	router := gin.Default()

	// CORS is handled by the API Gateway (nginx)

	// Health check
	router.GET("/health", healthCheck)

	// Reminder routes
	api := router.Group("/api/reminders")
	{
		api.GET("", listReminders)
		api.GET("/:id", getReminder)
		api.POST("", createReminder)
		api.PUT("/:id", updateReminder)
		api.DELETE("/:id", deleteReminder)
		api.GET("/pending", getPendingReminders)                // For scheduler service
		api.POST("/reset-stuck", resetStuckProcessingReminders) // For scheduler service
		api.PUT("/:id/status", updateReminderStatusOnly)        // For scheduler service - status only updates
	}

	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = "8081"
	}

	log.Printf("Reminder Service starting on port %s", port)
	if err := router.Run(":" + port); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}

func initDB() {
	dsn := os.Getenv("DATABASE_URL")
	if dsn == "" {
		dsn = "host=postgres user=reminder password=reminder dbname=reminder_db port=5432 sslmode=disable"
	}

	var err error
	db, err = gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}

	// Auto migrate the schema
	if err := db.AutoMigrate(&Reminder{}); err != nil {
		log.Fatal("Failed to migrate database:", err)
	}

	log.Println("Database connected and migrated successfully")
}

// CORS middleware removed - handled by API Gateway

func healthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":  "healthy",
		"service": "reminder-service",
		"time":    time.Now(),
	})
}

func listReminders(c *gin.Context) {
	userID := c.Query("user_id")
	if userID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "user_id is required"})
		return
	}

	var reminders []Reminder
	if err := db.Where("user_id = ?", userID).Order("date_time asc").Find(&reminders).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch reminders"})
		return
	}

	c.JSON(http.StatusOK, reminders)
}

func getReminder(c *gin.Context) {
	id := c.Param("id")
	userID := c.Query("user_id")

	var reminder Reminder
	if err := db.Where("id = ? AND user_id = ?", id, userID).First(&reminder).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": "Reminder not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch reminder"})
		return
	}

	c.JSON(http.StatusOK, reminder)
}

func createReminder(c *gin.Context) {
	var req CreateReminderRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Validate notification type requirements
	if req.NotificationType == "email" && req.Email == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Email is required for email notifications"})
		return
	}
	if req.NotificationType == "sms" && req.Phone == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Phone is required for SMS notifications"})
		return
	}

	// Parse datetime
	datetime, err := time.Parse(time.RFC3339, req.DateTime)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid datetime format. Use RFC3339"})
		return
	}

	// Get user ID from header or query (in production, extract from JWT)
	userID := c.GetHeader("X-User-ID")
	if userID == "" {
		userID = c.Query("user_id")
	}
	if userID == "" {
		userID = "default-user" // For testing
	}

	reminder := Reminder{
		ID:               uuid.New().String(),
		UserID:           userID,
		Title:            req.Title,
		Description:      req.Description,
		DateTime:         datetime,
		NotificationType: req.NotificationType,
		Email:            req.Email,
		Phone:            req.Phone,
		Status:           "pending",
	}

	if err := db.Create(&reminder).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create reminder"})
		return
	}

	// TODO: Publish event to RabbitMQ for scheduler service
	// publishReminderCreated(reminder)

	c.JSON(http.StatusCreated, reminder)
}

func updateReminder(c *gin.Context) {
	id := c.Param("id")
	userID := c.GetHeader("X-User-ID")
	if userID == "" {
		userID = c.Query("user_id")
	}

	var req UpdateReminderRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var reminder Reminder
	var err error

	// If no user_id provided (scheduler service), just find by ID
	if userID == "" {
		err = db.Where("id = ?", id).First(&reminder).Error
	} else {
		// Regular user update, check user ownership
		err = db.Where("id = ? AND user_id = ?", id, userID).First(&reminder).Error
	}

	if err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": "Reminder not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch reminder"})
		return
	}

	// Update fields
	if req.Title != "" {
		reminder.Title = req.Title
	}
	if req.Description != "" {
		reminder.Description = req.Description
	}
	if req.DateTime != "" {
		datetime, err := time.Parse(time.RFC3339, req.DateTime)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid datetime format"})
			return
		}
		reminder.DateTime = datetime
	}
	if req.NotificationType != "" {
		reminder.NotificationType = req.NotificationType
	}
	if req.Email != "" {
		reminder.Email = req.Email
	}
	if req.Phone != "" {
		reminder.Phone = req.Phone
	}
	if req.Status != "" {
		reminder.Status = req.Status
	}

	if err := db.Save(&reminder).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update reminder"})
		return
	}

	c.JSON(http.StatusOK, reminder)
}

func deleteReminder(c *gin.Context) {
	id := c.Param("id")
	userID := c.GetHeader("X-User-ID")
	if userID == "" {
		userID = c.Query("user_id")
	}

	result := db.Where("id = ? AND user_id = ?", id, userID).Delete(&Reminder{})
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete reminder"})
		return
	}

	if result.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Reminder not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Reminder deleted successfully"})
}

func getPendingReminders(c *gin.Context) {
	// This endpoint is for the scheduler service
	now := time.Now()
	var reminders []Reminder

	// Get reminders that are due now and still pending (not processing, sent, or failed)
	if err := db.Where("status = ? AND date_time <= ?", "pending", now).Find(&reminders).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch pending reminders"})
		return
	}

	c.JSON(http.StatusOK, reminders)
}

func resetStuckProcessingReminders(c *gin.Context) {
	// Reset reminders that have been in "processing" status for more than 5 minutes
	fiveMinutesAgo := time.Now().Add(-5 * time.Minute)

	result := db.Model(&Reminder{}).
		Where("status = ? AND updated_at < ?", "processing", fiveMinutesAgo).
		Update("status", "pending")

	if result.Error != nil {
		log.Printf("Error resetting stuck processing reminders: %v", result.Error)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to reset stuck reminders"})
		return
	}

	if result.RowsAffected > 0 {
		log.Printf("Reset %d stuck processing reminders", result.RowsAffected)
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Stuck reminders reset successfully",
		"count":   result.RowsAffected,
	})
}
func updateReminderStatusOnly(c *gin.Context) {
	// This endpoint is specifically for the scheduler service to update status
	id := c.Param("id")

	var req struct {
		Status string `json:"status" binding:"required,oneof=pending processing sent failed"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	result := db.Model(&Reminder{}).Where("id = ?", id).Update("status", req.Status)
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update reminder status"})
		return
	}

	if result.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Reminder not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Status updated successfully"})
}
