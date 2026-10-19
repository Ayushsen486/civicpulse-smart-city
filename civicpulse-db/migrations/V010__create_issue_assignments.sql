-- V010: Create issue assignments table
CREATE TABLE issue_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    issue_id UUID NOT NULL,
    officer_id UUID NOT NULL,
    assigned_by UUID NOT NULL,
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    unassigned_at TIMESTAMPTZ,
    is_current BOOLEAN NOT NULL DEFAULT true,
    CONSTRAINT fk_assignments_issue FOREIGN KEY (issue_id) REFERENCES issues(id) ON DELETE CASCADE,
    CONSTRAINT fk_assignments_officer FOREIGN KEY (officer_id) REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT fk_assignments_assigned_by FOREIGN KEY (assigned_by) REFERENCES users(id) ON DELETE RESTRICT
);

CREATE INDEX idx_issue_assignments_issue_id ON issue_assignments(issue_id);
CREATE INDEX idx_issue_assignments_officer_id ON issue_assignments(officer_id);
CREATE INDEX idx_issue_assignments_assigned_by ON issue_assignments(assigned_by);
