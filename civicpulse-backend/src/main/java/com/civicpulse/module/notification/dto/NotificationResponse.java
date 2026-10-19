package com.civicpulse.module.notification.dto;

import com.civicpulse.module.notification.entity.Notification;

import java.time.Instant;
import java.util.UUID;

public record NotificationResponse(
        UUID id,
        String title,
        String body,
        String type,
        String referenceType,
        UUID referenceId,
        boolean isRead,
        Instant sentAt
) {
    public static NotificationResponse fromEntity(Notification entity) {
        return new NotificationResponse(
                entity.getId(),
                entity.getTitle(),
                entity.getBody(),
                entity.getType(),
                entity.getReferenceType(),
                entity.getReferenceId(),
                entity.isRead(),
                entity.getSentAt()
        );
    }
}
