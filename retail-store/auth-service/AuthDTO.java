package com.retail.auth.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AuthRequest {
    private String email;
    private String password;
}

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
class RegisterRequest {
    private String email;
    private String password;
    private String firstName;
    private String lastName;
    private String username;
}

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
class AuthResponse {
    private Long userId;
    private String token;
    private String email;
    private String username;
    private String firstName;
    private String lastName;
}

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
class TokenValidationResponse {
    private boolean valid;
    private Long userId;
    private String email;
}
