package com.civicpulse.module.intelligence.controller;

import com.civicpulse.common.exception.GlobalExceptionHandler;
import com.civicpulse.module.category.entity.Priority;
import com.civicpulse.module.intelligence.dto.*;
import com.civicpulse.module.intelligence.entity.ReviewStatus;
import com.civicpulse.module.intelligence.service.IssueIntelligenceService;
import com.civicpulse.module.user.entity.User;
import com.civicpulse.module.user.entity.UserRole;
import com.civicpulse.security.CustomUserDetails;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.core.MethodParameter;
import org.springframework.http.MediaType;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.bind.support.WebDataBinderFactory;
import org.springframework.web.context.request.NativeWebRequest;
import org.springframework.web.method.support.HandlerMethodArgumentResolver;
import org.springframework.web.method.support.ModelAndViewContainer;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ExtendWith(MockitoExtension.class)
class IssueIntelligenceControllerTest {

    private MockMvc mockMvc;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Mock
    private IssueIntelligenceService intelligenceService;

    @InjectMocks
    private IssueIntelligenceController intelligenceController;

    private IntelligenceDraftController draftController;
    private CustomUserDetails mockUserDetails;
    private RecommendationResponse mockRecommendation;

    @BeforeEach
    void setUp() {
        draftController = new IntelligenceDraftController(intelligenceService);

        User officer = new User();
        officer.setId(UUID.randomUUID());
        officer.setEmail("officer@civicpulse.city");
        officer.setPasswordHash("hash");
        officer.setRole(UserRole.OFFICER);
        officer.setActive(true);
        mockUserDetails = new CustomUserDetails(officer);

        mockRecommendation = new RecommendationResponse(
                UUID.randomUUID(),
                UUID.randomUUID(),
                UUID.randomUUID(),
                "Potholes",
                Priority.HIGH,
                "Roads & Public Works Department (WARD-01)",
                0.90,
                0.85,
                0.90,
                0.88,
                "Categorized as Potholes based on keywords",
                Map.of("categoryKeywords", List.of("crater")),
                "CivicPulse-RuleEngine",
                "1.0.0",
                false,
                ReviewStatus.PENDING_REVIEW,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                true,
                Instant.now(),
                Instant.now()
        );

        HandlerMethodArgumentResolver authPrincipalResolver = new HandlerMethodArgumentResolver() {
            @Override
            public boolean supportsParameter(MethodParameter parameter) {
                return parameter.hasParameterAnnotation(AuthenticationPrincipal.class);
            }

            @Override
            public Object resolveArgument(MethodParameter parameter, ModelAndViewContainer mavContainer, NativeWebRequest webRequest, WebDataBinderFactory binderFactory) {
                return mockUserDetails;
            }
        };

        mockMvc = MockMvcBuilders
                .standaloneSetup(intelligenceController, draftController)
                .setCustomArgumentResolvers(authPrincipalResolver)
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();
    }

    @Test
    @DisplayName("POST /api/v1/intelligence/suggest should return advisory suggestions for draft")
    void shouldSuggestDraft() throws Exception {
        AnalyzeDraftRequest request = new AnalyzeDraftRequest("Pothole on street", "Large crater");
        DraftAnalysisResponse response = new DraftAnalysisResponse(
                UUID.randomUUID(), "Potholes", Priority.HIGH,
                "Roads & Public Works Department", 0.90, 0.85, 0.88, "Explanation", false
        );

        when(intelligenceService.analyzeDraft(any())).thenReturn(response);

        mockMvc.perform(post("/api/v1/intelligence/suggest")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.suggestedCategoryName").value("Potholes"))
                .andExpect(jsonPath("$.data.suggestedPriority").value("HIGH"))
                .andExpect(jsonPath("$.data.recommendedDepartment").value("Roads & Public Works Department"));
    }

    @Test
    @DisplayName("POST /api/v1/issues/{id}/intelligence/analyze should trigger issue analysis")
    void shouldAnalyzeExistingIssue() throws Exception {
        UUID issueId = mockRecommendation.issueId();
        when(intelligenceService.analyzeIssue(eq(issueId), eq(mockUserDetails.getId()))).thenReturn(mockRecommendation);

        mockMvc.perform(post("/api/v1/issues/{id}/intelligence/analyze", issueId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value(mockRecommendation.id().toString()))
                .andExpect(jsonPath("$.data.suggestedCategoryName").value("Potholes"))
                .andExpect(jsonPath("$.data.providerName").value("CivicPulse-RuleEngine"));
    }

    @Test
    @DisplayName("GET /api/v1/issues/{id}/intelligence should retrieve latest recommendation")
    void shouldGetLatestRecommendation() throws Exception {
        UUID issueId = mockRecommendation.issueId();
        when(intelligenceService.getLatestRecommendation(eq(issueId), eq(mockUserDetails.getId()), eq(mockUserDetails.getRole())))
                .thenReturn(mockRecommendation);

        mockMvc.perform(get("/api/v1/issues/{id}/intelligence", issueId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.suggestedCategoryName").value("Potholes"))
                .andExpect(jsonPath("$.data.reviewStatus").value("PENDING_REVIEW"));
    }

    @Test
    @DisplayName("GET /api/v1/issues/{id}/intelligence/history should retrieve recommendation history")
    void shouldGetRecommendationHistory() throws Exception {
        UUID issueId = mockRecommendation.issueId();
        when(intelligenceService.getRecommendationHistory(eq(issueId))).thenReturn(List.of(mockRecommendation));

        mockMvc.perform(get("/api/v1/issues/{id}/intelligence/history", issueId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].id").value(mockRecommendation.id().toString()));
    }

    @Test
    @DisplayName("POST /api/v1/issues/{id}/intelligence/review should review recommendation")
    void shouldReviewRecommendation() throws Exception {
        UUID issueId = mockRecommendation.issueId();
        ReviewRecommendationRequest request = new ReviewRecommendationRequest(
                ReviewAction.ACCEPT,
                "Reviewed and confirmed",
                null, null, null, true
        );

        RecommendationResponse accepted = new RecommendationResponse(
                mockRecommendation.id(),
                mockRecommendation.issueId(),
                mockRecommendation.suggestedCategoryId(),
                mockRecommendation.suggestedCategoryName(),
                mockRecommendation.suggestedPriority(),
                mockRecommendation.recommendedDepartment(),
                mockRecommendation.categoryConfidence(),
                mockRecommendation.priorityConfidence(),
                mockRecommendation.routingConfidence(),
                mockRecommendation.overallConfidence(),
                mockRecommendation.explanation(),
                mockRecommendation.factors(),
                mockRecommendation.providerName(),
                mockRecommendation.providerVersion(),
                false,
                ReviewStatus.ACCEPTED,
                mockUserDetails.getId(),
                "Vikram Singh",
                Instant.now(),
                "Reviewed and confirmed",
                null, null, null, null,
                true,
                Instant.now(),
                Instant.now()
        );

        when(intelligenceService.reviewRecommendation(eq(issueId), any(), eq(mockUserDetails.getId()))).thenReturn(accepted);

        mockMvc.perform(post("/api/v1/issues/{id}/intelligence/review", issueId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.reviewStatus").value("ACCEPTED"))
                .andExpect(jsonPath("$.data.reviewedByName").value("Vikram Singh"));
    }

    @Test
    @DisplayName("POST /api/v1/issues/{id}/intelligence/review should reject null review action with 400")
    void shouldRejectInvalidReviewRequest() throws Exception {
        UUID issueId = mockRecommendation.issueId();
        String invalidJson = "{\"action\": null}";

        mockMvc.perform(post("/api/v1/issues/{id}/intelligence/review", issueId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(invalidJson))
                .andExpect(status().isBadRequest());
    }
}
