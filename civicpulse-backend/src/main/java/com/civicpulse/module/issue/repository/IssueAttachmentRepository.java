package com.civicpulse.module.issue.repository;

import com.civicpulse.module.issue.entity.IssueAttachment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface IssueAttachmentRepository extends JpaRepository<IssueAttachment, UUID> {

    List<IssueAttachment> findAllByIssueIdOrderByCreatedAtAsc(UUID issueId);

    List<IssueAttachment> findAllByIssueIdAndIsBeforeTrue(UUID issueId);

    List<IssueAttachment> findAllByIssueIdAndIsBeforeFalse(UUID issueId);

    Optional<IssueAttachment> findByStorageKey(String storageKey);
}
