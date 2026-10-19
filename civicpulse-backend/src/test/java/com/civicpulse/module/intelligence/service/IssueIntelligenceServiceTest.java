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
import com.civicpulse.module.issue.entity.IssueStatus;
import com.civicpulse.module.issue.repository.IssueRepository;
import com.civicpulse.module.issue.repository.IssueTimelineEventRepository;
import com.civicpulse.module.user.entity.User;
import com.civicpulse.module.user.entity.UserRole;
import com.civicpulse.module.user.repository.UserRepository;
import com.civicpulse.module.ward.entity.Ward;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.Point;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.util.*;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class IssueIntelligenceServiceTest {

    @Mock
    private IssueRecommendationRepository recommendationRepository;
    @Mock
    private IssueRepository issueRepository;
    @Mock
    private CategoryRepository categoryRepository;
    @Mock
    private UserRepository userRepository;
    @Mock
    private IssueTimelineEventRepository timelineEventRepository;
    @Mock
    private IssueIntelligenceProvider intelligenceProvider;
    @Spy
    private ObjectMapper objectMapper = new ObjectMapper();

    @InjectMocks
    private IssueIntelligenceService intelligenceService;

    private Issue testIssue;
    private User reporter;
    private User assignedOfficer;
    private User supervisor;
    private Category roadsCategory;
    private Category potholeCategory;
    private Ward testWard;
    private IssueRecommendation existingRecommendation;

    @BeforeEach
    void setUp() {
        reporter = new User();
        reporter.setId(UUID.randomUUID());
        reporter.setEmail("citizen@civicpulse.city");
        reporter.setFirstName("Rohan");
        reporter.setLastName("Sharma");
        reporter.setRole(UserRole.CITIZEN);

        assignedOfficer = new User();
        assignedOfficer.setId(UUID.randomUUID());
        assignedOfficer.setEmail("officer@civicpulse.city");
        assignedOfficer.setFirstName("Vikram");
        assignedOfficer.setLastName("Singh");
        assignedOfficer.setRole(UserRole.OFFICER);

        supervisor = new User();
        supervisor.setId(UUID.randomUUID());
        supervisor.setEmail("supervisor@civicpulse.city");
        supervisor.setFirstName("Anita");
        supervisor.setLastName("Desai");
        supervisor.setRole(UserRole.SUPERVISOR);

        roadsCategory = new Category();
        roadsCategory.setId(UUID.randomUUID());
        roadsCategory.setName("Roads & Traffic");
        roadsCategory.setSlug("roads-traffic");
        roadsCategory.setDefaultPriority(Priority.MEDIUM);

        potholeCategory = new Category();
        potholeCategory.setId(UUID.randomUUID());
        potholeCategory.setName("Potholes");
        potholeCategory.setSlug("potholes");
        potholeCategory.setDefaultPriority(Priority.HIGH);
        potholeCategory.setParent(roadsCategory);

        testWard = new Ward();
        testWard.setId(UUID.randomUUID());
        testWard.setCode("WARD-01");
        testWard.setName("Central Ward");

        GeometryFactory gf = new GeometryFactory();
        Point point = gf.createPoint(new Coordinate(77.21, 28.61));

        testIssue = new Issue();
        testIssue.setId(UUID.randomUUID());
        testIssue.setTitle("Deep crater on main street");
        testIssue.setDescription("Vehicle axle damage hazard near junction");
        testIssue.setStatus(IssueStatus.REPORTED);
        testIssue.setPriority(Priority.MEDIUM);
        testIssue.setPriorityScore(50.0);
        testIssue.setCategory(roadsCategory);
        testIssue.setReporter(reporter);
        testIssue.setAssignedOfficer(assignedOfficer);
        testIssue.setWard(testWard);
        testIssue.setLocation(point);

        existingRecommendation = new IssueRecommendation();
        existingRecommendation.setId(UUID.randomUUID());
        existingRecommendation.setIssue(testIssue);
        existingRecommendation.setSuggestedCategory(potholeCategory);
        existingRecommendation.setSuggestedPriority(Priority.HIGH);
        existingRecommendation.setRecommendedDepartment("Roads & Public Works Department (WARD-01)");
        existingRecommendation.setCategoryConfidence(0.90);
        existingRecommendation.setPriorityConfidence(0.85);
        existingRecommendation.setRoutingConfidence(0.90);
        existingRecommendation.setOverallConfidence(0.88);
        existingRecommendation.setExplanation("Categorized as Potholes based on keywords");
        existingRecommendation.setFactors("{\"categoryKeywords\":[\"crater\"]}");
        existingRecommendation.setProviderName("CivicPulse-RuleEngine");
        existingRecommendation.setProviderVersion("1.0.0");
        existingRecommendation.setNeedsHumanReview(false);
        existingRecommendation.setReviewStatus(ReviewStatus.PENDING_REVIEW);
        existingRecommendation.setCurrent(true);
    }

    @Test
    @DisplayName("Should analyze draft report advisory without persisting records")
    void shouldAnalyzeDraftSuccessfully() {
        AnalyzeDraftRequest request = new AnalyzeDraftRequest("Pothole on ring road", "Damaged asphalt");
        when(categoryRepository.findAllByIsActiveTrueOrderBySortOrderAsc()).thenReturn(List.of(roadsCategory, potholeCategory));

        IssueAnalysisResult mockResult = new IssueAnalysisResult(
                potholeCategory.getId(),
                potholeCategory.getName(),
                Priority.HIGH,
                "Roads & Public Works Department",
                0.90, 0.85, 0.90, 0.88,
                "Explanation",
                Map.of(),
                false,
                "CivicPulse-RuleEngine",
                "1.0.0"
        );
        when(intelligenceProvider.analyze(any(IssueAnalysisContext.class))).thenReturn(mockResult);

        DraftAnalysisResponse response = intelligenceService.analyzeDraft(request);

        assertThat(response.suggestedCategoryName()).isEqualTo("Potholes");
        assertThat(response.suggestedPriority()).isEqualTo(Priority.HIGH);
        verifyNoInteractions(recommendationRepository);
    }

    @Test
    @DisplayName("Should analyze issue, deactivate previous recommendations, and persist new recommendation")
    void shouldAnalyzeIssueAndPersistRecommendation() {
        when(issueRepository.findById(testIssue.getId())).thenReturn(Optional.of(testIssue));
        when(categoryRepository.findAllByIsActiveTrueOrderBySortOrderAsc()).thenReturn(List.of(roadsCategory, potholeCategory));

        IssueAnalysisResult mockResult = new IssueAnalysisResult(
                potholeCategory.getId(),
                potholeCategory.getName(),
                Priority.HIGH,
                "Roads & Public Works Department (WARD-01)",
                0.90, 0.85, 0.90, 0.88,
                "Categorized as Potholes",
                Map.of("categoryKeywords", List.of("crater")),
                false,
                "CivicPulse-RuleEngine",
                "1.0.0"
        );
        when(intelligenceProvider.analyze(any(IssueAnalysisContext.class))).thenReturn(mockResult);
        when(categoryRepository.findById(potholeCategory.getId())).thenReturn(Optional.of(potholeCategory));
        when(recommendationRepository.save(any(IssueRecommendation.class))).thenAnswer(invocation -> invocation.getArgument(0));

        RecommendationResponse response = intelligenceService.analyzeIssue(testIssue.getId(), reporter.getId());

        assertThat(response.suggestedCategoryName()).isEqualTo("Potholes");
        assertThat(response.suggestedPriority()).isEqualTo(Priority.HIGH);
        assertThat(response.isCurrent()).isTrue();

        verify(recommendationRepository).deactivatePreviousRecommendations(testIssue.getId());
        verify(recommendationRepository).save(any(IssueRecommendation.class));
        verify(timelineEventRepository).save(any());
    }

    @Test
    @DisplayName("Should handle provider failure gracefully and throw BadRequestException without corruption")
    void shouldHandleProviderFailureGracefully() {
        when(issueRepository.findById(testIssue.getId())).thenReturn(Optional.of(testIssue));
        when(categoryRepository.findAllByIsActiveTrueOrderBySortOrderAsc()).thenReturn(List.of(roadsCategory));
        when(intelligenceProvider.analyze(any())).thenThrow(new RuntimeException("Inference timeout"));
        when(intelligenceProvider.getProviderName()).thenReturn("CivicPulse-RuleEngine");

        assertThatThrownBy(() -> intelligenceService.analyzeIssue(testIssue.getId(), reporter.getId()))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("Issue intelligence analysis failed");

        verify(recommendationRepository, never()).save(any());
    }

    @Test
    @DisplayName("Should allow citizen to view own report recommendation with internal notes redacted")
    void shouldAllowCitizenToViewOwnReportRecommendationWithoutInternalNotes() {
        existingRecommendation.setReviewNotes("Internal triage: verify if contractor was penalized");
        existingRecommendation.setReviewedBy(supervisor);

        when(issueRepository.findById(testIssue.getId())).thenReturn(Optional.of(testIssue));
        when(recommendationRepository.findByIssueIdAndIsCurrentTrue(testIssue.getId())).thenReturn(Optional.of(existingRecommendation));

        RecommendationResponse response = intelligenceService.getLatestRecommendation(testIssue.getId(), reporter.getId(), UserRole.CITIZEN);

        assertThat(response.suggestedCategoryName()).isEqualTo("Potholes");
        assertThat(response.reviewNotes()).isNull(); // Redacted for citizen
        assertThat(response.reviewedByName()).isNull(); // Redacted for citizen
    }

    @Test
    @DisplayName("Should prevent citizen from viewing recommendation for another user's issue")
    void shouldPreventCitizenFromViewingOtherCitizenRecommendation() {
        UUID strangerId = UUID.randomUUID();
        when(issueRepository.findById(testIssue.getId())).thenReturn(Optional.of(testIssue));

        assertThatThrownBy(() -> intelligenceService.getLatestRecommendation(testIssue.getId(), strangerId, UserRole.CITIZEN))
                .isInstanceOf(ForbiddenException.class)
                .hasMessageContaining("Citizens can only view intelligence recommendations for their own reported issues");
    }

    @Test
    @DisplayName("Should allow assigned field officer to ACCEPT recommendation and update issue")
    void shouldAllowAssignedOfficerToAcceptRecommendationAndApplyToIssue() {
        when(issueRepository.findById(testIssue.getId())).thenReturn(Optional.of(testIssue));
        when(recommendationRepository.findByIssueIdAndIsCurrentTrue(testIssue.getId())).thenReturn(Optional.of(existingRecommendation));
        when(userRepository.findByIdAndDeletedAtIsNull(assignedOfficer.getId())).thenReturn(Optional.of(assignedOfficer));
        when(recommendationRepository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        ReviewRecommendationRequest request = new ReviewRecommendationRequest(
                ReviewAction.ACCEPT,
                "Verified by field officer",
                null, null, null, true
        );

        RecommendationResponse response = intelligenceService.reviewRecommendation(testIssue.getId(), request, assignedOfficer.getId());

        assertThat(response.reviewStatus()).isEqualTo(ReviewStatus.ACCEPTED);
        assertThat(testIssue.getCategory()).isEqualTo(potholeCategory);
        assertThat(testIssue.getPriority()).isEqualTo(Priority.HIGH);
        verify(issueRepository).save(testIssue);
        verify(timelineEventRepository, atLeastOnce()).save(any());
    }

    @Test
    @DisplayName("Should prevent unassigned officer from reviewing recommendation")
    void shouldPreventUnassignedOfficerFromReviewingRecommendation() {
        User otherOfficer = new User();
        otherOfficer.setId(UUID.randomUUID());
        otherOfficer.setRole(UserRole.OFFICER);

        when(issueRepository.findById(testIssue.getId())).thenReturn(Optional.of(testIssue));
        when(recommendationRepository.findByIssueIdAndIsCurrentTrue(testIssue.getId())).thenReturn(Optional.of(existingRecommendation));
        when(userRepository.findByIdAndDeletedAtIsNull(otherOfficer.getId())).thenReturn(Optional.of(otherOfficer));

        ReviewRecommendationRequest request = new ReviewRecommendationRequest(
                ReviewAction.ACCEPT, "Note", null, null, null, true
        );

        assertThatThrownBy(() -> intelligenceService.reviewRecommendation(testIssue.getId(), request, otherOfficer.getId()))
                .isInstanceOf(ForbiddenException.class)
                .hasMessageContaining("Field officers can only review recommendations for issues assigned to them");
    }

    @Test
    @DisplayName("Should allow supervisor to OVERRIDE recommendation with custom category and priority")
    void shouldAllowSupervisorToOverrideRecommendation() {
        when(issueRepository.findById(testIssue.getId())).thenReturn(Optional.of(testIssue));
        when(recommendationRepository.findByIssueIdAndIsCurrentTrue(testIssue.getId())).thenReturn(Optional.of(existingRecommendation));
        when(userRepository.findByIdAndDeletedAtIsNull(supervisor.getId())).thenReturn(Optional.of(supervisor));
        when(recommendationRepository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        ReviewRecommendationRequest request = new ReviewRecommendationRequest(
                ReviewAction.OVERRIDE,
                "Escalated due to impending VIP movement",
                null,
                Priority.CRITICAL,
                "Disaster Management Team",
                true
        );

        RecommendationResponse response = intelligenceService.reviewRecommendation(testIssue.getId(), request, supervisor.getId());

        assertThat(response.reviewStatus()).isEqualTo(ReviewStatus.OVERRIDDEN);
        assertThat(response.overridePriority()).isEqualTo(Priority.CRITICAL);
        assertThat(testIssue.getPriority()).isEqualTo(Priority.CRITICAL);
        verify(issueRepository).save(testIssue);
    }

    @Test
    @DisplayName("Should allow supervisor to REJECT recommendation without altering issue attributes")
    void shouldAllowSupervisorToRejectRecommendationWithoutModifyingIssue() {
        when(issueRepository.findById(testIssue.getId())).thenReturn(Optional.of(testIssue));
        when(recommendationRepository.findByIssueIdAndIsCurrentTrue(testIssue.getId())).thenReturn(Optional.of(existingRecommendation));
        when(userRepository.findByIdAndDeletedAtIsNull(supervisor.getId())).thenReturn(Optional.of(supervisor));
        when(recommendationRepository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        ReviewRecommendationRequest request = new ReviewRecommendationRequest(
                ReviewAction.REJECT,
                "Incorrect classification",
                null, null, null, false
        );

        RecommendationResponse response = intelligenceService.reviewRecommendation(testIssue.getId(), request, supervisor.getId());

        assertThat(response.reviewStatus()).isEqualTo(ReviewStatus.REJECTED);
        // Original issue category and priority untouched
        assertThat(testIssue.getCategory()).isEqualTo(roadsCategory);
        assertThat(testIssue.getPriority()).isEqualTo(Priority.MEDIUM);
        verify(issueRepository, never()).save(testIssue);
    }
}
