package com.civicpulse.module.issue.entity;

public enum IssueStatus {
    REPORTED,
    ACKNOWLEDGED,
    ASSIGNED,
    IN_PROGRESS,
    RESOLVED,
    CLOSED,
    REOPENED,
    REJECTED,
    DUPLICATE,
    CANCELLED,
    PENDING, // Legacy alias for REPORTED
    DRAFT;

    public boolean isTerminal() {
        return this == CLOSED || this == REJECTED || this == DUPLICATE || this == CANCELLED;
    }
}
