
CREATE TABLE IF NOT EXISTS chat_sessions (
    customer_id VARCHAR(20) PRIMARY KEY,
    current_state VARCHAR(50) DEFAULT 'START',
    last_interaction TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_ai_prompt TEXT
);

CREATE INDEX IF NOT EXISTS idx_chat_sessions_customer_id ON chat_sessions(customer_id);

CREATE TABLE order_status (
    order_status_id VARCHAR(50) PRIMARY KEY, -- The "slug" used in code
    display_name VARCHAR(100) NOT NULL, -- What the user sees
    description TEXT, -- Internal or tooltip explanation
    display_order INT DEFAULT 0, -- To keep lists sorted in the UI
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);



CREATE TABLE IF NOT EXISTS custom_orders (
    order_id SERIAL PRIMARY KEY,
    customer_id VARCHAR(20) REFERENCES chat_sessions(customer_id),
    selections JSONB DEFAULT '{}',
    order_status_id VARCHAR(50) REFERENCES order_status(order_status_id) DEFAULT 'DRAFT', 
    turn_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX idx_one_funnel_order_per_user 
ON custom_orders (customer_id) 
WHERE order_status_id IN ('DRAFT', 'AWAITING_APPROVAL');


CREATE TABLE IF NOT EXISTS user_intents (
    intent_id SERIAL PRIMARY KEY,
    intent_key VARCHAR(50) UNIQUE NOT NULL,
    classification_guide TEXT, -- Why the AI should pick this
    is_active BOOLEAN DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_user_intents_intent_key ON user_intents(intent_key);


CREATE TABLE IF NOT EXISTS user_intents_config (
    intent_key VARCHAR(50) REFERENCES user_intents (intent_key),
    is_ai_action boolean DEFAULT FALSE,
    response_template TEXT DEFAULT '',
    sql_query TEXT DEFAULT ''
);


CREATE TABLE IF NOT EXISTS order_config (
    field_id SERIAL PRIMARY KEY,
    field_key VARCHAR(50) UNIQUE NOT NULL,
    display_name VARCHAR(100) NOT NULL,
    field_type VARCHAR(20) NOT NULL DEFAULT 'string', 
    options JSONB DEFAULT '[]'::jsonb,
    rules JSONB DEFAULT '[]'::jsonb,  -- visibility + validation + constraints
    extraction_hint TEXT,
    is_required BOOLEAN DEFAULT TRUE,
    is_active BOOLEAN DEFAULT TRUE,
    step_group INTEGER,
    sort_order INTEGER DEFAULT 0
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_order_config_field_key ON order_config(field_key);


