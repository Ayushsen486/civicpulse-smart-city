package com.civicpulse.module.issue.dto;

import com.civicpulse.module.issue.entity.IssueComment;

import java.time.Instant;
import java.util.UUID;

public record CommentResponse(
        UUID id,
        UUID issueId,
        UUID authorId,
        String authorName,
        String authorRole,
        String body,
        String content,
        boolean isInternal,
        Instant createdAt,
        Instant updatedAt
) {
    public static CommentResponse fromEntity(IssueComment comment) {
        if (comment == null) return null;
        String authorName = comment.getAuthor() != null
                ? comment.getAuthor().getFirstName() + " " + comment.getAuthor().getLastName()
                : null;
        String authorRole = comment.getAuthor() != null ? comment.getAuthor().getRole().name() : null;
        UUID authorId = comment.getAuthor() != null ? comment.getAuthor().getId() : null;

        return new CommentResponse(
                comment.getId(),
                comment.getIssue().getId(),
                authorId,
                authorName,
                authorRole,
                comment.getBody(),
                comment.getBody(),
                comment.isInternal(),
                comment.getCreatedAt(),
                comment.getUpdatedAt()
        );
    }
}
