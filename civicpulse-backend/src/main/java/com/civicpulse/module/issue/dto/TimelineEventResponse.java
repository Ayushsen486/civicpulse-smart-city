package com.civicpulse.module.issue.dto;

import com.civicpulse.module.issue.entity.IssueTimelineEvent;
import com.civicpulse.module.issue.entity.TimelineEventType;

import java.time.Instant;
import java.util.UUID;

public record TimelineEventResponse(
        UUID id,
        UUID issueId,
        UUID actorId,
        String actorName,
        String actorRole,
        TimelineEventType eventType,
        String oldValue,
        String newValue,
        String remarks,
        String metadata,
        Instant createdAt
) {
    public static TimelineEventResponse fromEntity(IssueTimelineEvent event) {
        if (event == null) return null;
        String actorName = event.getActor() != null
                ? event.getActor().getFirstName() + " " + event.getActor().getLastName()
                : "System";
        String actorRole = event.getActor() != null ? event.getActor().getRole().name() : "SYSTEM";
        UUID actorId = event.getActor() != null ? event.getActor().getId() : null;

        return new TimelineEventResponse(
                event.getId(),
                event.getIssue().getId(),
                actorId,
                actorName,
                actorRole,
                event.getEventType(),
                event.getOldValue(),
                event.getNewValue(),
                event.getRemarks(),
                event.getMetadata(),
                event.getCreatedAt()
        );
    }
}
