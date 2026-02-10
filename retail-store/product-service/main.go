package main

import (
	"fmt"
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	"github.com/retail/product-service/database"
	"github.com/retail/product-service/handlers"
)

func main() {
	// Load environment variables
	godotenv.Load()

	// Initialize database
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?charset=utf8mb4&parseTime=True&loc=Local",
		os.Getenv("DB_USER"),
		os.Getenv("DB_PASSWORD"),
		os.Getenv("DB_HOST"),
		os.Getenv("DB_PORT"),
		os.Getenv("DB_NAME"),
	)

	if err := database.Init(dsn); err != nil {
		log.Fatalf("Failed to initialize database: %v", err)
	}

	// Create Gin router
	router := gin.Default()

	// Add CORS middleware
	router.Use(func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}
		c.Next()
	})

	// Product routes
	api := router.Group("/api/products")
	{
		api.GET("", handlers.GetAllProducts)
		api.GET("/search", handlers.SearchProducts)
		api.GET("/category/:category", handlers.GetProductsByCategory)
		api.GET("/:id", handlers.GetProductByID)
		api.POST("", handlers.CreateProduct)
		api.PUT("/:id", handlers.UpdateProduct)
		api.DELETE("/:id", handlers.DeleteProduct)
		api.PUT("/:id/reduce-stock", handlers.ReduceStock)
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8082"
	}

	log.Printf("Product Service starting on port %s", port)
	if err := router.Run(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
