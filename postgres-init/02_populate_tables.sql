-- 1. Insert Core Units
INSERT INTO units (unit_name, unit_type) VALUES 
('kg', 'WEIGHT'),
('g', 'WEIGHT'),
('L', 'VOLUME'),
('ml', 'VOLUME'),
('unit', 'COUNT'),
('pcs', 'COUNT')
ON CONFLICT (unit_name) DO NOTHING;

-- 2. Insert Weight Conversions (g <-> kg)
INSERT INTO conversion_rates (from_unit_id, to_unit_id, multiplier)
VALUES 
    ((SELECT unit_id FROM units WHERE unit_name = 'g'), (SELECT unit_id FROM units WHERE unit_name = 'kg'), 0.001),
    ((SELECT unit_id FROM units WHERE unit_name = 'kg'), (SELECT unit_id FROM units WHERE unit_name = 'g'), 1000.0)
ON CONFLICT DO NOTHING;

-- 3. Insert Volume Conversions (ml <-> L)
INSERT INTO conversion_rates (from_unit_id, to_unit_id, multiplier)
VALUES 
    ((SELECT unit_id FROM units WHERE unit_name = 'ml'), (SELECT unit_id FROM units WHERE unit_name = 'L'), 0.001),
    ((SELECT unit_id FROM units WHERE unit_name = 'L'), (SELECT unit_id FROM units WHERE unit_name = 'ml'), 1000.0)
ON CONFLICT DO NOTHING;

-- 4. Insert Identity Conversions (unit <-> pcs)
INSERT INTO conversion_rates (from_unit_id, to_unit_id, multiplier)
VALUES 
    ((SELECT unit_id FROM units WHERE unit_name = 'pcs'), (SELECT unit_id FROM units WHERE unit_name = 'unit'), 1.0),
    ((SELECT unit_id FROM units WHERE unit_name = 'unit'), (SELECT unit_id FROM units WHERE unit_name = 'pcs'), 1.0)
ON CONFLICT DO NOTHING;