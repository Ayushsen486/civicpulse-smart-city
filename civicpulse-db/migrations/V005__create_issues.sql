-- V005: Create issues table
CREATE TABLE issues (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    issue_number SERIAL UNIQUE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('DRAFT', 'PENDING', 'ASSIGNED', 'IN_PROGRESS', 'RESOLVED', 'CLOSED', 'REOPENED', 'CANCELLED')),
    priority VARCHAR(20) NOT NULL DEFAULT 'MEDIUM' CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    category_id UUID NOT NULL,
    reporter_id UUID NOT NULL,
    assigned_officer_id UUID,
    ward_id UUID,
    location GEOMETRY(POINT, 4326) NOT NULL,
    address TEXT,
    landmark VARCHAR(255),
    upvote_count INTEGER NOT NULL DEFAULT 0,
    comment_count INTEGER NOT NULL DEFAULT 0,
    sla_deadline TIMESTAMPTZ,
    sla_breached BOOLEAN NOT NULL DEFAULT false,
    is_duplicate BOOLEAN NOT NULL DEFAULT false,
    parent_issue_id UUID,
    resolved_at TIMESTAMPTZ,
    closed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    CONSTRAINT fk_issues_category FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE RESTRICT,
    CONSTRAINT fk_issues_reporter FOREIGN KEY (reporter_id) REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT fk_issues_officer FOREIGN KEY (assigned_officer_id) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT fk_issues_ward FOREIGN KEY (ward_id) REFERENCES wards(id) ON DELETE SET NULL,
    CONSTRAINT fk_issues_parent FOREIGN KEY (parent_issue_id) REFERENCES issues(id) ON DELETE SET NULL
);

CREATE INDEX idx_issues_location ON issues USING GIST (location);
CREATE INDEX idx_issues_status_priority ON issues (status, priority);
CREATE INDEX idx_issues_category_id ON issues (category_id);
CREATE INDEX idx_issues_reporter_id ON issues (reporter_id);
CREATE INDEX idx_issues_assigned_officer_id ON issues (assigned_officer_id);
CREATE INDEX idx_issues_ward_id ON issues (ward_id);
CREATE INDEX idx_issues_parent_issue_id ON issues (parent_issue_id);
CREATE INDEX idx_issues_sla ON issues (sla_breached, sla_deadline) WHERE deleted_at IS NULL;
CREATE INDEX idx_issues_deleted_at ON issues (deleted_at);
