package com.civicpulse.module.issue.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public record AssignIssueRequest(
        @NotNull(message = "Officer ID is required")
        UUID officerId,

        @Size(max = 500, message = "Remarks cannot exceed 500 characters")
        String remarks
) {}
