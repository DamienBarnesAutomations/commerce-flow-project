-- 2. The Products Table
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    price NUMERIC(10, 2),
    img_url TEXT,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_products_name ON products(name);

CREATE TABLE IF NOT EXISTS sales (
    id SERIAL PRIMARY KEY,
    transaction_id INTEGER,
    product_id INTEGER REFERENCES products(id) ON DELETE CASCADE,
    quantity INTEGER DEFAULT 1,
    price_at_sale DECIMAL(10, 2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

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

CREATE TABLE IF NOT EXISTS user_states (
    chat_id BIGINT PRIMARY KEY,
    current_mode TEXT DEFAULT 'MAIN', -- e.g., 'PRODUCT', 'INGREDIENT', 'RECIPE'
    last_updated TIMESTAMP DEFAULT NOW()
);