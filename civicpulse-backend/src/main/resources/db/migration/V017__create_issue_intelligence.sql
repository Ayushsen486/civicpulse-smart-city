-- V017: Create issue intelligence recommendations and audit tables
-- Phase 3: AI-Powered Issue Intelligence

CREATE TABLE issue_intelligence_recommendations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    issue_id UUID NOT NULL,
    suggested_category_id UUID,
    suggested_priority VARCHAR(20) NOT NULL CHECK (suggested_priority IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    recommended_department VARCHAR(100) NOT NULL,
    category_confidence DOUBLE PRECISION NOT NULL,
    priority_confidence DOUBLE PRECISION NOT NULL,
    routing_confidence DOUBLE PRECISION NOT NULL,
    overall_confidence DOUBLE PRECISION NOT NULL,
    explanation TEXT NOT NULL,
    factors JSONB,
    provider_name VARCHAR(100) NOT NULL,
    provider_version VARCHAR(50) NOT NULL,
    needs_human_review BOOLEAN NOT NULL DEFAULT false,
    review_status VARCHAR(20) NOT NULL DEFAULT 'PENDING_REVIEW' CHECK (review_status IN ('PENDING_REVIEW', 'ACCEPTED', 'REJECTED', 'OVERRIDDEN')),
    reviewed_by UUID,
    reviewed_at TIMESTAMPTZ,
    review_notes TEXT,
    override_category_id UUID,
    override_priority VARCHAR(20) CHECK (override_priority IS NULL OR override_priority IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    override_department VARCHAR(100),
    is_current BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_intel_issue FOREIGN KEY (issue_id) REFERENCES issues(id) ON DELETE CASCADE,
    CONSTRAINT fk_intel_category FOREIGN KEY (suggested_category_id) REFERENCES categories(id) ON DELETE SET NULL,
    CONSTRAINT fk_intel_reviewer FOREIGN KEY (reviewed_by) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT fk_intel_override_category FOREIGN KEY (override_category_id) REFERENCES categories(id) ON DELETE SET NULL
);

CREATE INDEX idx_issue_intel_issue_id ON issue_intelligence_recommendations(issue_id);
CREATE INDEX idx_issue_intel_current ON issue_intelligence_recommendations(issue_id, is_current);
CREATE INDEX idx_issue_intel_review_status ON issue_intelligence_recommendations(review_status);
CREATE INDEX idx_issue_intel_needs_review ON issue_intelligence_recommendations(needs_human_review) WHERE needs_human_review IS TRUE;
CREATE INDEX idx_issue_intel_created_at ON issue_intelligence_recommendations(created_at DESC);
