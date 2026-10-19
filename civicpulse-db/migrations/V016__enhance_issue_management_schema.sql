-- V016: Enhance issue management schema for Phase 2 lifecycle, attachments, and timeline
-- Compatible with PostgreSQL 16 + PostGIS 3.4

-- 1. Enhance issues status constraint and add lifecycle tracking fields
ALTER TABLE issues DROP CONSTRAINT IF EXISTS issues_status_check;
ALTER TABLE issues ADD CONSTRAINT issues_status_check CHECK (
    status IN ('REPORTED', 'ACKNOWLEDGED', 'ASSIGNED', 'IN_PROGRESS', 'RESOLVED', 'CLOSED', 'REOPENED', 'REJECTED', 'DUPLICATE', 'CANCELLED', 'PENDING', 'DRAFT')
);
ALTER TABLE issues ALTER COLUMN status SET DEFAULT 'REPORTED';

ALTER TABLE issues ADD COLUMN IF NOT EXISTS issue_reference VARCHAR(50) UNIQUE;
ALTER TABLE issues ADD COLUMN IF NOT EXISTS priority_score DOUBLE PRECISION NOT NULL DEFAULT 0.0;
ALTER TABLE issues ADD COLUMN IF NOT EXISTS reopened_at TIMESTAMPTZ;
ALTER TABLE issues ADD COLUMN IF NOT EXISTS reopened_by UUID;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_issues_reopened_by'
    ) THEN
        ALTER TABLE issues ADD CONSTRAINT fk_issues_reopened_by FOREIGN KEY (reopened_by) REFERENCES users(id) ON DELETE SET NULL;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_issues_reference ON issues(issue_reference);
CREATE INDEX IF NOT EXISTS idx_issues_created_at_desc ON issues(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_issues_status ON issues(status);
CREATE INDEX IF NOT EXISTS idx_issues_priority ON issues(priority);

-- 2. Enhance issue_attachments with storage abstraction and attachment type
ALTER TABLE issue_attachments ADD COLUMN IF NOT EXISTS attachment_type VARCHAR(20) NOT NULL DEFAULT 'REPORT' CHECK (attachment_type IN ('REPORT', 'BEFORE', 'AFTER', 'OTHER'));
ALTER TABLE issue_attachments ADD COLUMN IF NOT EXISTS storage_key VARCHAR(255);
ALTER TABLE issue_attachments ADD COLUMN IF NOT EXISTS mime_type VARCHAR(100);
ALTER TABLE issue_attachments ADD COLUMN IF NOT EXISTS original_filename VARCHAR(255);

CREATE INDEX IF NOT EXISTS idx_issue_attachments_type ON issue_attachments(attachment_type);

-- 3. Enhance issue_timeline_events with explicit remarks
ALTER TABLE issue_timeline_events ADD COLUMN IF NOT EXISTS remarks TEXT;
CREATE INDEX IF NOT EXISTS idx_issue_timeline_events_lookup ON issue_timeline_events(issue_id, created_at ASC);

-- 4. Enhance issue_comments with soft delete support
ALTER TABLE issue_comments ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
CREATE INDEX IF NOT EXISTS idx_issue_comments_lookup ON issue_comments(issue_id, created_at ASC) WHERE deleted_at IS NULL;
