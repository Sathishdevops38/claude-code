package handlers

import (
	"log"
	"net/http"
	"strconv"
	"github.com/gin-gonic/gin"
	"github.com/retail/product-service/database"
	"github.com/retail/product-service/models"
)

// GetAllProducts retrieves all products with optional filtering
func GetAllProducts(c *gin.Context) {
	category := c.Query("category")
	var products []models.Product
	query := database.GetDB()

	if category != "" {
		query = query.Where("category = ?", category)
	}

	if err := query.Find(&products).Error; err != nil {
		log.Printf("Error fetching products: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch products"})
		return
	}

	c.JSON(http.StatusOK, products)
}

// GetProductByID retrieves a single product by ID
func GetProductByID(c *gin.Context) {
	id := c.Param("id")
	var product models.Product

	if err := database.GetDB().First(&product, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Product not found"})
		return
	}

	c.JSON(http.StatusOK, product)
}

// SearchProducts searches products by name or description
func SearchProducts(c *gin.Context) {
	query := c.Query("q")
	if query == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Search query is required"})
		return
	}

	var products []models.Product
	if err := database.GetDB().Where("name LIKE ?", "%"+query+"%").Or("description LIKE ?", "%"+query+"%").Find(&products).Error; err != nil {
		log.Printf("Error searching products: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Search failed"})
		return
	}

	c.JSON(http.StatusOK, products)
}

// CreateProduct creates a new product
func CreateProduct(c *gin.Context) {
	var req models.CreateProductRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	product := models.Product{
		Name:        req.Name,
		Description: req.Description,
		Price:       req.Price,
		Stock:       req.Stock,
		Category:    req.Category,
		ImageURL:    req.ImageURL,
		SKU:         req.SKU,
	}

	if err := database.GetDB().Create(&product).Error; err != nil {
		log.Printf("Error creating product: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create product"})
		return
	}

	c.JSON(http.StatusCreated, product)
}

// UpdateProduct updates an existing product
func UpdateProduct(c *gin.Context) {
	id := c.Param("id")
	var product models.Product

	if err := database.GetDB().First(&product, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Product not found"})
		return
	}

	var req models.UpdateProductRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if req.Name != "" {
		product.Name = req.Name
	}
	if req.Description != "" {
		product.Description = req.Description
	}
	if req.Price != 0 {
		product.Price = req.Price
	}
	if req.Stock >= 0 {
		product.Stock = req.Stock
	}
	if req.Category != "" {
		product.Category = req.Category
	}
	if req.ImageURL != "" {
		product.ImageURL = req.ImageURL
	}

	if err := database.GetDB().Save(&product).Error; err != nil {
		log.Printf("Error updating product: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update product"})
		return
	}

	c.JSON(http.StatusOK, product)
}

// DeleteProduct deletes a product
func DeleteProduct(c *gin.Context) {
	id := c.Param("id")
	if err := database.GetDB().Delete(&models.Product{}, id).Error; err != nil {
		log.Printf("Error deleting product: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete product"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Product deleted successfully"})
}

// GetProductsByCategory gets products by category
func GetProductsByCategory(c *gin.Context) {
	category := c.Param("category")
	var products []models.Product

	if err := database.GetDB().Where("category = ?", category).Find(&products).Error; err != nil {
		log.Printf("Error fetching products by category: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch products"})
		return
	}

	c.JSON(http.StatusOK, products)
}

// ReduceStock reduces product stock (called when order is placed)
func ReduceStock(c *gin.Context) {
	id := c.Param("id")
	quantity := c.Query("quantity")

	q, err := strconv.Atoi(quantity)
	if err != nil || q <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid quantity"})
		return
	}

	var product models.Product
	if err := database.GetDB().First(&product, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Product not found"})
		return
	}

	if product.Stock < q {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Insufficient stock"})
		return
	}

	product.Stock -= q
	if err := database.GetDB().Save(&product).Error; err != nil {
		log.Printf("Error reducing stock: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to reduce stock"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Stock reduced", "remainingStock": product.Stock})
}
