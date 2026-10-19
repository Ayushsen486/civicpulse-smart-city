package com.civicpulse.module.issue.dto;

import com.civicpulse.module.category.entity.Priority;
import jakarta.validation.constraints.Size;

public record UpdateIssueRequest(
        @Size(max = 255, message = "Title cannot exceed 255 characters")
        String title,

        String description,

        Priority priority,

        String address,

        @Size(max = 255, message = "Landmark cannot exceed 255 characters")
        String landmark
) {}
