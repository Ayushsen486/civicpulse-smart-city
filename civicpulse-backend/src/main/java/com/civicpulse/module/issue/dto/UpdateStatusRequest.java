package com.civicpulse.module.issue.dto;

import com.civicpulse.module.issue.entity.IssueStatus;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record UpdateStatusRequest(
        @NotNull(message = "New status is required")
        IssueStatus status,

        @Size(max = 1000, message = "Remarks cannot exceed 1000 characters")
        String remarks
) {}
