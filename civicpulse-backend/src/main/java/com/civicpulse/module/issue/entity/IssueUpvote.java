package com.civicpulse.module.issue.entity;

import com.civicpulse.module.user.entity.User;
import jakarta.persistence.*;

import java.time.Instant;

@Entity
@Table(name = "issue_upvotes")
public class IssueUpvote {

    @EmbeddedId
    private IssueUpvoteId id;

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("issueId")
    @JoinColumn(name = "issue_id", nullable = false)
    private Issue issue;

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("userId")
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    public IssueUpvote() {
    }

    public IssueUpvote(Issue issue, User user) {
        this.id = new IssueUpvoteId(issue.getId(), user.getId());
        this.issue = issue;
        this.user = user;
        this.createdAt = Instant.now();
    }

    public IssueUpvoteId getId() {
        return id;
    }

    public void setId(IssueUpvoteId id) {
        this.id = id;
    }

    public Issue getIssue() {
        return issue;
    }

    public void setIssue(Issue issue) {
        this.issue = issue;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }
}
