package com.civicpulse.module.intelligence.repository;

import com.civicpulse.module.intelligence.entity.IssueRecommendation;
import com.civicpulse.module.intelligence.entity.ReviewStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface IssueRecommendationRepository extends JpaRepository<IssueRecommendation, UUID> {

    Optional<IssueRecommendation> findByIssueIdAndIsCurrentTrue(UUID issueId);

    List<IssueRecommendation> findAllByIssueIdOrderByCreatedAtDesc(UUID issueId);

    Page<IssueRecommendation> findAllByReviewStatus(ReviewStatus reviewStatus, Pageable pageable);

    List<IssueRecommendation> findAllByNeedsHumanReviewTrueOrderByCreatedAtDesc();

    @Modifying
    @Query("UPDATE IssueRecommendation r SET r.isCurrent = false WHERE r.issue.id = :issueId")
    int deactivatePreviousRecommendations(@Param("issueId") UUID issueId);
}
