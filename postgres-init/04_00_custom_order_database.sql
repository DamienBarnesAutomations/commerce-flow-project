--- Run as postgres superuser
CREATE DATABASE custom_order OWNER custom_order_user;

-- Switch context to the new database
\c custom_order

-- Standardize the public schema for the new owner
ALTER SCHEMA public OWNER TO custom_order_user;

-- Grant explicit rights just to be safe
GRANT ALL ON SCHEMA public TO custom_order_user;

-- Ensure future tables created by any user are accessible
ALTER DEFAULT PRIVILEGES IN SCHEMA public 
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO custom_order_user;

GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO custom_order_user;

-- Ensure future sequences are accessible
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL ON SEQUENCES TO custom_order_user;

CREATE TABLE IF NOT EXISTS chat_sessions (
    customer_id VARCHAR(20) PRIMARY KEY,
    current_state VARCHAR(50) DEFAULT 'START',
    last_interaction TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source VARCHAR(20) NOT NULL, -- e.g., 'telegram', 'whatsapp'
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
    selections JSONB DEFAULT '{
        "client_name": null,
        "event_date": null,
        "delivery": null,
        "delivery_address": null,
        "tiers": null,
        "cake_theme": null,
        "has_ac": null,
        "special_note": null,
        "image_reference": null,
        "tier_definitions": [
            {
                "tier_index": 1,
                "size": null,
                "flavor": null,
                "layers": null
            }
        ]
    }',
    order_status_id VARCHAR(50) REFERENCES order_status(order_status_id) DEFAULT 'DRAFT', 
    turn_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE UNIQUE INDEX idx_one_funnel_order_per_user 
ON custom_orders (customer_id) 
WHERE order_status_id IN ('DRAFT', 'AWAITING_APPROVAL');

CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_custom_orders_modtime
    BEFORE UPDATE ON custom_orders
    FOR EACH ROW
    EXECUTE PROCEDURE update_modified_column();


CREATE TABLE IF NOT EXISTS user_intents (
    intent_id SERIAL PRIMARY KEY,
    intent_key VARCHAR(50) UNIQUE NOT NULL,
    classification_guide TEXT,
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
    field_type VARCHAR(20) NOT NULL CHECK (field_type IN ('string', 'integer', 'boolean', 'date', 'select')),
    scope VARCHAR(20) NOT NULL DEFAULT 'global' CHECK (scope IN ('global', 'tier')),
    options JSONB DEFAULT '[]'::jsonb,
    extraction_hint TEXT,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    CONSTRAINT enforce_option_structure CHECK (
        jsonb_typeof(options) = 'array' AND 
        (jsonb_array_length(options) = 0 OR jsonb_exists(options->0, 'value'))
    )
);
CREATE INDEX IF NOT EXISTS idx_order_config_field_key ON order_config(field_key);

-- Validation Function & Trigger for order_config
CREATE OR REPLACE FUNCTION validate_order_config_integrity() 
RETURNS trigger AS $$
BEGIN
    IF NEW.options IS NOT NULL AND jsonb_typeof(NEW.options) = 'array' AND jsonb_array_length(NEW.options) > 0 THEN
        IF NOT EXISTS (
            SELECT 1 FROM jsonb_array_elements(NEW.options) AS opt 
            WHERE jsonb_exists(opt, 'value')
        ) THEN
            RAISE EXCEPTION 'Field "%": Each option must have a "value"', NEW.field_key;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validate_order_config
    BEFORE INSERT OR UPDATE ON order_config
    FOR EACH ROW EXECUTE FUNCTION validate_order_config_integrity();

CREATE TABLE IF NOT EXISTS field_rules (
    rule_id SERIAL PRIMARY KEY,
    field_key VARCHAR(50) REFERENCES order_config(field_key) ON DELETE CASCADE,
    rule_type VARCHAR(50) NOT NULL,
    config JSONB NOT NULL,
    error_message TEXT
);

CREATE TABLE order_review (
    id SERIAL PRIMARY KEY,
    customer_id VARCHAR(20) REFERENCES chat_sessions(customer_id) NOT NULL,
    order_id INT REFERENCES custom_orders(order_id) NOT NULL,
    quoted_price DECIMAL(10, 2),
    user_note TEXT,
    admin_note TEXT,
    review_status VARCHAR(20) DEFAULT 'PENDING', -- Can be 'PENDING', 'ACCEPTED', 'REJECTED'
    is_processed BOOLEAN DEFAULT FALSE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE admin_user (
    id SERIAL PRIMARY KEY,
    admin_id VARCHAR(20) NOT NULL,
    source VARCHAR(50) NOT NULL, -- e.g., 'telegram', 'web'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


INSERT INTO order_status (order_status_id, display_name, description, display_order) VALUES
('DRAFT', 'Draft', 'Order is currently being edited and has not been submitted.', 1),
('AWAITING_APPROVAL', 'Awaiting Approval', 'Order is pending internal verification by a supervisor.', 2),
('AWAITING_DEPOSIT', 'Awaiting Deposit', 'Payment is required before the order can proceed to production.', 4),
('AWAITING_REVIEW', 'In Review', 'The order is being reviewed for quality or specifications.', 3),
('CANCELLED', 'Cancelled', 'The order was stopped and will not be fulfilled.', 5),
('COMPLETED', 'Completed', 'The order has been successfully fulfilled and closed.', 6);


INSERT INTO user_intents (intent_key, classification_guide) VALUES
('NEW_ORDER', 'User explicitly requests to start a fresh order from scratch, often using "new" as a keyword. Example: "I want to start a new order" or "Let''s start over with a fresh cake." This intent should be used SPARINGLY; if they are just providing details for the first time, use CHANGE_ORDER instead.'),

('CHANGE_ORDER', 'The primary intent for processing details. Use this when the user provides ANY specific data points (flavors, sizes, dates, names, delivery status) or answers a question from the bot. Even if it is the first thing they say about a cake, if it contains details, it is CHANGE_ORDER.'),

('RESET_ORDER', 'User explicitly wants to wipe the current selection and return to a blank slate. Look for "reset", "clear everything", "start the form over", or "empty my cart". Unlike CANCEL, this implies they want to stay in the ordering flow but with no data saved.'),

('CONFIRM_ORDER', 'User is ready to finalize and move to payment or scheduling. Keywords: "done", "that is all", "confirm", "checkout", "send it", "place order", "looks good".'),

('CANCEL_ORDER', 'User wants to stop the current process entirely. This is more final than a reset. Keywords: "cancel", "stop", "forget it", "nevermind", "I don''t want this anymore".'),

('VIEW_HISTORY', 'User asks about past orders, previous designs, or "the usual". Keywords: "past", "history", "last time", "previous", "what did I get before?".'),

('VIEW_MENU', 'User is browsing. Asking for flavors, sizes, pricing lists, or available themes. Keywords: "menu", "list", "options", "prices", "what flavors do you have?".'),

('TALK_TO_HUMAN', 'User bypasses the bot. Look for keywords like "agent", "human", "person", "representative", or expressions of severe frustration with the automation.'),

('CHECK_STATUS', 'User is asking about a COMPLETED order that is already in the system. Keywords: "status", "where is it?", "tracking", "is my cake ready?".'),

('GREETING', 'Social pleasantries and openers. "Hello", "Hi", "Good morning". If a greeting is combined with an order (e.g., "Hi, I want a cake"), prioritize the ordering intent.'),

('HELP', 'User is stuck. "How do I use this?", "What can I do?", "help", "instructions".'),

('UNKNOWN', 'Fallback for gibberish, unrelated topics (weather, news), or completely ambiguous input that doesn''t fit the categories above.');



INSERT INTO order_config (
    field_key, display_name, field_type, scope, options, 
    extraction_hint, sort_order, is_active
) VALUES
-- GLOBAL SCOPE: Root level order details
('client_name', 'Client Name', 'string', 'global', '[]',
    'Extract the customer''s full name. If they mention a business, prioritize the individual contact name.',
    10, true),

('event_date', 'Event Date', 'date', 'global', '[]',
    'Convert natural language (e.g., "next Friday", "Halloween") to YYYY-MM-DD. Assume the current or upcoming year. Minimum 7 days notice required.',
    20, true),

('delivery', 'Delivery Service', 'boolean', 'global', 
    '[{"label": "Delivery", "value": true}, {"label": "Pickup", "value": false}]',
    'True for phrases like "bring it to me," "drop off," or "deliver." False for "pick up," "self-collect," or "I''ll come by."',
    30, true),

('delivery_address', 'Delivery Address', 'string', 'global', '[]',
    'Extract the full street address including unit numbers or zip codes. Ignore if delivery is false.',
    40, true),

('tiers', 'Number of Tiers', 'integer', 'global', 
    '[{"label": "1 Tier", "value": 1}, {"label": "2 Tiers", "value": 2}, {"label": "3 Tiers", "value": 3}]',
    'Identify how many stacked sections are requested. Map "layers" to tiers if they describe dimensions (e.g., "a 10 and 8 inch cake" = 2 tiers).',
    50, true),

('cake_theme', 'Theme/Design', 'string', 'global', '[]',
    'Extract the visual style, character, or occasion (e.g., "Star Wars", "Wedding", "Minimalist"). If simple/plain, map to "None".',
    60, true),

('has_ac', 'Air Conditioning', 'boolean', 'global', 
    '[{"label": "Yes", "value": true}, {"label": "No", "value": false}]',
    'True if the cake will be kept in climate control/AC. False for outdoor, park, or ambient temperature settings.',
    70, true),

-- TIER SCOPE: Repeated attributes inside 'tier_definitions'
('size', 'Tier Size', 'select', 'tier', 
    '[{"label": "6\"", "value": "6"}, {"label": "8\"", "value": "8"}, {"label": "9\"", "value": "9"}, {"label": "10\"", "value": "10"}, {"label": "12\"", "value": "12"}, {"label": "Quarter Sheet", "value": "quarter sheet"}, {"label": "Half Sheet", "value": "half sheet"}]',
    'Extract the diameter of the specific tier. Normalize "10 inch" or "10\"" to "10". If multiple tiers, identify which size belongs to which position (bottom-up).',
    80, true),

('flavor', 'Cake Flavor', 'select', 'tier', 
    '[{"label": "Vanilla", "value": "Vanilla"}, {"label": "Chocolate", "value": "Chocolate"}, {"label": "Red Velvet", "value": "Red Velvet"}, {"label": "Carrot", "value": "Carrot"}, {"label": "Lemon", "value": "Lemon"}, {"label": "Coconut", "value": "Coconut"}]',
    'Match the flavor against known options. If user mentions different flavors for different tiers, map them specifically (e.g., "bottom tier chocolate, top vanilla").',
    90, true),

('layers', 'Internal Layers', 'integer', 'tier', 
    '[{"label": "2 Layers", "value": 2}, {"label": "3 Layers", "value": 3}, {"label": "4 Layers", "value": 4}]',
    'Count the horizontal sponge slices inside a single tier. Often called "double layer" or "triple layer." Distinct from the number of Tiers.',
    100, true),
('special_note', 'Special Instructions', 'string', 'global', '[]',
    'Capture any miscellaneous requests, allergies, or specific design details not covered by other fields. Look for phrases like "Make sure to...", "Also...", or "Please include...". Do not include tier sizes or flavors here.',
    110, true),

-- Image: Capturing visual references
('image_reference', 'Inspiration Image', 'string', 'global', '[]',
    'Extract the URL or file identifier of any images shared by the user. If the user says "like this photo" or "attached is a sketch," link that reference here.',
    120, true);


INSERT INTO field_rules (field_key, rule_type, config, error_message) VALUES
-- Date constraint
('event_date', 'lead_time', '{"min_days": 7}', 'I need at least 7 days notice to bake something amazing!'),

-- Visibility constraint
('delivery_address', 'dependency', '{"depends_on": "delivery", "value": true}', 'Where should I deliver the cake?'),

-- Structural Stability (The Cake-Specific Logic)
('size', 'min_base_for_tiers', '{"tiers": 2, "min_inches": 8}', 'For a 2-tier cake, the bottom tier must be at least 8 inches.'),
('size', 'min_base_for_tiers', '{"tiers": 3, "min_inches": 10}', 'A 3-tier cake needs a sturdy 10-inch base to stay upright!'),
('special_note', 'max_length', '{"max_chars": 500}', 'Your special note is too long!');