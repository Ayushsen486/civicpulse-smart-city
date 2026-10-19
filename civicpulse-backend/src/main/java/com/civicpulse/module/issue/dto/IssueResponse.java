package com.civicpulse.module.issue.dto;

import com.civicpulse.module.category.entity.Priority;
import com.civicpulse.module.issue.entity.Issue;
import com.civicpulse.module.issue.entity.IssueStatus;

import java.time.Instant;
import java.util.Collections;
import java.util.List;
import java.util.UUID;

public record IssueResponse(
        UUID id,
        Integer issueNumber,
        String issueReference,
        String title,
        String description,
        IssueStatus status,
        Priority priority,
        double priorityScore,
        UUID categoryId,
        String categoryName,
        String categoryIcon,
        String categoryColor,
        UUID reporterId,
        String reporterName,
        UUID assignedOfficerId,
        String assignedOfficerName,
        UUID wardId,
        String wardName,
        double latitude,
        double longitude,
        String address,
        String landmark,
        int upvoteCount,
        int commentCount,
        boolean hasUpvoted,
        Double distanceMeters,
        Instant slaDeadline,
        boolean slaBreached,
        boolean isDuplicate,
        UUID parentIssueId,
        Instant resolvedAt,
        Instant closedAt,
        Instant reopenedAt,
        Instant createdAt,
        Instant updatedAt,
        List<AttachmentResponse> attachments
) {
    public static IssueResponse fromEntity(Issue issue) {
        return fromEntity(issue, false, null, Collections.emptyList());
    }

    public static IssueResponse fromEntity(Issue issue, boolean hasUpvoted, Double distanceMeters, List<AttachmentResponse> attachments) {
        if (issue == null) return null;

        UUID categoryId = issue.getCategory() != null ? issue.getCategory().getId() : null;
        String categoryName = issue.getCategory() != null ? issue.getCategory().getName() : null;
        String categoryIcon = issue.getCategory() != null ? issue.getCategory().getIcon() : null;
        String categoryColor = issue.getCategory() != null ? issue.getCategory().getColor() : null;

        UUID reporterId = issue.getReporter() != null ? issue.getReporter().getId() : null;
        String reporterName = issue.getReporter() != null
                ? issue.getReporter().getFirstName() + " " + issue.getReporter().getLastName()
                : null;

        UUID officerId = issue.getAssignedOfficer() != null ? issue.getAssignedOfficer().getId() : null;
        String officerName = issue.getAssignedOfficer() != null
                ? issue.getAssignedOfficer().getFirstName() + " " + issue.getAssignedOfficer().getLastName()
                : null;

        UUID wardId = issue.getWard() != null ? issue.getWard().getId() : null;
        String wardName = issue.getWard() != null ? issue.getWard().getName() : null;

        double lat = issue.getLocation() != null ? issue.getLocation().getY() : 0.0;
        double lng = issue.getLocation() != null ? issue.getLocation().getX() : 0.0;

        UUID parentId = issue.getParentIssue() != null ? issue.getParentIssue().getId() : null;

        return new IssueResponse(
                issue.getId(),
                issue.getIssueNumber(),
                issue.getIssueReference(),
                issue.getTitle(),
                issue.getDescription(),
                issue.getStatus(),
                issue.getPriority(),
                issue.getPriorityScore(),
                categoryId,
                categoryName,
                categoryIcon,
                categoryColor,
                reporterId,
                reporterName,
                officerId,
                officerName,
                wardId,
                wardName,
                lat,
                lng,
                issue.getAddress(),
                issue.getLandmark(),
                issue.getUpvoteCount(),
                issue.getCommentCount(),
                hasUpvoted,
                distanceMeters,
                issue.getSlaDeadline(),
                issue.isSlaBreached(),
                issue.isDuplicate(),
                parentId,
                issue.getResolvedAt(),
                issue.getClosedAt(),
                issue.getReopenedAt(),
                issue.getCreatedAt(),
                issue.getUpdatedAt(),
                attachments != null ? attachments : Collections.emptyList()
        );
    }
}
