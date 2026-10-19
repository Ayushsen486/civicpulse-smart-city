package com.civicpulse.module.category.service;

import com.civicpulse.common.exception.ConflictException;
import com.civicpulse.common.exception.ResourceNotFoundException;
import com.civicpulse.module.category.dto.CategoryResponse;
import com.civicpulse.module.category.dto.CreateCategoryRequest;
import com.civicpulse.module.category.dto.UpdateCategoryRequest;
import com.civicpulse.module.category.entity.Category;
import com.civicpulse.module.category.entity.Priority;
import com.civicpulse.module.category.repository.CategoryRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
public class CategoryService {

    private final CategoryRepository categoryRepository;

    public CategoryService(CategoryRepository categoryRepository) {
        this.categoryRepository = categoryRepository;
    }

    @Transactional(readOnly = true)
    public List<CategoryResponse> getAllCategories(boolean topLevelOnly, boolean activeOnly) {
        List<Category> categories;
        if (topLevelOnly) {
            categories = activeOnly
                    ? categoryRepository.findAllByParentIsNullAndIsActiveTrueOrderBySortOrderAsc()
                    : categoryRepository.findAllByParentIsNullOrderBySortOrderAsc();
        } else {
            categories = activeOnly
                    ? categoryRepository.findAllByIsActiveTrueOrderBySortOrderAsc()
                    : categoryRepository.findAllByOrderBySortOrderAsc();
        }

        return categories.stream()
                .map(CategoryResponse::fromEntity)
                .toList();
    }

    @Transactional(readOnly = true)
    public CategoryResponse getCategoryById(UUID id) {
        Category category = findCategoryById(id);
        return CategoryResponse.fromEntity(category);
    }

    @Transactional
    public CategoryResponse createCategory(CreateCategoryRequest request) {
        String cleanSlug = request.slug().trim().toLowerCase();
        if (categoryRepository.existsBySlug(cleanSlug)) {
            throw new ConflictException("Category with slug '" + cleanSlug + "' already exists");
        }

        Category category = new Category();
        category.setName(request.name().trim());
        category.setSlug(cleanSlug);
        category.setIcon(request.icon() != null ? request.icon().trim() : null);
        category.setColor(request.color() != null ? request.color().trim() : null);
        category.setDefaultPriority(request.defaultPriority() != null ? request.defaultPriority() : Priority.MEDIUM);
        category.setSlaHoursOverride(request.slaHoursOverride());
        category.setSortOrder(request.sortOrder() != null ? request.sortOrder() : 0);
        category.setActive(true);

        if (request.parentId() != null) {
            Category parent = findCategoryById(request.parentId());
            category.setParent(parent);
        }

        Category saved = categoryRepository.save(category);
        return CategoryResponse.fromEntity(saved);
    }

    @Transactional
    public CategoryResponse updateCategory(UUID id, UpdateCategoryRequest request) {
        Category category = findCategoryById(id);

        if (request.slug() != null && !request.slug().isBlank()) {
            String cleanSlug = request.slug().trim().toLowerCase();
            if (!cleanSlug.equals(category.getSlug()) && categoryRepository.existsBySlug(cleanSlug)) {
                throw new ConflictException("Category with slug '" + cleanSlug + "' already exists");
            }
            category.setSlug(cleanSlug);
        }

        if (request.name() != null && !request.name().isBlank()) {
            category.setName(request.name().trim());
        }
        if (request.icon() != null) {
            category.setIcon(request.icon().trim());
        }
        if (request.color() != null) {
            category.setColor(request.color().trim());
        }
        if (request.defaultPriority() != null) {
            category.setDefaultPriority(request.defaultPriority());
        }
        if (request.slaHoursOverride() != null) {
            category.setSlaHoursOverride(request.slaHoursOverride());
        }
        if (request.isActive() != null) {
            category.setActive(request.isActive());
        }
        if (request.sortOrder() != null) {
            category.setSortOrder(request.sortOrder());
        }
        if (request.parentId() != null) {
            if (request.parentId().equals(category.getId())) {
                throw new ConflictException("A category cannot be its own parent");
            }
            Category parent = findCategoryById(request.parentId());
            category.setParent(parent);
        }

        Category updated = categoryRepository.save(category);
        return CategoryResponse.fromEntity(updated);
    }

    @Transactional
    public void deleteCategory(UUID id) {
        Category category = findCategoryById(id);
        categoryRepository.delete(category);
    }

    private Category findCategoryById(UUID id) {
        return categoryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Category not found with id: " + id));
    }
}
