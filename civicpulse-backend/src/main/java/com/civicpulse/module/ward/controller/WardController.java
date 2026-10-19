package com.civicpulse.module.ward.controller;

import com.civicpulse.common.dto.ApiResponse;
import com.civicpulse.module.ward.dto.CreateWardRequest;
import com.civicpulse.module.ward.dto.UpdateWardRequest;
import com.civicpulse.module.ward.dto.WardResponse;
import com.civicpulse.module.ward.service.WardService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/wards")
@Tag(name = "Wards", description = "Municipal ward boundaries and geographic jurisdiction")
public class WardController {

    private final WardService wardService;

    public WardController(WardService wardService) {
        this.wardService = wardService;
    }

    @GetMapping
    @Operation(summary = "List all wards", description = "Returns all administrative municipal wards")
    public ResponseEntity<ApiResponse<List<WardResponse>>> listWards() {
        List<WardResponse> wards = wardService.getAllWards();
        return ResponseEntity.ok(ApiResponse.success(wards));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get ward by ID", description = "Returns details and polygon boundary for a specific ward")
    public ResponseEntity<ApiResponse<WardResponse>> getWardById(
            @PathVariable UUID id
    ) {
        WardResponse response = wardService.getWardById(id);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @GetMapping("/lookup")
    @Operation(summary = "Spatial ward lookup by GPS coordinate", description = "Locates which municipal ward polygon contains the given latitude and longitude")
    public ResponseEntity<ApiResponse<WardResponse>> lookupWardByCoordinates(
            @RequestParam double lat,
            @RequestParam double lng
    ) {
        WardResponse response = wardService.findWardContainingPoint(lat, lng);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Create ward (Admin)", description = "Creates a new municipal ward with boundary polygon in WKT format")
    public ResponseEntity<ApiResponse<WardResponse>> createWard(
            @Valid @RequestBody CreateWardRequest request
    ) {
        WardResponse response = wardService.createWard(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(response));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Update ward (Admin)", description = "Updates ward name, code, or boundary polygon")
    public ResponseEntity<ApiResponse<WardResponse>> updateWard(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateWardRequest request
    ) {
        WardResponse response = wardService.updateWard(id, request);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Delete ward (Admin)", description = "Deletes a municipal ward")
    public ResponseEntity<ApiResponse<Map<String, String>>> deleteWard(
            @PathVariable UUID id
    ) {
        wardService.deleteWard(id);
        return ResponseEntity.ok(ApiResponse.success(Map.of("message", "Ward deleted successfully")));
    }
}
