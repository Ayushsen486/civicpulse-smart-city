-- V008: Create issue upvotes junction table
CREATE TABLE issue_upvotes (
    issue_id UUID NOT NULL,
    user_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (issue_id, user_id),
    CONSTRAINT fk_upvotes_issue FOREIGN KEY (issue_id) REFERENCES issues(id) ON DELETE CASCADE,
    CONSTRAINT fk_upvotes_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_issue_upvotes_user_id ON issue_upvotes(user_id);
