-- V015: Seed initial data (Admin user, Default categories, Sample wards)

-- 1. Sample Wards
INSERT INTO wards (id, name, code, boundary, created_at, updated_at)
VALUES
    ('a0000000-0000-0000-0000-000000000001', 'Central Ward', 'WARD-01',
     ST_GeomFromText('POLYGON((77.200 28.600, 77.220 28.600, 77.220 28.620, 77.200 28.620, 77.200 28.600))', 4326),
     NOW(), NOW()),
    ('a0000000-0000-0000-0000-000000000002', 'North Ward', 'WARD-02',
     ST_GeomFromText('POLYGON((77.200 28.620, 77.220 28.620, 77.220 28.640, 77.200 28.640, 77.200 28.620))', 4326),
     NOW(), NOW()),
    ('a0000000-0000-0000-0000-000000000003', 'South Ward', 'WARD-03',
     ST_GeomFromText('POLYGON((77.200 28.580, 77.220 28.580, 77.220 28.600, 77.200 28.600, 77.200 28.580))', 4326),
     NOW(), NOW()),
    ('a0000000-0000-0000-0000-000000000004', 'East Ward', 'WARD-04',
     ST_GeomFromText('POLYGON((77.220 28.600, 77.240 28.600, 77.240 28.620, 77.220 28.620, 77.220 28.600))', 4326),
     NOW(), NOW()),
    ('a0000000-0000-0000-0000-000000000005', 'West Ward', 'WARD-05',
     ST_GeomFromText('POLYGON((77.180 28.600, 77.200 28.600, 77.200 28.620, 77.180 28.620, 77.180 28.600))', 4326),
     NOW(), NOW())
ON CONFLICT (code) DO NOTHING;

-- 2. Seed Admin User (password: Admin@12345, bcrypt cost factor 12)
INSERT INTO users (
    id, email, phone, password_hash, first_name, last_name,
    role, avatar_url, is_active, is_phone_verified, is_email_verified,
    ward_id, created_at, updated_at
)
VALUES (
    'b0000000-0000-0000-0000-000000000001',
    'admin@civicpulse.org',
    '+919876543210',
    crypt('Admin@12345', gen_salt('bf', 12)),
    'System',
    'Administrator',
    'ADMIN',
    NULL,
    true,
    true,
    true,
    'a0000000-0000-0000-0000-000000000001',
    NOW(),
    NOW()
)
ON CONFLICT (email) DO NOTHING;

-- 3. Top-Level Categories
INSERT INTO categories (id, name, slug, icon, color, default_priority, sla_hours_override, is_active, parent_id, sort_order, created_at, updated_at)
VALUES
    ('c0000000-0000-0000-0000-000000000001', 'Roads & Traffic', 'roads-traffic', 'road', '#E65100', 'HIGH', 48, true, NULL, 1, NOW(), NOW()),
    ('c0000000-0000-0000-0000-000000000002', 'Sanitation & Waste', 'sanitation-waste', 'trash-2', '#2E7D32', 'MEDIUM', 24, true, NULL, 2, NOW(), NOW()),
    ('c0000000-0000-0000-0000-000000000003', 'Water Supply', 'water-supply', 'droplet', '#0277BD', 'CRITICAL', 12, true, NULL, 3, NOW(), NOW()),
    ('c0000000-0000-0000-0000-000000000004', 'Street Lighting', 'street-lighting', 'lightbulb', '#F57F17', 'MEDIUM', 36, true, NULL, 4, NOW(), NOW()),
    ('c0000000-0000-0000-0000-000000000005', 'Public Parks', 'public-parks', 'trees', '#558B2F', 'LOW', 72, true, NULL, 5, NOW(), NOW())
ON CONFLICT (slug) DO NOTHING;

-- 4. Sub-Categories
INSERT INTO categories (id, name, slug, icon, color, default_priority, sla_hours_override, is_active, parent_id, sort_order, created_at, updated_at)
VALUES
    ('c0000000-0000-0000-0000-000000000011', 'Potholes', 'potholes', 'circle-alert', '#E65100', 'HIGH', 48, true, 'c0000000-0000-0000-0000-000000000001', 1, NOW(), NOW()),
    ('c0000000-0000-0000-0000-000000000012', 'Broken Footpath', 'broken-footpath', 'footprints', '#E65100', 'MEDIUM', 72, true, 'c0000000-0000-0000-0000-000000000001', 2, NOW(), NOW()),
    ('c0000000-0000-0000-0000-000000000021', 'Garbage Dump', 'garbage-dump', 'trash', '#2E7D32', 'HIGH', 24, true, 'c0000000-0000-0000-0000-000000000002', 1, NOW(), NOW()),
    ('c0000000-0000-0000-0000-000000000022', 'Drain Blockage', 'drain-blockage', 'waves', '#2E7D32', 'HIGH', 24, true, 'c0000000-0000-0000-0000-000000000002', 2, NOW(), NOW()),
    ('c0000000-0000-0000-0000-000000000031', 'Water Pipe Leak', 'water-pipe-leak', 'droplets', '#0277BD', 'CRITICAL', 12, true, 'c0000000-0000-0000-0000-000000000003', 1, NOW(), NOW()),
    ('c0000000-0000-0000-0000-000000000032', 'No Water Supply', 'no-water-supply', 'alert-triangle', '#0277BD', 'CRITICAL', 8, true, 'c0000000-0000-0000-0000-000000000003', 2, NOW(), NOW()),
    ('c0000000-0000-0000-0000-000000000041', 'Broken Streetlight', 'broken-streetlight', 'lightbulb-off', '#F57F17', 'MEDIUM', 36, true, 'c0000000-0000-0000-0000-000000000004', 1, NOW(), NOW()),
    ('c0000000-0000-0000-0000-000000000051', 'Damaged Playground', 'damaged-playground', 'smile', '#558B2F', 'LOW', 96, true, 'c0000000-0000-0000-0000-000000000005', 1, NOW(), NOW())
ON CONFLICT (slug) DO NOTHING;
