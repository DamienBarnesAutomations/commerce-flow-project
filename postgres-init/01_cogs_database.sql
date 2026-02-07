--- Run as postgres superuser
CREATE ROLE cogs_user LOGIN PASSWORD 'strong_password_here';
CREATE DATABASE cogs OWNER cogs_user;

-- Switch context to the new database
\c cogs

-- Standardize the public schema for the new owner
ALTER SCHEMA public OWNER TO cogs_user;

-- Grant explicit rights just to be safe
GRANT ALL ON SCHEMA public TO cogs_user;

-- Ensure future tables created by any user are accessible
ALTER DEFAULT PRIVILEGES IN SCHEMA public 
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO cogs_user;


CREATE TABLE IF NOT EXISTS units (
    unit_id SERIAL PRIMARY KEY,
    unit_name VARCHAR(50) UNIQUE NOT NULL, -- e.g., 'kg', 'g', 'L'
    unit_type VARCHAR(50) NOT NULL    -- e.g., 'WEIGHT', 'VOLUME', 'COUNT'
);

CREATE INDEX IF NOT EXISTS idx_unit_name ON units(unit_name);

-- 1. Table: ingredients
CREATE TABLE IF NOT EXISTS ingredients (
    ingredient_id SERIAL PRIMARY KEY,
    ingredient_name TEXT UNIQUE NOT NULL,
    unit_id INTEGER REFERENCES Units(Unit_id) NOT NULL, 
    current_quantity NUMERIC NOT NULL DEFAULT 0 CHECK (current_quantity >= 0),
    reorder_point NUMERIC NOT NULL DEFAULT 0 CHECK (reorder_point >= 0),
    current_cost NUMERIC NOT NULL DEFAULT 0.0 CHECK (current_cost >= 0),
    last_updated TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_ingredient_name ON ingredients(ingredient_name);

-- 2. Table: units
CREATE TABLE IF NOT EXISTS units (
    unit_id SERIAL PRIMARY KEY,
    unit_name VARCHAR(50) UNIQUE NOT NULL, -- e.g., 'kg', 'g', 'L'
    unit_type VARCHAR(50) NOT NULL    -- e.g., 'WEIGHT', 'VOLUME', 'COUNT'
);

CREATE INDEX IF NOT EXISTS idx_unit_name ON units(unit_name);

-- 3. Table: conversion_rates
CREATE TABLE IF NOT EXISTS conversion_rates (
    conversion_rate_id SERIAL PRIMARY KEY,
    from_unit_id INTEGER REFERENCES units(unit_id),
    to_unit_id INTEGER REFERENCES units(unit_id),
    multiplier NUMERIC(15, 6) NOT NULL,
    UNIQUE(from_unit_id, to_unit_id)
);

-- 4. Table: recipes
CREATE TABLE IF NOT EXISTS recipes (
    recipe_id SERIAL PRIMARY KEY,
    recipe_name TEXT NOT NULL UNIQUE,
    base_yield INTEGER NOT NULL CHECK (base_yield > 0),
    unit_name TEXT NOT NULL, 
    instructions TEXT,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_recipe_name ON recipes(recipe_name);

-- 5. Table: recipe_components
CREATE TABLE IF NOT EXISTS recipe_components (
    recipe_component_id SERIAL PRIMARY KEY,
    recipe_id INTEGER NOT NULL REFERENCES recipes(recipe_id) ON DELETE RESTRICT,
    ingredient_id INTEGER NOT NULL REFERENCES INGREDIENTS(ingredient_id) ON DELETE RESTRICT,
    quantity_needed NUMERIC (10, 3) NOT NULL CHECK (quantity_needed > 0),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (recipe_id, ingredient_id)
);



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
