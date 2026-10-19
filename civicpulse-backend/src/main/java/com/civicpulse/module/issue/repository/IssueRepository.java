package com.civicpulse.module.issue.repository;

import com.civicpulse.module.category.entity.Priority;
import com.civicpulse.module.issue.entity.Issue;
import com.civicpulse.module.issue.entity.IssueStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface IssueRepository extends JpaRepository<Issue, UUID>, JpaSpecificationExecutor<Issue> {

    Optional<Issue> findByIdAndDeletedAtIsNull(UUID id);

    Optional<Issue> findByIssueReferenceAndDeletedAtIsNull(String issueReference);

    Page<Issue> findAllByDeletedAtIsNull(Pageable pageable);

    Page<Issue> findAllByReporterIdAndDeletedAtIsNull(UUID reporterId, Pageable pageable);

    Page<Issue> findAllByAssignedOfficerIdAndDeletedAtIsNull(UUID officerId, Pageable pageable);

    long countByAssignedOfficerIdAndStatusInAndDeletedAtIsNull(UUID officerId, Collection<IssueStatus> statuses);

    long countByDeletedAtIsNull();

    long countByStatusAndDeletedAtIsNull(IssueStatus status);

    long countByPriorityAndDeletedAtIsNull(Priority priority);

    long countBySlaDeadlineBeforeAndStatusNotInAndDeletedAtIsNull(Instant deadline, Collection<IssueStatus> statuses);

    @Query(value = """
        SELECT * FROM issues i
        WHERE i.deleted_at IS NULL
          AND ST_DWithin(i.location::geography, ST_SetSRID(ST_MakePoint(:longitude, :latitude), 4326)::geography, :radiusMeters)
        ORDER BY ST_Distance(i.location::geography, ST_SetSRID(ST_MakePoint(:longitude, :latitude), 4326)::geography) ASC
        LIMIT :limit
        """, nativeQuery = true)
    List<Issue> findNearbyIssues(
            @Param("latitude") double latitude,
            @Param("longitude") double longitude,
            @Param("radiusMeters") double radiusMeters,
            @Param("limit") int limit
    );

    @Query(value = """
        SELECT * FROM issues i
        WHERE i.deleted_at IS NULL
          AND i.category_id = :categoryId
          AND i.id != :excludeIssueId
          AND ST_DWithin(i.location::geography, ST_SetSRID(ST_MakePoint(:longitude, :latitude), 4326)::geography, :radiusMeters)
        ORDER BY ST_Distance(i.location::geography, ST_SetSRID(ST_MakePoint(:longitude, :latitude), 4326)::geography) ASC
        LIMIT 10
        """, nativeQuery = true)
    List<Issue> findPotentialDuplicates(
            @Param("categoryId") UUID categoryId,
            @Param("excludeIssueId") UUID excludeIssueId,
            @Param("latitude") double latitude,
            @Param("longitude") double longitude,
            @Param("radiusMeters") double radiusMeters
    );

    // Cursor pagination support
    List<Issue> findByDeletedAtIsNullAndCreatedAtLessThanOrderByCreatedAtDesc(Instant cursorCreatedAt, Pageable pageable);
}
