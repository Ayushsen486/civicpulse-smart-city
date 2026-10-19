package com.civicpulse.module.category.service;

import com.civicpulse.common.exception.ConflictException;
import com.civicpulse.common.exception.ResourceNotFoundException;
import com.civicpulse.module.category.dto.CategoryResponse;
import com.civicpulse.module.category.dto.CreateCategoryRequest;
import com.civicpulse.module.category.entity.Category;
import com.civicpulse.module.category.entity.Priority;
import com.civicpulse.module.category.repository.CategoryRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CategoryServiceTest {

    @Mock
    private CategoryRepository categoryRepository;

    @InjectMocks
    private CategoryService categoryService;

    @Test
    @DisplayName("createCategory: successfully creates category")
    void createCategory_Success() {
        CreateCategoryRequest request = new CreateCategoryRequest(
                "Potholes",
                "potholes",
                "road",
                "#EF4444",
                Priority.HIGH,
                48,
                null,
                1
        );

        when(categoryRepository.existsBySlug("potholes")).thenReturn(false);
        when(categoryRepository.save(any(Category.class))).thenAnswer(invocation -> {
            Category c = invocation.getArgument(0);
            c.setId(UUID.randomUUID());
            return c;
        });

        CategoryResponse response = categoryService.createCategory(request);

        assertThat(response).isNotNull();
        assertThat(response.name()).isEqualTo("Potholes");
        assertThat(response.slug()).isEqualTo("potholes");
        assertThat(response.defaultPriority()).isEqualTo(Priority.HIGH);
        assertThat(response.slaHoursOverride()).isEqualTo(48);

        verify(categoryRepository).save(any(Category.class));
    }

    @Test
    @DisplayName("createCategory: throws ConflictException when slug already exists")
    void createCategory_DuplicateSlug_ThrowsConflict() {
        CreateCategoryRequest request = new CreateCategoryRequest(
                "Potholes",
                "potholes",
                "road",
                "#EF4444",
                Priority.HIGH,
                48,
                null,
                1
        );

        when(categoryRepository.existsBySlug("potholes")).thenReturn(true);

        assertThatThrownBy(() -> categoryService.createCategory(request))
                .isInstanceOf(ConflictException.class)
                .hasMessageContaining("already exists");

        verify(categoryRepository, never()).save(any(Category.class));
    }

    @Test
    @DisplayName("getCategoryById: throws ResourceNotFoundException when category not found")
    void getCategoryById_NotFound_ThrowsException() {
        UUID id = UUID.randomUUID();
        when(categoryRepository.findById(id)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> categoryService.getCategoryById(id))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Category not found");
    }

    @Test
    @DisplayName("getAllCategories: returns active categories list")
    void getAllCategories_Success() {
        Category cat = new Category();
        cat.setId(UUID.randomUUID());
        cat.setName("Roads");
        cat.setSlug("roads");

        when(categoryRepository.findAllByIsActiveTrueOrderBySortOrderAsc()).thenReturn(List.of(cat));

        List<CategoryResponse> list = categoryService.getAllCategories(false, true);

        assertThat(list).hasSize(1);
        assertThat(list.get(0).slug()).isEqualTo("roads");
    }
}
