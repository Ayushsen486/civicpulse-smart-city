package com.civicpulse.module.category.repository;

import com.civicpulse.module.category.entity.Category;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface CategoryRepository extends JpaRepository<Category, UUID> {

    Optional<Category> findBySlug(String slug);

    boolean existsBySlug(String slug);

    List<Category> findAllByParentIsNullAndIsActiveTrueOrderBySortOrderAsc();

    List<Category> findAllByParentIsNullOrderBySortOrderAsc();

    List<Category> findAllByParentIdAndIsActiveTrueOrderBySortOrderAsc(UUID parentId);

    List<Category> findAllByIsActiveTrueOrderBySortOrderAsc();

    List<Category> findAllByOrderBySortOrderAsc();
}
