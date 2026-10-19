package com.civicpulse.module.user.dto;

import com.civicpulse.module.user.entity.User;
import com.civicpulse.module.user.entity.UserRole;

import java.time.Instant;
import java.util.UUID;

public record UserResponse(
        UUID id,
        String email,
        String phone,
        String firstName,
        String lastName,
        UserRole role,
        String avatarUrl,
        boolean isActive,
        boolean isPhoneVerified,
        boolean isEmailVerified,
        UUID wardId,
        String wardName,
        Instant createdAt,
        Instant updatedAt
) {
    public static UserResponse fromEntity(User user) {
        if (user == null) {
            return null;
        }
        UUID wardId = null;
        String wardName = null;
        if (user.getWard() != null) {
            wardId = user.getWard().getId();
            wardName = user.getWard().getName();
        }
        return new UserResponse(
                user.getId(),
                user.getEmail(),
                user.getPhone(),
                user.getFirstName(),
                user.getLastName(),
                user.getRole(),
                user.getAvatarUrl(),
                user.isActive(),
                user.isPhoneVerified(),
                user.isEmailVerified(),
                wardId,
                wardName,
                user.getCreatedAt(),
                user.getUpdatedAt()
        );
    }
}
