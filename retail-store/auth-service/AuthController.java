package com.retail.auth.controller;

import com.retail.auth.dto.AuthResponse;
import com.retail.auth.dto.AuthRequest;
import com.retail.auth.dto.RegisterRequest;
import com.retail.auth.dto.TokenValidationResponse;
import com.retail.auth.service.AuthService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*")
public class AuthController {
    @Autowired
    private AuthService authService;

    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@RequestBody RegisterRequest request) {
        AuthResponse response = authService.register(
                request.getEmail(),
                request.getPassword(),
                request.getFirstName(),
                request.getLastName(),
                request.getUsername()
        );
        return ResponseEntity.ok(response);
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@RequestBody AuthRequest request) {
        AuthResponse response = authService.login(request.getEmail(), request.getPassword());
        return ResponseEntity.ok(response);
    }

    @GetMapping("/validate-token/{token}")
    public ResponseEntity<TokenValidationResponse> validateToken(@PathVariable String token) {
        boolean isValid = authService.validateToken(token);
        if (isValid) {
            Long userId = authService.getUserIdFromToken(token);
            TokenValidationResponse response = TokenValidationResponse.builder()
                    .valid(true)
                    .userId(userId)
                    .build();
            return ResponseEntity.ok(response);
        }
        return ResponseEntity.ok(TokenValidationResponse.builder().valid(false).build());
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<?> getUserById(@PathVariable Long userId) {
        return ResponseEntity.ok(authService.getUserById(userId));
    }
}
