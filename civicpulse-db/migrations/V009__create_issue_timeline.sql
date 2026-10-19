-- V009: Create issue timeline events table
CREATE TABLE issue_timeline_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    issue_id UUID NOT NULL,
    actor_id UUID,
    event_type VARCHAR(50) NOT NULL,
    old_value VARCHAR(255),
    new_value VARCHAR(255),
    metadata JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_timeline_issue FOREIGN KEY (issue_id) REFERENCES issues(id) ON DELETE CASCADE,
    CONSTRAINT fk_timeline_actor FOREIGN KEY (actor_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX idx_issue_timeline_issue_id ON issue_timeline_events(issue_id);
CREATE INDEX idx_issue_timeline_actor_id ON issue_timeline_events(actor_id);
CREATE INDEX idx_issue_timeline_created_at ON issue_timeline_events(created_at);
