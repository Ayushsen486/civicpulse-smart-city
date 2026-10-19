package com.civicpulse.module.intelligence.entity;

import com.civicpulse.module.category.entity.Category;
import com.civicpulse.module.category.entity.Priority;
import com.civicpulse.module.issue.entity.Issue;
import com.civicpulse.module.user.entity.User;
import jakarta.persistence.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "issue_intelligence_recommendations")
public class IssueRecommendation {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "issue_id", nullable = false)
    private Issue issue;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "suggested_category_id")
    private Category suggestedCategory;

    @Enumerated(EnumType.STRING)
    @Column(name = "suggested_priority", nullable = false, length = 20)
    private Priority suggestedPriority;

    @Column(name = "recommended_department", nullable = false, length = 100)
    private String recommendedDepartment;

    @Column(name = "category_confidence", nullable = false)
    private double categoryConfidence;

    @Column(name = "priority_confidence", nullable = false)
    private double priorityConfidence;

    @Column(name = "routing_confidence", nullable = false)
    private double routingConfidence;

    @Column(name = "overall_confidence", nullable = false)
    private double overallConfidence;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String explanation;

    @org.hibernate.annotations.JdbcTypeCode(org.hibernate.type.SqlTypes.JSON)
    @Column(columnDefinition = "JSONB")
    private String factors;

    @Column(name = "provider_name", nullable = false, length = 100)
    private String providerName;

    @Column(name = "provider_version", nullable = false, length = 50)
    private String providerVersion;

    @Column(name = "needs_human_review", nullable = false)
    private boolean needsHumanReview = false;

    @Enumerated(EnumType.STRING)
    @Column(name = "review_status", nullable = false, length = 20)
    private ReviewStatus reviewStatus = ReviewStatus.PENDING_REVIEW;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "reviewed_by")
    private User reviewedBy;

    @Column(name = "reviewed_at")
    private Instant reviewedAt;

    @Column(name = "review_notes", columnDefinition = "TEXT")
    private String reviewNotes;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "override_category_id")
    private Category overrideCategory;

    @Enumerated(EnumType.STRING)
    @Column(name = "override_priority", length = 20)
    private Priority overridePriority;

    @Column(name = "override_department", length = 100)
    private String overrideDepartment;

    @Column(name = "is_current", nullable = false)
    private boolean isCurrent = true;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();

    public IssueRecommendation() {
    }

    @PreUpdate
    public void onUpdate() {
        this.updatedAt = Instant.now();
    }

    // Getters and Setters

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public Issue getIssue() {
        return issue;
    }

    public void setIssue(Issue issue) {
        this.issue = issue;
    }

    public Category getSuggestedCategory() {
        return suggestedCategory;
    }

    public void setSuggestedCategory(Category suggestedCategory) {
        this.suggestedCategory = suggestedCategory;
    }

    public Priority getSuggestedPriority() {
        return suggestedPriority;
    }

    public void setSuggestedPriority(Priority suggestedPriority) {
        this.suggestedPriority = suggestedPriority;
    }

    public String getRecommendedDepartment() {
        return recommendedDepartment;
    }

    public void setRecommendedDepartment(String recommendedDepartment) {
        this.recommendedDepartment = recommendedDepartment;
    }

    public double getCategoryConfidence() {
        return categoryConfidence;
    }

    public void setCategoryConfidence(double categoryConfidence) {
        this.categoryConfidence = categoryConfidence;
    }

    public double getPriorityConfidence() {
        return priorityConfidence;
    }

    public void setPriorityConfidence(double priorityConfidence) {
        this.priorityConfidence = priorityConfidence;
    }

    public double getRoutingConfidence() {
        return routingConfidence;
    }

    public void setRoutingConfidence(double routingConfidence) {
        this.routingConfidence = routingConfidence;
    }

    public double getOverallConfidence() {
        return overallConfidence;
    }

    public void setOverallConfidence(double overallConfidence) {
        this.overallConfidence = overallConfidence;
    }

    public String getExplanation() {
        return explanation;
    }

    public void setExplanation(String explanation) {
        this.explanation = explanation;
    }

    public String getFactors() {
        return factors;
    }

    public void setFactors(String factors) {
        this.factors = factors;
    }

    public String getProviderName() {
        return providerName;
    }

    public void setProviderName(String providerName) {
        this.providerName = providerName;
    }

    public String getProviderVersion() {
        return providerVersion;
    }

    public void setProviderVersion(String providerVersion) {
        this.providerVersion = providerVersion;
    }

    public boolean isNeedsHumanReview() {
        return needsHumanReview;
    }

    public void setNeedsHumanReview(boolean needsHumanReview) {
        this.needsHumanReview = needsHumanReview;
    }

    public ReviewStatus getReviewStatus() {
        return reviewStatus;
    }

    public void setReviewStatus(ReviewStatus reviewStatus) {
        this.reviewStatus = reviewStatus;
    }

    public User getReviewedBy() {
        return reviewedBy;
    }

    public void setReviewedBy(User reviewedBy) {
        this.reviewedBy = reviewedBy;
    }

    public Instant getReviewedAt() {
        return reviewedAt;
    }

    public void setReviewedAt(Instant reviewedAt) {
        this.reviewedAt = reviewedAt;
    }

    public String getReviewNotes() {
        return reviewNotes;
    }

    public void setReviewNotes(String reviewNotes) {
        this.reviewNotes = reviewNotes;
    }

    public Category getOverrideCategory() {
        return overrideCategory;
    }

    public void setOverrideCategory(Category overrideCategory) {
        this.overrideCategory = overrideCategory;
    }

    public Priority getOverridePriority() {
        return overridePriority;
    }

    public void setOverridePriority(Priority overridePriority) {
        this.overridePriority = overridePriority;
    }

    public String getOverrideDepartment() {
        return overrideDepartment;
    }

    public void setOverrideDepartment(String overrideDepartment) {
        this.overrideDepartment = overrideDepartment;
    }

    public boolean isCurrent() {
        return isCurrent;
    }

    public void setCurrent(boolean current) {
        isCurrent = current;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(Instant updatedAt) {
        this.updatedAt = updatedAt;
    }
}
