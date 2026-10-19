-- V003: Create wards table
CREATE TABLE wards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    code VARCHAR(20) NOT NULL UNIQUE,
    boundary GEOMETRY(POLYGON, 4326),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_wards_boundary ON wards USING GIST (boundary);
CREATE INDEX idx_wards_code ON wards(code);

-- Link users.ward_id to wards.id
ALTER TABLE users ADD CONSTRAINT fk_users_ward FOREIGN KEY (ward_id) REFERENCES wards(id) ON DELETE SET NULL;
CREATE INDEX idx_users_ward_id ON users(ward_id);
