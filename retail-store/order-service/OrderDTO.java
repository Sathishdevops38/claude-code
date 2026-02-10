package com.retail.order.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreateOrderRequest {
    private Long userId;
    private List<OrderItemRequest> items;
    private String shippingAddress;
}

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
class OrderItemRequest {
    private Long productId;
    private Integer quantity;
}

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
class OrderResponse {
    private Long id;
    private Long userId;
    private Double totalAmount;
    private String status;
    private List<OrderItemResponse> items;
    private String shippingAddress;
    private String trackingNumber;
    private LocalDateTime createdAt;
}

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
class OrderItemResponse {
    private Long productId;
    private String productName;
    private Integer quantity;
    private Double price;
}

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
class UpdateOrderStatusRequest {
    private String status;
    private String trackingNumber;
}
