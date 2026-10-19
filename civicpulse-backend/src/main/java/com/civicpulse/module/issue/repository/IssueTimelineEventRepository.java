package com.civicpulse.module.issue.repository;

import com.civicpulse.module.issue.entity.IssueTimelineEvent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface IssueTimelineEventRepository extends JpaRepository<IssueTimelineEvent, UUID> {

    List<IssueTimelineEvent> findAllByIssueIdOrderByCreatedAtAsc(UUID issueId);
}
