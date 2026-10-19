package com.civicpulse.module.issue.dto;

import java.util.List;

public record IssueStatisticsResponse(
        long totalIssues,
        long reportedCount,
        long acknowledgedCount,
        long assignedCount,
        long inProgressCount,
        long resolvedCount,
        long closedCount,
        long rejectedCount,
        long slaBreachedCount,
        long highPriorityCount,
        List<OfficerWorkloadResponse> officerWorkloads
) {
}
