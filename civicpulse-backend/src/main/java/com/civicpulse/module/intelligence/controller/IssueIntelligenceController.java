package com.civicpulse.module.intelligence.controller;

import com.civicpulse.common.dto.ApiResponse;
import com.civicpulse.module.intelligence.dto.RecommendationResponse;
import com.civicpulse.module.intelligence.dto.ReviewRecommendationRequest;
import com.civicpulse.module.intelligence.service.IssueIntelligenceService;
import com.civicpulse.security.CustomUserDetails;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/issues/{id}/intelligence")
@Tag(name = "Issue Intelligence", description = "AI-powered civic issue categorization, priority evaluation, department routing, and staff review")
public class IssueIntelligenceController {

    private final IssueIntelligenceService intelligenceService;

    public IssueIntelligenceController(IssueIntelligenceService intelligenceService) {
        this.intelligenceService = intelligenceService;
    }

    @PostMapping("/analyze")
    @PreAuthorize("hasAnyRole('OFFICER', 'SUPERVISOR', 'ADMIN')")
    @Operation(summary = "Analyze issue with AI intelligence", description = "Executes category suggestion, priority assessment, and department routing for an existing issue")
    public ResponseEntity<ApiResponse<RecommendationResponse>> analyzeIssue(
            @PathVariable UUID id,
            @AuthenticationPrincipal CustomUserDetails userDetails
    ) {
        RecommendationResponse response = intelligenceService.analyzeIssue(id, userDetails.getId());
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @GetMapping
    @Operation(summary = "Get latest intelligence recommendation", description = "Retrieves the current intelligence recommendation for the issue. Citizens can only view recommendations for their own reports.")
    public ResponseEntity<ApiResponse<RecommendationResponse>> getLatestRecommendation(
            @PathVariable UUID id,
            @AuthenticationPrincipal CustomUserDetails userDetails
    ) {
        RecommendationResponse response = intelligenceService.getLatestRecommendation(id, userDetails.getId(), userDetails.getRole());
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @GetMapping("/history")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'ADMIN')")
    @Operation(summary = "Get recommendation history", description = "Retrieves audit history of all intelligence recommendations for an issue")
    public ResponseEntity<ApiResponse<List<RecommendationResponse>>> getRecommendationHistory(
            @PathVariable UUID id
    ) {
        List<RecommendationResponse> response = intelligenceService.getRecommendationHistory(id);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @PostMapping("/review")
    @PreAuthorize("hasAnyRole('OFFICER', 'SUPERVISOR', 'ADMIN')")
    @Operation(summary = "Review recommendation", description = "Accepts, rejects, or overrides an AI intelligence recommendation. Updates issue taxonomy and SLA if accepted.")
    public ResponseEntity<ApiResponse<RecommendationResponse>> reviewRecommendation(
            @PathVariable UUID id,
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @Valid @RequestBody ReviewRecommendationRequest request
    ) {
        RecommendationResponse response = intelligenceService.reviewRecommendation(id, request, userDetails.getId());
        return ResponseEntity.ok(ApiResponse.success(response));
    }
}
