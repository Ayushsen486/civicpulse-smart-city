package com.civicpulse.module.issue.repository;

import com.civicpulse.module.issue.entity.IssueUpvote;
import com.civicpulse.module.issue.entity.IssueUpvoteId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface IssueUpvoteRepository extends JpaRepository<IssueUpvote, IssueUpvoteId> {

    boolean existsByIdIssueIdAndIdUserId(UUID issueId, UUID userId);

    void deleteByIdIssueIdAndIdUserId(UUID issueId, UUID userId);

    long countByIdIssueId(UUID issueId);
}
