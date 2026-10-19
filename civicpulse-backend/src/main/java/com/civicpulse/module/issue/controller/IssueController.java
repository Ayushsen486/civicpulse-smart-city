package com.civicpulse.module.issue.controller;

import com.civicpulse.common.dto.ApiResponse;
import com.civicpulse.common.dto.PageMeta;
import com.civicpulse.module.category.entity.Priority;
import com.civicpulse.module.issue.dto.*;
import com.civicpulse.module.issue.entity.AttachmentType;
import com.civicpulse.module.issue.entity.IssueStatus;
import com.civicpulse.module.issue.service.IssueService;
import com.civicpulse.security.CustomUserDetails;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/issues")
@Tag(name = "Issues", description = "Core civic issue reporting, geospatial discovery, and lifecycle management")
public class IssueController {

    private final IssueService issueService;

    public IssueController(IssueService issueService) {
        this.issueService = issueService;
    }

    @PostMapping
    @Operation(summary = "Report a new civic issue", description = "Submits a new issue with geolocation, category, and priority")
    public ResponseEntity<ApiResponse<IssueResponse>> createIssue(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @Valid @RequestBody CreateIssueRequest request
    ) {
        IssueResponse response = issueService.createIssue(request, userDetails.getId());
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(response));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get issue details", description = "Retrieves full details of a specific issue including attachments")
    public ResponseEntity<ApiResponse<IssueResponse>> getIssueById(
            @PathVariable UUID id,
            @AuthenticationPrincipal CustomUserDetails userDetails
    ) {
        UUID currentUserId = userDetails != null ? userDetails.getId() : null;
        IssueResponse response = issueService.getIssueById(id, currentUserId);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @GetMapping
    @Operation(summary = "List and filter issues", description = "Returns paginated list of issues with filtering by status, priority, category, ward, or reporter")
    public ResponseEntity<ApiResponse<List<IssueResponse>>> listIssues(
            @RequestParam(required = false) IssueStatus status,
            @RequestParam(required = false) Priority priority,
            @RequestParam(required = false) UUID categoryId,
            @RequestParam(required = false) UUID wardId,
            @RequestParam(required = false) UUID reporterId,
            @RequestParam(required = false) UUID officerId,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable
    ) {
        Page<IssueResponse> page = issueService.listIssues(status, priority, categoryId, wardId, reporterId, officerId, pageable);
        return ResponseEntity.ok(ApiResponse.success(page.getContent(), PageMeta.from(page)));
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update issue details", description = "Edits title, description, priority, or address of an issue")
    public ResponseEntity<ApiResponse<IssueResponse>> updateIssue(
            @PathVariable UUID id,
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @Valid @RequestBody UpdateIssueRequest request
    ) {
        IssueResponse response = issueService.updateIssue(id, request, userDetails.getId(), userDetails.getRole());
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @PatchMapping("/{id}/status")
    @Operation(summary = "Transition issue status", description = "Executes state machine status transition with audit recording")
    public ResponseEntity<ApiResponse<IssueResponse>> updateStatus(
            @PathVariable UUID id,
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @Valid @RequestBody UpdateStatusRequest request
    ) {
        IssueResponse response = issueService.updateStatus(id, request, userDetails.getId());
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @GetMapping("/nearby")
    @Operation(summary = "Discover nearby issues (PostGIS)", description = "Searches for civic issues within radius meters using PostGIS ST_DWithin")
    public ResponseEntity<ApiResponse<List<IssueResponse>>> getNearbyIssues(
            @RequestParam double lat,
            @RequestParam double lng,
            @RequestParam(defaultValue = "1000") double radius,
            @RequestParam(defaultValue = "20") int limit,
            @AuthenticationPrincipal CustomUserDetails userDetails
    ) {
        UUID currentUserId = userDetails != null ? userDetails.getId() : null;
        List<IssueResponse> nearby = issueService.getNearbyIssues(lat, lng, radius, limit, currentUserId);
        return ResponseEntity.ok(ApiResponse.success(nearby));
    }

    @PostMapping("/{id}/assign")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'ADMIN')")
    @Operation(summary = "Assign issue to officer", description = "Dispatches a field officer to resolve the issue")
    public ResponseEntity<ApiResponse<IssueResponse>> assignOfficer(
            @PathVariable UUID id,
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @Valid @RequestBody AssignIssueRequest request
    ) {
        IssueResponse response = issueService.assignOfficer(id, request, userDetails.getId());
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @PostMapping("/{id}/reassign")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'ADMIN')")
    @Operation(summary = "Reassign issue to officer", description = "Reassigns an in-flight issue to another field officer")
    public ResponseEntity<ApiResponse<IssueResponse>> reassignOfficer(
            @PathVariable UUID id,
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @Valid @RequestBody AssignIssueRequest request
    ) {
        IssueResponse response = issueService.assignOfficer(id, request, userDetails.getId());
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @GetMapping("/assigned-to-me")
    @PreAuthorize("hasRole('OFFICER')")
    @Operation(summary = "List issues assigned to authenticated officer", description = "Returns active queue of issues dispatched to the logged-in officer")
    public ResponseEntity<ApiResponse<List<IssueResponse>>> getAssignedToMe(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable
    ) {
        Page<IssueResponse> page = issueService.getAssignedToMe(userDetails.getId(), pageable);
        return ResponseEntity.ok(ApiResponse.success(page.getContent(), PageMeta.from(page)));
    }

    @GetMapping("/statistics")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'ADMIN', 'OFFICER')")
    @Operation(summary = "Get system-wide operational statistics", description = "Returns aggregated metrics on issues, SLA breaches, and officer workloads")
    public ResponseEntity<ApiResponse<IssueStatisticsResponse>> getStatistics() {
        IssueStatisticsResponse stats = issueService.getStatistics();
        return ResponseEntity.ok(ApiResponse.success(stats));
    }

    @GetMapping("/{id}/timeline")
    @Operation(summary = "Get issue timeline", description = "Retrieves complete chronological audit history of status changes and assignments")
    public ResponseEntity<ApiResponse<List<TimelineEventResponse>>> getTimeline(
            @PathVariable UUID id
    ) {
        List<TimelineEventResponse> timeline = issueService.getTimeline(id);
        return ResponseEntity.ok(ApiResponse.success(timeline));
    }

    @PostMapping("/{id}/upvote")
    @Operation(summary = "Upvote issue", description = "Adds citizen upvote to the issue")
    public ResponseEntity<ApiResponse<Map<String, String>>> upvoteIssue(
            @PathVariable UUID id,
            @AuthenticationPrincipal CustomUserDetails userDetails
    ) {
        issueService.upvoteIssue(id, userDetails.getId());
        return ResponseEntity.ok(ApiResponse.success(Map.of("message", "Upvoted successfully")));
    }

    @DeleteMapping("/{id}/upvote")
    @Operation(summary = "Remove upvote", description = "Removes citizen upvote from the issue")
    public ResponseEntity<ApiResponse<Map<String, String>>> removeUpvote(
            @PathVariable UUID id,
            @AuthenticationPrincipal CustomUserDetails userDetails
    ) {
        issueService.removeUpvote(id, userDetails.getId());
        return ResponseEntity.ok(ApiResponse.success(Map.of("message", "Upvote removed successfully")));
    }

    @PostMapping("/{id}/comments")
    @Operation(summary = "Add comment to issue", description = "Posts a public citizen comment or internal officer note")
    public ResponseEntity<ApiResponse<CommentResponse>> addComment(
            @PathVariable UUID id,
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @Valid @RequestBody CreateCommentRequest request
    ) {
        CommentResponse response = issueService.addComment(id, request, userDetails.getId());
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(response));
    }

    @GetMapping("/{id}/comments")
    @Operation(summary = "List comments", description = "Retrieves comments on the issue with visibility access rules")
    public ResponseEntity<ApiResponse<List<CommentResponse>>> getComments(
            @PathVariable UUID id,
            @AuthenticationPrincipal CustomUserDetails userDetails
    ) {
        List<CommentResponse> comments = issueService.getComments(id, userDetails.getRole());
        return ResponseEntity.ok(ApiResponse.success(comments));
    }

    @PostMapping(value = "/{id}/attachments", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "Upload photo/video attachment", description = "Uploads evidentiary media attachment with MIME verification")
    public ResponseEntity<ApiResponse<AttachmentResponse>> uploadAttachment(
            @PathVariable UUID id,
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "attachmentType", defaultValue = "REPORT") AttachmentType attachmentType,
            @RequestParam(value = "isBefore", defaultValue = "true") boolean isBefore
    ) {
        AttachmentResponse response = issueService.addAttachment(id, file, attachmentType, isBefore, userDetails.getId());
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(response));
    }

    @GetMapping("/{id}/attachments")
    @Operation(summary = "List attachments", description = "Returns all photographic and video evidence attachments for an issue")
    public ResponseEntity<ApiResponse<List<AttachmentResponse>>> getAttachments(
            @PathVariable UUID id
    ) {
        List<AttachmentResponse> attachments = issueService.getAttachments(id);
        return ResponseEntity.ok(ApiResponse.success(attachments));
    }
}
