package com.civicpulse.module.issue.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;

import java.io.Serializable;
import java.util.Objects;
import java.util.UUID;

@Embeddable
public class IssueUpvoteId implements Serializable {

    @Column(name = "issue_id")
    private UUID issueId;

    @Column(name = "user_id")
    private UUID userId;

    public IssueUpvoteId() {
    }

    public IssueUpvoteId(UUID issueId, UUID userId) {
        this.issueId = issueId;
        this.userId = userId;
    }

    public UUID getIssueId() {
        return issueId;
    }

    public void setIssueId(UUID issueId) {
        this.issueId = issueId;
    }

    public UUID getUserId() {
        return userId;
    }

    public void setUserId(UUID userId) {
        this.userId = userId;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        IssueUpvoteId that = (IssueUpvoteId) o;
        return Objects.equals(issueId, that.issueId) && Objects.equals(userId, that.userId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(issueId, userId);
    }
}
