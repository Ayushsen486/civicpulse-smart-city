package com.civicpulse.module.issue.repository;

import com.civicpulse.module.issue.entity.IssueAssignment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface IssueAssignmentRepository extends JpaRepository<IssueAssignment, UUID> {

    List<IssueAssignment> findAllByIssueIdOrderByAssignedAtDesc(UUID issueId);

    Optional<IssueAssignment> findFirstByIssueIdAndIsCurrentTrue(UUID issueId);
}
