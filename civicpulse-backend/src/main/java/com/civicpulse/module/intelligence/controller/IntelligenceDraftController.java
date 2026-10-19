package com.civicpulse.module.intelligence.controller;

import com.civicpulse.common.dto.ApiResponse;
import com.civicpulse.module.intelligence.dto.AnalyzeDraftRequest;
import com.civicpulse.module.intelligence.dto.DraftAnalysisResponse;
import com.civicpulse.module.intelligence.service.IssueIntelligenceService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/intelligence")
@Tag(name = "Issue Intelligence Advisory", description = "Advisory intelligence suggestions for civic reports before submission")
public class IntelligenceDraftController {

    private final IssueIntelligenceService intelligenceService;

    public IntelligenceDraftController(IssueIntelligenceService intelligenceService) {
        this.intelligenceService = intelligenceService;
    }

    @PostMapping("/suggest")
    @Operation(summary = "Get suggestions for draft report", description = "Returns suggested category, priority, and routing advisory without persisting to an issue record")
    public ResponseEntity<ApiResponse<DraftAnalysisResponse>> suggestDraft(
            @Valid @RequestBody AnalyzeDraftRequest request
    ) {
        DraftAnalysisResponse response = intelligenceService.analyzeDraft(request);
        return ResponseEntity.ok(ApiResponse.success(response));
    }
}
