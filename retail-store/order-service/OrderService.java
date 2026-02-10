package com.retail.order.service;

import com.retail.order.dto.*;
import com.retail.order.entity.Order;
import com.retail.order.entity.OrderItem;
import com.retail.order.repository.OrderRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class OrderService {
    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private RestTemplate restTemplate;

    public OrderResponse createOrder(CreateOrderRequest request) {
        // Calculate total amount
        Double totalAmount = 0.0;
        List<OrderItem> items = new java.util.ArrayList<>();

        for (OrderItemRequest itemRequest : request.getItems()) {
            // Here you would call the product service to get price
            // For now, we'll assume a default price
            Double price = 100.0; // This should be fetched from product service
            OrderItem item = OrderItem.builder()
                    .productId(itemRequest.getProductId())
                    .quantity(itemRequest.getQuantity())
                    .price(price)
                    .build();
            items.add(item);
            totalAmount += price * itemRequest.getQuantity();
        }

        Order order = Order.builder()
                .userId(request.getUserId())
                .totalAmount(totalAmount)
                .status(com.retail.order.entity.OrderStatus.PENDING)
                .shippingAddress(request.getShippingAddress())
                .items(items)
                .build();

        Order savedOrder = orderRepository.save(order);
        for (OrderItem item : items) {
            item.setOrder(savedOrder);
        }
        orderRepository.save(savedOrder);

        return convertToResponse(savedOrder);
    }

    public OrderResponse getOrderById(Long orderId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found"));
        return convertToResponse(order);
    }

    public List<OrderResponse> getOrdersByUserId(Long userId) {
        List<Order> orders = orderRepository.findByUserId(userId);
        return orders.stream().map(this::convertToResponse).collect(Collectors.toList());
    }

    public OrderResponse updateOrderStatus(Long orderId, UpdateOrderStatusRequest request) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found"));

        order.setStatus(com.retail.order.entity.OrderStatus.valueOf(request.getStatus()));
        if (request.getTrackingNumber() != null) {
            order.setTrackingNumber(request.getTrackingNumber());
        }

        Order updatedOrder = orderRepository.save(order);
        return convertToResponse(updatedOrder);
    }

    public List<OrderResponse> getAllOrders() {
        return orderRepository.findAll().stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
    }

    private OrderResponse convertToResponse(Order order) {
        List<OrderItemResponse> itemResponses = order.getItems().stream()
                .map(item -> OrderItemResponse.builder()
                        .productId(item.getProductId())
                        .productName(item.getProductName())
                        .quantity(item.getQuantity())
                        .price(item.getPrice())
                        .build())
                .collect(Collectors.toList());

        return OrderResponse.builder()
                .id(order.getId())
                .userId(order.getUserId())
                .totalAmount(order.getTotalAmount())
                .status(order.getStatus().toString())
                .items(itemResponses)
                .shippingAddress(order.getShippingAddress())
                .trackingNumber(order.getTrackingNumber())
                .createdAt(order.getCreatedAt())
                .build();
    }
}
