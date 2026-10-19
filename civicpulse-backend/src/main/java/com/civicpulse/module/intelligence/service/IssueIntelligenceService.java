package com.civicpulse.module.intelligence.service;

import com.civicpulse.common.exception.BadRequestException;
import com.civicpulse.common.exception.ForbiddenException;
import com.civicpulse.common.exception.ResourceNotFoundException;
import com.civicpulse.module.category.entity.Category;
import com.civicpulse.module.category.entity.Priority;
import com.civicpulse.module.category.repository.CategoryRepository;
import com.civicpulse.module.intelligence.dto.*;
import com.civicpulse.module.intelligence.entity.IssueRecommendation;
import com.civicpulse.module.intelligence.entity.ReviewStatus;
import com.civicpulse.module.intelligence.provider.IssueAnalysisContext;
import com.civicpulse.module.intelligence.provider.IssueAnalysisResult;
import com.civicpulse.module.intelligence.provider.IssueIntelligenceProvider;
import com.civicpulse.module.intelligence.repository.IssueRecommendationRepository;
import com.civicpulse.module.issue.entity.Issue;
import com.civicpulse.module.issue.entity.IssueTimelineEvent;
import com.civicpulse.module.issue.entity.TimelineEventType;
import com.civicpulse.module.issue.repository.IssueRepository;
import com.civicpulse.module.issue.repository.IssueTimelineEventRepository;
import com.civicpulse.module.user.entity.User;
import com.civicpulse.module.user.entity.UserRole;
import com.civicpulse.module.user.repository.UserRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
public class IssueIntelligenceService {

    private static final Logger log = LoggerFactory.getLogger(IssueIntelligenceService.class);

    private final IssueRecommendationRepository recommendationRepository;
    private final IssueRepository issueRepository;
    private final CategoryRepository categoryRepository;
    private final UserRepository userRepository;
    private final IssueTimelineEventRepository timelineEventRepository;
    private final IssueIntelligenceProvider intelligenceProvider;
    private final ObjectMapper objectMapper;

    public IssueIntelligenceService(
            IssueRecommendationRepository recommendationRepository,
            IssueRepository issueRepository,
            CategoryRepository categoryRepository,
            UserRepository userRepository,
            IssueTimelineEventRepository timelineEventRepository,
            IssueIntelligenceProvider intelligenceProvider,
            ObjectMapper objectMapper
    ) {
        this.recommendationRepository = recommendationRepository;
        this.issueRepository = issueRepository;
        this.categoryRepository = categoryRepository;
        this.userRepository = userRepository;
        this.timelineEventRepository = timelineEventRepository;
        this.intelligenceProvider = intelligenceProvider;
        this.objectMapper = objectMapper;
    }

    /**
     * Pre-submission draft suggestion for citizens or call centers.
     * Non-persisted fast advisory check.
     */
    @Transactional(readOnly = true)
    public DraftAnalysisResponse analyzeDraft(AnalyzeDraftRequest request) {
        List<Category> activeCategories = categoryRepository.findAllByIsActiveTrueOrderBySortOrderAsc();
        IssueAnalysisContext context = IssueAnalysisContext.ofDraft(request.title(), request.description(), activeCategories);

        IssueAnalysisResult result = intelligenceProvider.analyze(context);
        return DraftAnalysisResponse.fromResult(result);
    }

    /**
     * Executes intelligence analysis on an existing issue and persists a new recommendation.
     * Supersedes previous current recommendations for the same issue.
     */
    @Transactional
    public RecommendationResponse analyzeIssue(UUID issueId, UUID requesterId) {
        Issue issue = findActiveIssue(issueId);

        List<Category> availableCategories = categoryRepository.findAllByIsActiveTrueOrderBySortOrderAsc();

        String wardName = issue.getWard() != null ? issue.getWard().getName() : null;
        String wardCode = issue.getWard() != null ? issue.getWard().getCode() : null;
        Double latitude = issue.getLocation() != null ? issue.getLocation().getY() : null;
        Double longitude = issue.getLocation() != null ? issue.getLocation().getX() : null;

        IssueAnalysisContext context = new IssueAnalysisContext(
                issue.getTitle(),
                issue.getDescription(),
                issue.getCategory() != null ? issue.getCategory().getId() : null,
                issue.getCategory() != null ? issue.getCategory().getSlug() : null,
                issue.getPriority(),
                wardName,
                wardCode,
                latitude,
                longitude,
                availableCategories
        );

        IssueAnalysisResult result;
        try {
            result = intelligenceProvider.analyze(context);
        } catch (Exception e) {
            log.error("Intelligence provider [{}] failed for issue {}", intelligenceProvider.getProviderName(), issueId, e);
            throw new BadRequestException("Issue intelligence analysis failed: " + e.getMessage());
        }

        // Deactivate previous active recommendations to prevent duplicate current records
        recommendationRepository.deactivatePreviousRecommendations(issueId);

        // Map suggested category entity if returned
        Category suggestedCategory = null;
        if (result.suggestedCategoryId() != null) {
            suggestedCategory = categoryRepository.findById(result.suggestedCategoryId()).orElse(null);
        }

        String factorsJson = null;
        try {
            factorsJson = objectMapper.writeValueAsString(result.factors());
        } catch (Exception e) {
            log.warn("Could not serialize factors for issue {}: {}", issueId, e.getMessage());
        }

        IssueRecommendation recommendation = new IssueRecommendation();
        recommendation.setIssue(issue);
        recommendation.setSuggestedCategory(suggestedCategory);
        recommendation.setSuggestedPriority(result.suggestedPriority());
        recommendation.setRecommendedDepartment(result.recommendedDepartment());
        recommendation.setCategoryConfidence(result.categoryConfidence());
        recommendation.setPriorityConfidence(result.priorityConfidence());
        recommendation.setRoutingConfidence(result.routingConfidence());
        recommendation.setOverallConfidence(result.overallConfidence());
        recommendation.setExplanation(result.explanation());
        recommendation.setFactors(factorsJson);
        recommendation.setProviderName(result.providerName());
        recommendation.setProviderVersion(result.providerVersion());
        recommendation.setNeedsHumanReview(result.needsHumanReview());
        recommendation.setReviewStatus(ReviewStatus.PENDING_REVIEW);
        recommendation.setCurrent(true);

        IssueRecommendation saved = recommendationRepository.save(recommendation);

        // Record timeline event
        User requester = requesterId != null ? userRepository.findById(requesterId).orElse(null) : null;
        recordTimeline(
                issue,
                requester,
                TimelineEventType.DETAILS_UPDATED,
                null,
                "INTELLIGENCE_ANALYZED",
                "Automated issue intelligence analysis completed by " + result.providerName() + " (Confidence: " + result.overallConfidence() + ")"
        );

        return RecommendationResponse.fromEntity(saved, objectMapper);
    }

    /**
     * Non-blocking silent analysis called during issue creation.
     */
    @Transactional
    public void analyzeSilently(Issue issue) {
        try {
            analyzeIssue(issue.getId(), null);
        } catch (Exception e) {
            log.warn("Non-blocking intelligence analysis skipped for issue {}: {}", issue.getId(), e.getMessage());
        }
    }

    /**
     * Retrieves the latest active recommendation for an issue.
     */
    @Transactional(readOnly = true)
    public RecommendationResponse getLatestRecommendation(UUID issueId, UUID requesterId, UserRole requesterRole) {
        Issue issue = findActiveIssue(issueId);

        // Check citizen visibility
        if (requesterRole == UserRole.CITIZEN) {
            if (!issue.getReporter().getId().equals(requesterId)) {
                throw new ForbiddenException("Citizens can only view intelligence recommendations for their own reported issues");
            }
        }

        IssueRecommendation recommendation = recommendationRepository.findByIssueIdAndIsCurrentTrue(issueId)
                .orElseThrow(() -> new ResourceNotFoundException("No active intelligence recommendation found for issue: " + issueId));

        RecommendationResponse response = RecommendationResponse.fromEntity(recommendation, objectMapper);

        // Citizens must not view internal review notes or sensitive reviewer details
        if (requesterRole == UserRole.CITIZEN) {
            return new RecommendationResponse(
                    response.id(),
                    response.issueId(),
                    response.suggestedCategoryId(),
                    response.suggestedCategoryName(),
                    response.suggestedPriority(),
                    response.recommendedDepartment(),
                    response.categoryConfidence(),
                    response.priorityConfidence(),
                    response.routingConfidence(),
                    response.overallConfidence(),
                    response.explanation(),
                    response.factors(),
                    response.providerName(),
                    response.providerVersion(),
                    response.needsHumanReview(),
                    response.reviewStatus(),
                    null, // Redacted reviewer ID
                    null, // Redacted reviewer name
                    response.reviewedAt(),
                    null, // Redacted review notes
                    null,
                    null,
                    null,
                    null,
                    response.isCurrent(),
                    response.createdAt(),
                    response.updatedAt()
            );
        }

        return response;
    }

    /**
     * Retrieves recommendation history for an issue (restricted to staff).
     */
    @Transactional(readOnly = true)
    public List<RecommendationResponse> getRecommendationHistory(UUID issueId) {
        findActiveIssue(issueId);
        return recommendationRepository.findAllByIssueIdOrderByCreatedAtDesc(issueId).stream()
                .map(r -> RecommendationResponse.fromEntity(r, objectMapper))
                .toList();
    }

    /**
     * Reviews, accepts, rejects, or overrides a recommendation.
     */
    @Transactional
    public RecommendationResponse reviewRecommendation(UUID issueId, ReviewRecommendationRequest request, UUID reviewerId) {
        Issue issue = findActiveIssue(issueId);

        IssueRecommendation recommendation = recommendationRepository.findByIssueIdAndIsCurrentTrue(issueId)
                .orElseThrow(() -> new ResourceNotFoundException("No active recommendation to review for issue: " + issueId));

        User reviewer = userRepository.findByIdAndDeletedAtIsNull(reviewerId)
                .orElseThrow(() -> new ResourceNotFoundException("Reviewer not found: " + reviewerId));

        // Authorization check: Officer must be assigned or user must be Supervisor/Admin
        if (reviewer.getRole() == UserRole.OFFICER) {
            if (issue.getAssignedOfficer() == null || !issue.getAssignedOfficer().getId().equals(reviewerId)) {
                throw new ForbiddenException("Field officers can only review recommendations for issues assigned to them");
            }
        } else if (reviewer.getRole() != UserRole.SUPERVISOR && reviewer.getRole() != UserRole.ADMIN) {
            throw new ForbiddenException("Citizens are not authorized to review issue intelligence recommendations");
        }

        recommendation.setReviewedBy(reviewer);
        recommendation.setReviewedAt(Instant.now());
        recommendation.setReviewNotes(request.reviewNotes());

        switch (request.action()) {
            case ACCEPT -> {
                recommendation.setReviewStatus(ReviewStatus.ACCEPTED);
                if (request.shouldApplyToIssue()) {
                    applyRecommendationToIssue(issue, recommendation.getSuggestedCategory(), recommendation.getSuggestedPriority(), reviewer);
                }
                recordTimeline(
                        issue,
                        reviewer,
                        TimelineEventType.DETAILS_UPDATED,
                        ReviewStatus.PENDING_REVIEW.name(),
                        ReviewStatus.ACCEPTED.name(),
                        "Intelligence recommendation ACCEPTED by " + reviewer.getRole() + " (" + reviewer.getEmail() + ")"
                );
            }
            case REJECT -> {
                recommendation.setReviewStatus(ReviewStatus.REJECTED);
                recordTimeline(
                        issue,
                        reviewer,
                        TimelineEventType.DETAILS_UPDATED,
                        ReviewStatus.PENDING_REVIEW.name(),
                        ReviewStatus.REJECTED.name(),
                        "Intelligence recommendation REJECTED. Notes: " + (request.reviewNotes() != null ? request.reviewNotes() : "None")
                );
            }
            case OVERRIDE -> {
                recommendation.setReviewStatus(ReviewStatus.OVERRIDDEN);

                Category overrideCategory = null;
                if (request.overrideCategoryId() != null) {
                    overrideCategory = categoryRepository.findById(request.overrideCategoryId())
                            .orElseThrow(() -> new ResourceNotFoundException("Override category not found: " + request.overrideCategoryId()));
                    recommendation.setOverrideCategory(overrideCategory);
                }

                if (request.overridePriority() != null) {
                    recommendation.setOverridePriority(request.overridePriority());
                }

                if (request.overrideDepartment() != null) {
                    recommendation.setOverrideDepartment(request.overrideDepartment());
                }

                if (request.shouldApplyToIssue()) {
                    Category targetCategory = overrideCategory != null ? overrideCategory : issue.getCategory();
                    Priority targetPriority = request.overridePriority() != null ? request.overridePriority() : issue.getPriority();
                    applyRecommendationToIssue(issue, targetCategory, targetPriority, reviewer);
                }

                recordTimeline(
                        issue,
                        reviewer,
                        TimelineEventType.DETAILS_UPDATED,
                        ReviewStatus.PENDING_REVIEW.name(),
                        ReviewStatus.OVERRIDDEN.name(),
                        "Intelligence recommendation OVERRIDDEN by " + reviewer.getRole() + " (" + reviewer.getEmail() + ")"
                );
            }
        }

        IssueRecommendation updated = recommendationRepository.save(recommendation);
        return RecommendationResponse.fromEntity(updated, objectMapper);
    }

    private void applyRecommendationToIssue(Issue issue, Category newCategory, Priority newPriority, User actor) {
        boolean changed = false;

        if (newCategory != null && !newCategory.getId().equals(issue.getCategory().getId())) {
            Category oldCategory = issue.getCategory();
            issue.setCategory(newCategory);
            // Recalculate SLA based on new category
            int slaHours = newCategory.getSlaHoursOverride() != null ? newCategory.getSlaHoursOverride() : 72;
            issue.setSlaDeadline(Instant.now().plus(slaHours, ChronoUnit.HOURS));
            changed = true;

            recordTimeline(
                    issue,
                    actor,
                    TimelineEventType.DETAILS_UPDATED,
                    oldCategory.getName(),
                    newCategory.getName(),
                    "Category updated via intelligence recommendation review"
            );
        }

        if (newPriority != null && newPriority != issue.getPriority()) {
            Priority oldPriority = issue.getPriority();
            issue.setPriority(newPriority);
            issue.setPriorityScore(computePriorityScore(newPriority));
            changed = true;

            recordTimeline(
                    issue,
                    actor,
                    TimelineEventType.PRIORITY_CHANGED,
                    oldPriority.name(),
                    newPriority.name(),
                    "Priority updated via intelligence recommendation review"
            );
        }

        if (changed) {
            issueRepository.save(issue);
        }
    }

    private double computePriorityScore(Priority priority) {
        return switch (priority) {
            case CRITICAL -> 90.0;
            case HIGH -> 70.0;
            case MEDIUM -> 50.0;
            case LOW -> 30.0;
        };
    }

    private Issue findActiveIssue(UUID issueId) {
        return issueRepository.findById(issueId)
                .filter(i -> i.getDeletedAt() == null)
                .orElseThrow(() -> new ResourceNotFoundException("Active issue not found: " + issueId));
    }

    private void recordTimeline(Issue issue, User actor, TimelineEventType type, String oldVal, String newVal, String remarks) {
        IssueTimelineEvent event = new IssueTimelineEvent();
        event.setIssue(issue);
        event.setActor(actor);
        event.setEventType(type);
        event.setOldValue(oldVal);
        event.setNewValue(newVal);
        event.setRemarks(remarks);
        timelineEventRepository.save(event);
    }
}
