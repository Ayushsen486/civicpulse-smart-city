package com.civicpulse.module.issue.dto;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.validation.constraints.Size;

public record CreateCommentRequest(
        @Size(max = 2000, message = "Comment body cannot exceed 2000 characters")
        String body,

        @Size(max = 2000, message = "Comment content cannot exceed 2000 characters")
        String content,

        Boolean isInternal
) {
    public CreateCommentRequest(String body, Boolean isInternal) {
        this(body, null, isInternal);
    }
    @JsonIgnore
    public String getResolvedBody() {
        if (body != null && !body.isBlank()) {
            return body.trim();
        }
        if (content != null && !content.isBlank()) {
            return content.trim();
        }
        return "";
    }
}
