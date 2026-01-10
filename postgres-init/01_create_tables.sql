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


CREATE INDEX IF NOT EXISTS idx_cake_options_name ON cake_options(item_name);

CREATE TABLE IF NOT EXISTS chat_sessions (
    whatsapp_num VARCHAR(20) PRIMARY KEY,
    current_state VARCHAR(50) DEFAULT 'START',
    customer_name VARCHAR(100),
    last_interaction TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_ai_prompt TEXT
);

CREATE INDEX IF NOT EXISTS idx_chat_sessions_whatsapp_num ON chat_sessions(whatsapp_num);

CREATE TYPE order_status_type AS ENUM (
  'DRAFT', 
  'AWAITING_APPROVAL', 
  'AWAITING_DEPOSIT', 
  'AWAITING_REVIEW', 
  'CANCELLED', 
  'COMPLETED'
);

CREATE TABLE IF NOT EXISTS custom_orders (
    order_id SERIAL PRIMARY KEY,
    whatsapp_num VARCHAR(20) REFERENCES chat_sessions(whatsapp_num),
    selections JSONB DEFAULT '{}', -- All cake details & address go here
    total_price DECIMAL(10, 2) DEFAULT 0.00,
    deposit_amount DECIMAL(10, 2) DEFAULT 0.00, -- 60% of total
    status order_status_type DEFAULT 'DRAFT', 
    -- Statuses: DRAFT, PENDING_APPROVAL, AWAITING_DEPOSIT, ACCEPTED, COMPLETED, CANCELLED
    turn_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

drop index idx_one_funnel_order_per_user
CREATE UNIQUE INDEX idx_one_funnel_order_per_user 
ON custom_orders (whatsapp_num) 
WHERE status IN ('DRAFT', 'AWAITING_APPROVAL');

-- 1. Create the Strategy Enum

CREATE TABLE IF NOT EXISTS user_intents (
    intent_id SERIAL PRIMARY KEY,
    intent_key VARCHAR(50) UNIQUE NOT NULL,
    classification_guide TEXT, -- Why the AI should pick this
    is_active BOOLEAN DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_user_intents_intent_key ON user_intents(intent_key);

ALTER TABLE user_intents
ADD COLUMN is_ai_action boolean DEFAULT FALSE

ALTER TABLE user_intents
ADD COLUMN message_template TEXT 

ALTER TABLE user_intents
ADD COLUMN sql_action TEXT 



CREATE TABLE IF NOT EXISTS order_config (
    field_id SERIAL PRIMARY KEY,
    field_key VARCHAR(50) UNIQUE NOT NULL,
    display_name VARCHAR(100) NOT NULL,
    field_type VARCHAR(20) NOT NULL DEFAULT 'string', -- string, boolean, date, integer
    static_prompt TEXT NOT NULL,
    options JSONB DEFAULT '{}'::jsonb,
    visibility_rule JSONB DEFAULT NULL, -- e.g., {"depends_on": "delivery", "show_if": "Delivery"}
    validation_logic JSONB DEFAULT NULL, -- e.g., {"controlled_by": "layer", "allowed_map": {...}}
    constraint_error_message TEXT,
    is_required BOOLEAN DEFAULT TRUE,
    is_active BOOLEAN DEFAULT TRUE,
    sort_order INTEGER DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_order_config_field_key_key ON order_config(field_key);

CREATE OR REPLACE FUNCTION validate_order_config_logic(logic jsonb) 
RETURNS boolean AS $$
BEGIN
    -- 1. If logic is NULL, it's valid (optional field)
    IF logic IS NULL THEN RETURN TRUE; END IF;

    -- 2. Ensure basic structure
    IF NOT (logic ? 'controlled_by' AND logic ? 'allowed_map') THEN
        RETURN FALSE;
    END IF;

    -- 3. Referential Integrity: Check if the 'controlled_by' key exists in the table
    -- This ensures "layer" actually exists in order_config.field_key
    IF NOT EXISTS (
        SELECT 1 FROM order_config 
        WHERE field_key = (logic->>'controlled_by')
    ) THEN
        RETURN FALSE;
    END IF;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

ALTER TABLE order_config
ADD CONSTRAINT enforce_logic_integrity 
CHECK (validate_order_config_logic(validation_logic));

CREATE OR REPLACE FUNCTION validate_visibility_logic(rule jsonb) 
RETURNS boolean AS $$
BEGIN
    -- 1. If rule is NULL, it's valid (always visible)
    IF rule IS NULL THEN RETURN TRUE; END IF;

    -- 2. Check for required keys
    IF NOT (rule ? 'depends_on' AND rule ? 'show_if') THEN
        RETURN FALSE;
    END IF;

    -- 3. Referential Integrity: Ensure the source field exists
    IF NOT EXISTS (
        SELECT 1 FROM order_config 
        WHERE field_key = (rule->>'depends_on')
    ) THEN
        RETURN FALSE;
    END IF;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;


ALTER TABLE order_config
ADD CONSTRAINT enforce_visibility_integrity 
CHECK (validate_visibility_logic(visibility_rule));

CREATE OR REPLACE FUNCTION validate_options_pricing(opts jsonb) 
RETURNS boolean AS $$
DECLARE
    item jsonb;
BEGIN
    -- If it's empty or null, that's fine (e.g., for text input fields)
    IF opts IS NULL OR jsonb_array_length(opts) = 0 THEN 
        RETURN TRUE; 
    END IF;

    -- Iterate through each object in the array
    FOR item IN SELECT * FROM jsonb_array_elements(opts) LOOP
        IF NOT (item ? 'value' AND item ? 'price') THEN
            RETURN FALSE;
        END IF;
        
        IF jsonb_typeof(item->'price') != 'number' THEN
            RETURN FALSE;
        END IF;
    END LOOP;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

ALTER TABLE order_config
ADD CONSTRAINT enforce_options_pricing 
CHECK (validate_options_pricing(options));

CREATE TABLE IF NOT EXISTS user_chat_context (
	user_chat_context_id SERIAL PRIMARY KEY,
	whatsapp_num VARCHAR(20) REFERENCES chat_sessions(whatsapp_num),
	order_id INTEGER REFERENCES custom_orders(order_id),
	field_id INTEGER REFERENCES order_config(id)
)

CREATE INDEX IF NOT EXISTS idx_user_chat_context_key ON user_chat_context(whatsapp_num);

CREATE TABLE IF NOT EXISTS ai_prompt_message_template(
	ai_prompt_message_id SERIAL PRIMARY KEY,
	user_prompt TEXT NOT NULL,
	system_prompt TEXT NOT NULL
)

