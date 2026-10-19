package com.civicpulse.module.issue.service;

import com.civicpulse.common.exception.BadRequestException;
import com.civicpulse.common.exception.ForbiddenException;
import com.civicpulse.module.issue.entity.Issue;
import com.civicpulse.module.issue.entity.IssueStatus;
import com.civicpulse.module.user.entity.User;
import com.civicpulse.module.user.entity.UserRole;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class IssueStateMachineTest {

    private IssueStateMachine stateMachine;
    private User reporter;
    private User assignedOfficer;
    private User unassignedOfficer;
    private User supervisor;
    private Issue issue;

    @BeforeEach
    void setUp() {
        stateMachine = new IssueStateMachine();

        reporter = new User();
        reporter.setId(UUID.randomUUID());
        reporter.setRole(UserRole.CITIZEN);

        assignedOfficer = new User();
        assignedOfficer.setId(UUID.randomUUID());
        assignedOfficer.setRole(UserRole.OFFICER);

        unassignedOfficer = new User();
        unassignedOfficer.setId(UUID.randomUUID());
        unassignedOfficer.setRole(UserRole.OFFICER);

        supervisor = new User();
        supervisor.setId(UUID.randomUUID());
        supervisor.setRole(UserRole.SUPERVISOR);

        issue = new Issue();
        issue.setId(UUID.randomUUID());
        issue.setStatus(IssueStatus.REPORTED);
        issue.setReporter(reporter);
        issue.setAssignedOfficer(assignedOfficer);
    }

    @Test
    @DisplayName("REPORTED -> ACKNOWLEDGED: allowed for supervisor or officer")
    void transition_ReportedToAcknowledged_Success() {
        assertThatCode(() -> stateMachine.validateTransition(issue, IssueStatus.ACKNOWLEDGED, supervisor))
                .doesNotThrowAnyException();
    }

    @Test
    @DisplayName("REPORTED -> ACKNOWLEDGED: rejected for citizen")
    void transition_ReportedToAcknowledged_CitizenForbidden() {
        assertThatThrownBy(() -> stateMachine.validateTransition(issue, IssueStatus.ACKNOWLEDGED, reporter))
                .isInstanceOf(ForbiddenException.class)
                .hasMessageContaining("Citizens cannot acknowledge issues");
    }

    @Test
    @DisplayName("IN_PROGRESS -> RESOLVED: allowed for assigned officer")
    void transition_InProgressToResolved_AssignedOfficer_Success() {
        issue.setStatus(IssueStatus.IN_PROGRESS);

        assertThatCode(() -> stateMachine.validateTransition(issue, IssueStatus.RESOLVED, assignedOfficer))
                .doesNotThrowAnyException();
    }

    @Test
    @DisplayName("IN_PROGRESS -> RESOLVED: forbidden for unassigned officer")
    void transition_InProgressToResolved_UnassignedOfficer_Forbidden() {
        issue.setStatus(IssueStatus.IN_PROGRESS);

        assertThatThrownBy(() -> stateMachine.validateTransition(issue, IssueStatus.RESOLVED, unassignedOfficer))
                .isInstanceOf(ForbiddenException.class)
                .hasMessageContaining("Only the assigned officer can mark this issue as resolved");
    }

    @Test
    @DisplayName("IN_PROGRESS -> RESOLVED: forbidden for citizen (Task 3 constraint)")
    void transition_InProgressToResolved_CitizenForbidden() {
        issue.setStatus(IssueStatus.IN_PROGRESS);

        assertThatThrownBy(() -> stateMachine.validateTransition(issue, IssueStatus.RESOLVED, reporter))
                .isInstanceOf(ForbiddenException.class)
                .hasMessageContaining("Citizens cannot mark issues as resolved");
    }

    @Test
    @DisplayName("RESOLVED -> CLOSED: forbidden for citizen, allowed for supervisor")
    void transition_ResolvedToClosed_RoleEnforced() {
        issue.setStatus(IssueStatus.RESOLVED);

        assertThatThrownBy(() -> stateMachine.validateTransition(issue, IssueStatus.CLOSED, reporter))
                .isInstanceOf(ForbiddenException.class)
                .hasMessageContaining("Only supervisors and admins can close issues");

        assertThatCode(() -> stateMachine.validateTransition(issue, IssueStatus.CLOSED, supervisor))
                .doesNotThrowAnyException();
    }

    @Test
    @DisplayName("RESOLVED -> REOPENED: allowed for original reporter citizen")
    void transition_ResolvedToReopened_Reporter_Success() {
        issue.setStatus(IssueStatus.RESOLVED);

        assertThatCode(() -> stateMachine.validateTransition(issue, IssueStatus.REOPENED, reporter))
                .doesNotThrowAnyException();
    }

    @Test
    @DisplayName("RESOLVED -> REOPENED: forbidden for other non-reporter citizen")
    void transition_ResolvedToReopened_OtherCitizen_Forbidden() {
        issue.setStatus(IssueStatus.RESOLVED);
        User otherCitizen = new User();
        otherCitizen.setId(UUID.randomUUID());
        otherCitizen.setRole(UserRole.CITIZEN);

        assertThatThrownBy(() -> stateMachine.validateTransition(issue, IssueStatus.REOPENED, otherCitizen))
                .isInstanceOf(ForbiddenException.class)
                .hasMessageContaining("Only the original reporter or municipal authorities can reopen this issue");
    }

    @Test
    @DisplayName("Illegal transition jump: REPORTED -> RESOLVED throws BadRequestException")
    void transition_IllegalJump_ThrowsBadRequest() {
        assertThatThrownBy(() -> stateMachine.validateTransition(issue, IssueStatus.RESOLVED, supervisor))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("Invalid status transition from REPORTED to RESOLVED");
    }

    @Test
    @DisplayName("Terminal state: REJECTED cannot transition to any status")
    void transition_FromTerminalState_ThrowsBadRequest() {
        issue.setStatus(IssueStatus.REJECTED);

        assertThatThrownBy(() -> stateMachine.validateTransition(issue, IssueStatus.IN_PROGRESS, supervisor))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("Invalid status transition from REJECTED to IN_PROGRESS");
    }
}
