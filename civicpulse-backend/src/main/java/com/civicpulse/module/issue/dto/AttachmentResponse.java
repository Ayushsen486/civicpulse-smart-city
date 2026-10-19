package com.civicpulse.module.issue.dto;

import com.civicpulse.module.issue.entity.AttachmentType;
import com.civicpulse.module.issue.entity.IssueAttachment;

import java.time.Instant;
import java.util.UUID;

public record AttachmentResponse(
        UUID id,
        UUID issueId,
        String fileUrl,
        String storageKey,
        String originalFilename,
        String mimeType,
        String fileType,
        Integer fileSize,
        AttachmentType attachmentType,
        boolean isBefore,
        UUID uploadedById,
        String uploadedByName,
        Instant createdAt
) {
    public static AttachmentResponse fromEntity(IssueAttachment attachment) {
        if (attachment == null) return null;
        String uploaderName = attachment.getUploadedBy() != null
                ? attachment.getUploadedBy().getFirstName() + " " + attachment.getUploadedBy().getLastName()
                : null;
        UUID uploaderId = attachment.getUploadedBy() != null ? attachment.getUploadedBy().getId() : null;

        return new AttachmentResponse(
                attachment.getId(),
                attachment.getIssue().getId(),
                attachment.getFileUrl(),
                attachment.getStorageKey(),
                attachment.getOriginalFilename(),
                attachment.getMimeType(),
                attachment.getFileType(),
                attachment.getFileSize(),
                attachment.getAttachmentType(),
                attachment.isBefore(),
                uploaderId,
                uploaderName,
                attachment.getCreatedAt()
        );
    }
}
