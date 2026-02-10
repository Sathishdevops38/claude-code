# Retail Store API Documentation

Complete API documentation for the microservices-based retail store application.

## Base URLs

```
Auth Service:    http://localhost:8081/api/auth
Product Service: http://localhost:8082/api/products
Order Service:   http://localhost:8083/api/orders
Payment Service: http://localhost:8084/api/payments
Frontend:        http://localhost:3000
```

## Authentication

Most API endpoints require JWT authentication. Include the token in request headers:

```
Authorization: Bearer <jwt_token>
```

---

## Auth Service (Port 8081)

### 1. Register User
**POST** `/api/auth/register`

Request body:
```json
{
  "email": "user@example.com",
  "password": "Password123!",
  "firstName": "John",
  "lastName": "Doe",
  "username": "johndoe"
}
```

Response (201):
```json
{
  "userId": 1,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "email": "user@example.com",
  "username": "johndoe",
  "firstName": "John",
  "lastName": "Doe"
}
```

### 2. Login User
**POST** `/api/auth/login`

Request body:
```json
{
  "email": "user@example.com",
  "password": "Password123!"
}
```

Response (200):
```json
{
  "userId": 1,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "email": "user@example.com",
  "username": "johndoe",
  "firstName": "John",
  "lastName": "Doe"
}
```

### 3. Validate Token
**GET** `/api/auth/validate-token/{token}`

Response (200):
```json
{
  "valid": true,
  "userId": 1,
  "email": "user@example.com"
}
```

### 4. Get User Details
**GET** `/api/auth/user/{userId}`

Response (200):
```json
{
  "id": 1,
  "email": "user@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "username": "johndoe",
  "enabled": true,
  "role": "CUSTOMER",
  "createdAt": "2024-01-15T10:30:00",
  "updatedAt": "2024-01-15T10:30:00"
}
```

---

## Product Service (Port 8082)

### 1. Get All Products
**GET** `/api/products`

Optional query parameters:
- `category`: Filter by category

Response (200):
```json
[
  {
    "id": 1,
    "name": "Laptop",
    "description": "High-performance laptop",
    "price": 999.99,
    "stock": 50,
    "category": "Electronics",
    "imageUrl": "https://...",
    "sku": "LAPTOP-001",
    "createdAt": "2024-01-15T10:30:00"
  },
  {
    "id": 2,
    "name": "Mouse",
    "description": "Wireless mouse",
    "price": 29.99,
    "stock": 150,
    "category": "Electronics",
    "imageUrl": "https://...",
    "sku": "MOUSE-001",
    "createdAt": "2024-01-15T10:30:00"
  }
]
```

### 2. Get Product by ID
**GET** `/api/products/{productId}`

Response (200):
```json
{
  "id": 1,
  "name": "Laptop",
  "description": "High-performance laptop",
  "price": 999.99,
  "stock": 50,
  "category": "Electronics",
  "imageUrl": "https://...",
  "sku": "LAPTOP-001",
  "createdAt": "2024-01-15T10:30:00"
}
```

### 3. Search Products
**GET** `/api/products/search?q={query}`

Response (200):
```json
[
  {
    "id": 1,
    "name": "Laptop",
    "description": "High-performance laptop",
    "price": 999.99,
    "stock": 50,
    "category": "Electronics",
    "imageUrl": "https://...",
    "sku": "LAPTOP-001",
    "createdAt": "2024-01-15T10:30:00"
  }
]
```

### 4. Get Products by Category
**GET** `/api/products/category/{category}`

Response (200):
```json
[
  {
    "id": 1,
    "name": "Laptop",
    "description": "High-performance laptop",
    "price": 999.99,
    "stock": 50,
    "category": "Electronics",
    "imageUrl": "https://...",
    "sku": "LAPTOP-001",
    "createdAt": "2024-01-15T10:30:00"
  }
]
```

### 5. Create Product (Admin Only)
**POST** `/api/products`

Request body:
```json
{
  "name": "Keyboard",
  "description": "Mechanical keyboard",
  "price": 149.99,
  "stock": 100,
  "category": "Electronics",
  "imageUrl": "https://...",
  "sku": "KEYBOARD-001"
}
```

Response (201):
```json
{
  "id": 3,
  "name": "Keyboard",
  "description": "Mechanical keyboard",
  "price": 149.99,
  "stock": 100,
  "category": "Electronics",
  "imageUrl": "https://...",
  "sku": "KEYBOARD-001",
  "createdAt": "2024-01-16T10:30:00"
}
```

### 6. Update Product (Admin Only)
**PUT** `/api/products/{productId}`

Request body:
```json
{
  "name": "Keyboard Pro",
  "price": 159.99
}
```

Response (200):
```json
{
  "id": 3,
  "name": "Keyboard Pro",
  "description": "Mechanical keyboard",
  "price": 159.99,
  "stock": 100,
  "category": "Electronics",
  "imageUrl": "https://...",
  "sku": "KEYBOARD-001",
  "createdAt": "2024-01-16T10:30:00"
}
```

### 7. Delete Product (Admin Only)
**DELETE** `/api/products/{productId}`

Response (200):
```json
{
  "message": "Product deleted successfully"
}
```

### 8. Reduce Stock
**PUT** `/api/products/{productId}/reduce-stock?quantity={quantity}`

Response (200):
```json
{
  "message": "Stock reduced",
  "remainingStock": 95
}
```

---

## Order Service (Port 8083)

### 1. Create Order
**POST** `/api/orders`

Request body:
```json
{
  "userId": 1,
  "items": [
    {
      "productId": 1,
      "quantity": 1
    },
    {
      "productId": 2,
      "quantity": 2
    }
  ],
  "shippingAddress": "123 Main St, City, State 12345"
}
```

Response (201):
```json
{
  "id": 1,
  "userId": 1,
  "totalAmount": 1059.97,
  "status": "PENDING",
  "items": [
    {
      "productId": 1,
      "productName": "Laptop",
      "quantity": 1,
      "price": 999.99
    },
    {
      "productId": 2,
      "productName": "Mouse",
      "quantity": 2,
      "price": 29.99
    }
  ],
  "shippingAddress": "123 Main St, City, State 12345",
  "trackingNumber": null,
  "createdAt": "2024-01-16T10:30:00"
}
```

### 2. Get Order
**GET** `/api/orders/{orderId}`

Response (200):
```json
{
  "id": 1,
  "userId": 1,
  "totalAmount": 1059.97,
  "status": "CONFIRMED",
  "items": [
    {
      "productId": 1,
      "productName": "Laptop",
      "quantity": 1,
      "price": 999.99
    }
  ],
  "shippingAddress": "123 Main St, City, State 12345",
  "trackingNumber": "TRACK123456",
  "createdAt": "2024-01-16T10:30:00"
}
```

### 3. Get User Orders
**GET** `/api/orders/user/{userId}`

Response (200):
```json
[
  {
    "id": 1,
    "userId": 1,
    "totalAmount": 1059.97,
    "status": "CONFIRMED",
    "items": [...],
    "shippingAddress": "123 Main St, City, State 12345",
    "trackingNumber": "TRACK123456",
    "createdAt": "2024-01-16T10:30:00"
  }
]
```

### 4. Get All Orders (Admin Only)
**GET** `/api/orders`

Response (200):
```json
[
  {
    "id": 1,
    "userId": 1,
    "totalAmount": 1059.97,
    "status": "CONFIRMED",
    ...
  }
]
```

### 5. Update Order Status (Admin Only)
**PUT** `/api/orders/{orderId}/status`

Request body:
```json
{
  "status": "SHIPPED",
  "trackingNumber": "TRACK123456"
}
```

Response (200):
```json
{
  "id": 1,
  "userId": 1,
  "totalAmount": 1059.97,
  "status": "SHIPPED",
  "items": [...],
  "shippingAddress": "123 Main St, City, State 12345",
  "trackingNumber": "TRACK123456",
  "createdAt": "2024-01-16T10:30:00"
}
```

---

## Payment Service (Port 8084)

### 1. Health Check
**GET** `/api/payments/health`

Response (200):
```json
{
  "status": "ok",
  "service": "payment-service"
}
```

### 2. Process Payment
**POST** `/api/payments/process`

Request body:
```json
{
  "order_id": 1,
  "user_id": 1,
  "amount": 1059.97,
  "payment_method": "stripe"
}
```

Response (200):
```json
{
  "transactionId": "550e8400-e29b-41d4-a716-446655440000",
  "orderId": 1,
  "amount": 1059.97,
  "status": "COMPLETED",
  "paymentMethod": "stripe",
  "timestamp": "2024-01-16T10:30:00"
}
```

### 3. Get Payment Details
**GET** `/api/payments/{transactionId}`

Response (200):
```json
{
  "id": 1,
  "order_id": 1,
  "user_id": 1,
  "amount": 1059.97,
  "status": "COMPLETED",
  "payment_method": "stripe",
  "transaction_id": "550e8400-e29b-41d4-a716-446655440000",
  "created_at": "2024-01-16T10:30:00",
  "updated_at": "2024-01-16T10:30:00"
}
```

### 4. Get Payment by Order
**GET** `/api/payments/order/{orderId}`

Response (200):
```json
{
  "id": 1,
  "order_id": 1,
  "user_id": 1,
  "amount": 1059.97,
  "status": "COMPLETED",
  "payment_method": "stripe",
  "transaction_id": "550e8400-e29b-41d4-a716-446655440000",
  "created_at": "2024-01-16T10:30:00",
  "updated_at": "2024-01-16T10:30:00"
}
```

### 5. Refund Payment
**POST** `/api/payments/{paymentId}/refund`

Response (200):
```json
{
  "id": 1,
  "status": "REFUNDED",
  "refundedAt": "2024-01-16T11:00:00"
}
```

---

## Error Responses

### 400 Bad Request
```json
{
  "error": "Invalid input data"
}
```

### 401 Unauthorized
```json
{
  "error": "Invalid or expired token"
}
```

### 404 Not Found
```json
{
  "error": "Resource not found"
}
```

### 500 Internal Server Error
```json
{
  "error": "Internal server error"
}
```

---

## Integration Examples

### Example 1: Complete Purchase Flow

1. Register/Login
```bash
curl -X POST http://localhost:8081/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"Password123!"}'
```

2. Get Products
```bash
curl http://localhost:8082/api/products
```

3. Create Order
```bash
curl -X POST http://localhost:8083/api/orders \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "userId":1,
    "items":[{"productId":1,"quantity":1}],
    "shippingAddress":"123 Main St"
  }'
```

4. Process Payment
```bash
curl -X POST http://localhost:8084/api/payments/process \
  -H "Content-Type: application/json" \
  -d '{
    "order_id":1,
    "user_id":1,
    "amount":999.99,
    "payment_method":"stripe"
  }'
```

5. Get Order Status
```bash
curl http://localhost:8083/api/orders/1 \
  -H "Authorization: Bearer <token>"
```

---

## Rate Limiting

Rate limits are applied as follows:
- Auth Service: 100 requests per minute
- Product Service: 1000 requests per minute
- Order Service: 500 requests per minute
- Payment Service: 200 requests per minute

---

## WebSocket Support

Currently, real-time updates via WebSocket are not implemented. Polling can be used to monitor order status changes.

---

## CORS Configuration

All services support Cross-Origin Resource Sharing (CORS) for frontend communication.

Allowed Origins: `*` (in development)
Allowed Methods: `GET, POST, PUT, DELETE, OPTIONS`
Allowed Headers: `Content-Type, Authorization`

---

## Versioning

API is currently at version 1.0. Future versions will be available at:
- `/api/v2/auth`
- `/api/v2/products`
- etc.
