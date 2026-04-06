package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/lubricentros/api/internal/database"
	"github.com/lubricentros/api/internal/database/migrations"
	"github.com/lubricentros/api/internal/domain/entity"
	"github.com/lubricentros/api/internal/handler"
	infraMiddleware "github.com/lubricentros/api/internal/infrastructure/middleware"
	"github.com/lubricentros/api/internal/middleware"
	"github.com/lubricentros/api/internal/repository"
	"github.com/lubricentros/api/internal/usecase"
	"github.com/lubricentros/api/pkg/config"
	jwtpkg "github.com/lubricentros/api/pkg/jwt"
)

func main() {
	// Load and validate configuration from .env
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	// Establish MariaDB connection pool
	db, err := database.Connect(cfg.Database)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()
	log.Println("[main] Database connection pool established")

	// Run pending migrations
	if err := migrations.RunMigrations(db); err != nil {
		log.Fatalf("Failed to run migrations: %v", err)
	}
	log.Println("[main] Database migrations applied")

	// Initialize JWT manager
	jwtMgr, err := jwtpkg.NewManager()
	if err != nil {
		log.Fatalf("Failed to initialize JWT manager: %v", err)
	}

	// Set Gin mode based on environment
	if cfg.Environment == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	r := gin.New()
	r.Use(gin.Recovery())
	r.Use(gin.Logger())
	
	// Add CORS middleware
	r.Use(infraMiddleware.CORS())
	
	// Add input sanitization middleware
	r.Use(infraMiddleware.InputSanitizer())

	// Create repositories
	userRepo := repository.NewUserRepository(db)
	vehicleRepo := repository.NewVehicleRepository(db)
	appointmentRepo := repository.NewAppointmentRepository(db)
	serviceRepo := repository.NewServiceRecordRepository(db)
	refreshRepo := repository.NewRefreshTokenRepository(db)
	auditRepo := repository.NewAuditLogRepository(db)
	passwordResetRepo := repository.NewPasswordResetTokenRepository(db)

	// Create usecases
	authUsecase := usecase.NewAuthUsecase(userRepo, refreshRepo, jwtMgr)
	authUsecase.SetAuditRepo(auditRepo) // Set audit repo to avoid circular dependency
	authUsecase.SetPasswordResetRepo(passwordResetRepo) // Set password reset repo
	vehicleUsecase := usecase.NewVehicleUsecase(vehicleRepo, serviceRepo)
	appointmentUsecase := usecase.NewAppointmentUsecase(appointmentRepo, vehicleRepo)
	serviceUsecase := usecase.NewServiceUsecase(serviceRepo, vehicleRepo)

	// Create handlers
	authHandler := handler.NewAuthHandler(authUsecase)
	vehicleHandler := handler.NewVehicleHandler(vehicleUsecase)
	appointmentHandler := handler.NewAppointmentHandler(appointmentUsecase)
	serviceHandler := handler.NewServiceHandler(serviceUsecase)

	// Health check endpoint
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok"})
	})

	// Public auth routes (with rate limiting)
	auth := r.Group("/auth")
	auth.Use(infraMiddleware.RateLimit(5)) // 5 requests per minute
	{
		auth.POST("/register", authHandler.Register)
		auth.POST("/login", authHandler.Login)
		auth.POST("/refresh", authHandler.Refresh)
		auth.POST("/logout", authHandler.Logout)
		auth.POST("/password-recovery", authHandler.RequestPasswordRecovery)
		auth.POST("/password-reset", authHandler.ResetPassword)
	}

	// Protected routes (require authentication)
	protected := r.Group("/")
	protected.Use(middleware.Auth(jwtMgr))
	{
		// Vehicle routes
		vehicles := protected.Group("/vehicles")
		{
			vehicles.GET("", vehicleHandler.List)
			vehicles.POST("", vehicleHandler.Create)
			vehicles.GET("/:id", vehicleHandler.GetByID)
			vehicles.PUT("/:id", vehicleHandler.Update)
			vehicles.DELETE("/:id", vehicleHandler.Delete)
			vehicles.GET("/:id/report", vehicleHandler.GetReport)
		}

		// Appointment routes
		appointments := protected.Group("/appointments")
		{
			appointments.GET("", appointmentHandler.List)
			appointments.POST("", appointmentHandler.Create)
			appointments.GET("/:id", appointmentHandler.GetByID)
			appointments.PUT("/:id", appointmentHandler.Update)
			appointments.DELETE("/:id", appointmentHandler.Delete)
			appointments.GET("/slots", appointmentHandler.AvailableSlots)
		}

		// Service routes
		services := protected.Group("/services")
		{
			services.GET("/vehicle/:vehicleId", serviceHandler.GetByVehicleID)
		}

		// Admin-only service creation
		admin := protected.Group("/admin")
		admin.Use(middleware.RequireRole(entity.RoleAdmin))
		{
			admin.POST("/services", serviceHandler.Create)
		}

		// Logout all (authenticated users)
		protected.POST("/auth/logout-all", authHandler.LogoutAll)
	}

	// Graceful shutdown
	srv := &http.Server{
		Addr:    ":" + cfg.Port,
		Handler: r,
	}

	// Start server in a goroutine
	go func() {
		log.Printf("[main] Server starting on port %s", cfg.Port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Server failed to start: %v", err)
		}
	}()

	// Wait for interrupt signal
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	log.Println("[main] Shutting down server...")

	// Graceful shutdown with timeout
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		log.Fatalf("Server forced to shutdown: %v", err)
	}

	log.Println("[main] Server exited properly")
}
