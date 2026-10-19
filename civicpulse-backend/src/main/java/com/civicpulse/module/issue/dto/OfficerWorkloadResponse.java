package com.civicpulse.module.issue.dto;

import java.util.UUID;

public record OfficerWorkloadResponse(
        UUID officerId,
        String officerName,
        String email,
        long activeIssuesCount,
        long resolvedIssuesCount
) {
}
