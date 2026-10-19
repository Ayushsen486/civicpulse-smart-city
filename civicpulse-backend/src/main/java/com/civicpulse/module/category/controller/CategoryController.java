package com.civicpulse.module.category.controller;

import com.civicpulse.common.dto.ApiResponse;
import com.civicpulse.module.category.dto.CategoryResponse;
import com.civicpulse.module.category.dto.CreateCategoryRequest;
import com.civicpulse.module.category.dto.UpdateCategoryRequest;
import com.civicpulse.module.category.service.CategoryService;
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
@RequestMapping("/api/v1/categories")
@Tag(name = "Categories", description = "Civic issue categories and SLA configuration")
public class CategoryController {

    private final CategoryService categoryService;

    public CategoryController(CategoryService categoryService) {
        this.categoryService = categoryService;
    }

    @GetMapping
    @Operation(summary = "List categories", description = "Public endpoint returning active civic issue categories and their sub-categories")
    public ResponseEntity<ApiResponse<List<CategoryResponse>>> listCategories(
            @RequestParam(defaultValue = "false") boolean topLevelOnly,
            @RequestParam(defaultValue = "true") boolean activeOnly
    ) {
        List<CategoryResponse> categories = categoryService.getAllCategories(topLevelOnly, activeOnly);
        return ResponseEntity.ok(ApiResponse.success(categories));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get category by ID", description = "Public endpoint returning a specific category")
    public ResponseEntity<ApiResponse<CategoryResponse>> getCategoryById(
            @PathVariable UUID id
    ) {
        CategoryResponse response = categoryService.getCategoryById(id);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Create category (Admin)", description = "Adds a new category or sub-category to the platform")
    public ResponseEntity<ApiResponse<CategoryResponse>> createCategory(
            @Valid @RequestBody CreateCategoryRequest request
    ) {
        CategoryResponse response = categoryService.createCategory(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(response));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Update category (Admin)", description = "Modifies SLA, priority, naming, or hierarchy for a category")
    public ResponseEntity<ApiResponse<CategoryResponse>> updateCategory(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateCategoryRequest request
    ) {
        CategoryResponse response = categoryService.updateCategory(id, request);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Delete category (Admin)", description = "Deletes a category from the platform")
    public ResponseEntity<ApiResponse<Map<String, String>>> deleteCategory(
            @PathVariable UUID id
    ) {
        categoryService.deleteCategory(id);
        return ResponseEntity.ok(ApiResponse.success(Map.of("message", "Category deleted successfully")));
    }
}
