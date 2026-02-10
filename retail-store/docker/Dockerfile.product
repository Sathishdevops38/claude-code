# Product Service Dockerfile
FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY product-service/go.mod go.sum ./
RUN go mod download

COPY product-service .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

FROM alpine:latest

WORKDIR /app
RUN apk --no-cache add ca-certificates
COPY --from=builder /app/main .
COPY product-service/.env .

EXPOSE 8082

CMD ["./main"]
