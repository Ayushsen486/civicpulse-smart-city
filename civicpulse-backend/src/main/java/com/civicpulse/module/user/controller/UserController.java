package com.civicpulse.module.user.controller;

import com.civicpulse.common.dto.ApiResponse;
import com.civicpulse.common.dto.PageMeta;
import com.civicpulse.module.user.dto.CreateUserRequest;
import com.civicpulse.module.user.dto.UpdateProfileRequest;
import com.civicpulse.module.user.dto.UpdateUserRequest;
import com.civicpulse.module.user.dto.UserResponse;
import com.civicpulse.module.user.entity.UserRole;
import com.civicpulse.module.user.service.UserService;
import com.civicpulse.security.CustomUserDetails;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/users")
@Tag(name = "Users", description = "User profile and account administration endpoints")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping("/me")
    @Operation(summary = "Get current user profile", description = "Returns the profile of the currently authenticated user")
    public ResponseEntity<ApiResponse<UserResponse>> getCurrentUser(
            @AuthenticationPrincipal CustomUserDetails userDetails
    ) {
        UserResponse response = userService.getUserProfile(userDetails.getId());
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @PutMapping("/me")
    @Operation(summary = "Update current user profile", description = "Updates details of the currently authenticated user")
    public ResponseEntity<ApiResponse<UserResponse>> updateCurrentUser(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @Valid @RequestBody UpdateProfileRequest request
    ) {
        UserResponse response = userService.updateProfile(userDetails.getId(), request);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "List all users (Admin)", description = "Returns paginated user accounts with optional role filter")
    public ResponseEntity<ApiResponse<List<UserResponse>>> listUsers(
            @RequestParam(required = false) UserRole role,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable
    ) {
        Page<UserResponse> page = userService.getAllUsers(pageable, role);
        return ResponseEntity.ok(ApiResponse.success(page.getContent(), PageMeta.from(page)));
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Create user account (Admin)", description = "Creates a new officer, supervisor, or citizen user")
    public ResponseEntity<ApiResponse<UserResponse>> createUser(
            @Valid @RequestBody CreateUserRequest request
    ) {
        UserResponse response = userService.createUser(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(response));
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Get user by ID (Admin)", description = "Returns detailed profile of a specific user")
    public ResponseEntity<ApiResponse<UserResponse>> getUserById(
            @PathVariable UUID id
    ) {
        UserResponse response = userService.getUserById(id);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Update user (Admin)", description = "Updates roles, status, or details of a user")
    public ResponseEntity<ApiResponse<UserResponse>> updateUser(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateUserRequest request
    ) {
        UserResponse response = userService.updateUser(id, request);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Soft delete user (Admin)", description = "Marks a user as deleted and deactivates the account")
    public ResponseEntity<ApiResponse<Map<String, String>>> deleteUser(
            @PathVariable UUID id
    ) {
        userService.deleteUser(id);
        return ResponseEntity.ok(ApiResponse.success(Map.of("message", "User deleted successfully")));
    }

    @GetMapping("/officers")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'ADMIN')")
    @Operation(summary = "List officers (Supervisor/Admin)", description = "Returns paginated list of officers available for dispatch")
    public ResponseEntity<ApiResponse<List<UserResponse>>> listOfficers(
            @PageableDefault(size = 20, sort = "firstName", direction = Sort.Direction.ASC) Pageable pageable
    ) {
        Page<UserResponse> page = userService.getOfficers(pageable);
        return ResponseEntity.ok(ApiResponse.success(page.getContent(), PageMeta.from(page)));
    }
}
