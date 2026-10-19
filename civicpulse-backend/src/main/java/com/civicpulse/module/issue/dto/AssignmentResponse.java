package com.civicpulse.module.issue.dto;

import com.civicpulse.module.issue.entity.IssueAssignment;

import java.time.Instant;
import java.util.UUID;

public record AssignmentResponse(
        UUID id,
        UUID issueId,
        UUID officerId,
        String officerName,
        UUID assignedById,
        String assignedByName,
        Instant assignedAt,
        Instant unassignedAt,
        boolean isCurrent
) {
    public static AssignmentResponse fromEntity(IssueAssignment assignment) {
        if (assignment == null) return null;
        String officerName = assignment.getOfficer() != null
                ? assignment.getOfficer().getFirstName() + " " + assignment.getOfficer().getLastName()
                : null;
        String assignedByName = assignment.getAssignedBy() != null
                ? assignment.getAssignedBy().getFirstName() + " " + assignment.getAssignedBy().getLastName()
                : null;

        return new AssignmentResponse(
                assignment.getId(),
                assignment.getIssue().getId(),
                assignment.getOfficer().getId(),
                officerName,
                assignment.getAssignedBy().getId(),
                assignedByName,
                assignment.getAssignedAt(),
                assignment.getUnassignedAt(),
                assignment.isCurrent()
        );
    }
}
