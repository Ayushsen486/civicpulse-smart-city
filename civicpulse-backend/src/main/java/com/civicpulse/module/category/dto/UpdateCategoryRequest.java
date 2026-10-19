package com.civicpulse.module.category.dto;

import com.civicpulse.module.category.entity.Priority;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public record UpdateCategoryRequest(
        @Size(max = 100, message = "Category name cannot exceed 100 characters")
        String name,

        @Pattern(regexp = "^[a-z0-9]+(?:-[a-z0-9]+)*$", message = "Slug must be lowercase alphanumeric with hyphens")
        @Size(max = 100, message = "Slug cannot exceed 100 characters")
        String slug,

        @Size(max = 50, message = "Icon name cannot exceed 50 characters")
        String icon,

        @Pattern(regexp = "^#([A-Fa-f0-9]{6})$", message = "Color must be a valid 6-character hex code")
        String color,

        Priority defaultPriority,

        Integer slaHoursOverride,

        Boolean isActive,

        UUID parentId,

        Integer sortOrder
) {}
