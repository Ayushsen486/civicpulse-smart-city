package com.civicpulse.module.issue.service;

import com.civicpulse.common.exception.BadRequestException;
import com.civicpulse.common.exception.ForbiddenException;
import com.civicpulse.module.issue.entity.Issue;
import com.civicpulse.module.issue.entity.IssueStatus;
import com.civicpulse.module.issue.entity.TimelineEventType;
import com.civicpulse.module.user.entity.User;
import com.civicpulse.module.user.entity.UserRole;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.Map;
import java.util.Set;

@Component
public class IssueStateMachine {

    // Valid state transitions
    private static final Map<IssueStatus, Set<IssueStatus>> ALLOWED_TRANSITIONS = Map.ofEntries(
            Map.entry(IssueStatus.REPORTED, Set.of(IssueStatus.ACKNOWLEDGED, IssueStatus.ASSIGNED, IssueStatus.REJECTED, IssueStatus.DUPLICATE, IssueStatus.CANCELLED)),
            Map.entry(IssueStatus.PENDING, Set.of(IssueStatus.ACKNOWLEDGED, IssueStatus.ASSIGNED, IssueStatus.REJECTED, IssueStatus.DUPLICATE, IssueStatus.CANCELLED)),
            Map.entry(IssueStatus.ACKNOWLEDGED, Set.of(IssueStatus.ASSIGNED, IssueStatus.IN_PROGRESS, IssueStatus.REJECTED, IssueStatus.DUPLICATE, IssueStatus.CANCELLED)),
            Map.entry(IssueStatus.ASSIGNED, Set.of(IssueStatus.IN_PROGRESS, IssueStatus.ASSIGNED, IssueStatus.REJECTED, IssueStatus.CANCELLED)),
            Map.entry(IssueStatus.IN_PROGRESS, Set.of(IssueStatus.RESOLVED, IssueStatus.ASSIGNED, IssueStatus.REJECTED)),
            Map.entry(IssueStatus.RESOLVED, Set.of(IssueStatus.CLOSED, IssueStatus.REOPENED)),
            Map.entry(IssueStatus.REOPENED, Set.of(IssueStatus.ASSIGNED, IssueStatus.IN_PROGRESS, IssueStatus.RESOLVED)),
            Map.entry(IssueStatus.CLOSED, Set.of(IssueStatus.REOPENED)),
            Map.entry(IssueStatus.REJECTED, Set.of()),
            Map.entry(IssueStatus.DUPLICATE, Set.of()),
            Map.entry(IssueStatus.CANCELLED, Set.of())
    );

    public void validateTransition(Issue issue, IssueStatus targetStatus, User actor) {
        IssueStatus currentStatus = issue.getStatus();

        if (currentStatus == targetStatus) {
            return;
        }

        Set<IssueStatus> validTargets = ALLOWED_TRANSITIONS.getOrDefault(currentStatus, Set.of());
        if (!validTargets.contains(targetStatus)) {
            throw new BadRequestException(
                    "Invalid status transition from " + currentStatus + " to " + targetStatus
            );
        }

        UserRole role = actor.getRole();
        boolean isReporter = issue.getReporter() != null && issue.getReporter().getId().equals(actor.getId());
        boolean isAssignedOfficer = issue.getAssignedOfficer() != null && issue.getAssignedOfficer().getId().equals(actor.getId());

        // Enforce role-based permission on target status
        switch (targetStatus) {
            case ACKNOWLEDGED -> {
                if (role == UserRole.CITIZEN) {
                    throw new ForbiddenException("Citizens cannot acknowledge issues");
                }
            }
            case ASSIGNED -> {
                if (role != UserRole.SUPERVISOR && role != UserRole.ADMIN) {
                    throw new ForbiddenException("Only supervisors and admins can assign issues");
                }
            }
            case IN_PROGRESS -> {
                if (role == UserRole.CITIZEN) {
                    throw new ForbiddenException("Citizens cannot put issues in progress");
                }
                if (role == UserRole.OFFICER && !isAssignedOfficer) {
                    throw new ForbiddenException("Only the assigned officer can put this issue in progress");
                }
            }
            case RESOLVED -> {
                // AGENTS.md Task 3: Do not allow citizens to mark their own issues as resolved
                if (role == UserRole.CITIZEN) {
                    throw new ForbiddenException("Citizens cannot mark issues as resolved");
                }
                if (role == UserRole.OFFICER && !isAssignedOfficer) {
                    throw new ForbiddenException("Only the assigned officer can mark this issue as resolved");
                }
            }
            case CLOSED -> {
                // AGENTS.md Task 3: Do not allow citizens to mark their own issues as closed
                if (role == UserRole.CITIZEN) {
                    throw new ForbiddenException("Only supervisors and admins can close issues");
                }
            }
            case REOPENED -> {
                // Reporter citizen or supervisor/admin can reopen resolved issues
                if (role == UserRole.CITIZEN && !isReporter) {
                    throw new ForbiddenException("Only the original reporter or municipal authorities can reopen this issue");
                }
                if (role == UserRole.OFFICER) {
                    throw new ForbiddenException("Field officers cannot reopen issues");
                }
            }
            case REJECTED, DUPLICATE -> {
                if (role != UserRole.SUPERVISOR && role != UserRole.ADMIN) {
                    throw new ForbiddenException("Only supervisors and admins can reject or mark issues as duplicate");
                }
            }
            case CANCELLED -> {
                // Citizen can cancel their own report if still in REPORTED/PENDING
                if (role == UserRole.CITIZEN) {
                    if (!isReporter) {
                        throw new ForbiddenException("You cannot cancel another user's issue");
                    }
                    if (currentStatus != IssueStatus.REPORTED && currentStatus != IssueStatus.PENDING) {
                        throw new BadRequestException("Issue can only be cancelled while in REPORTED state");
                    }
                } else if (role != UserRole.SUPERVISOR && role != UserRole.ADMIN) {
                    throw new ForbiddenException("Insufficient permissions to cancel issue");
                }
            }
            default -> {
            }
        }
    }

    public TimelineEventType determineEventType(IssueStatus targetStatus) {
        return switch (targetStatus) {
            case RESOLVED -> TimelineEventType.RESOLVED;
            case CLOSED -> TimelineEventType.CLOSED;
            case REOPENED -> TimelineEventType.REOPENED;
            case REJECTED -> TimelineEventType.REJECTED;
            case DUPLICATE -> TimelineEventType.DUPLICATE_LINKED;
            default -> TimelineEventType.STATUS_CHANGED;
        };
    }
}
