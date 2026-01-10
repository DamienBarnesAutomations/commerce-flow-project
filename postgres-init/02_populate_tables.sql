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



-- 2. Insert into the new consolidated table
INSERT INTO order_config (
    field_key, 
    display_name, 
    field_type, 
    static_prompt, 
    options, 
    visibility_rule, 
    validation_logic, 
    constraint_error_message, 
    sort_order
) VALUES
-- 1. Layers
('layer', 'Number of Layers', 'integer', 'How many layers would you like for your cake?', 
    '[{"label": "1 Layer", "value": "1", "price": 0}, {"label": "2 Layers", "value": "2", "price": 0}, {"label": "3 Layers", "value": "3", "price": 0}]'::jsonb, 
    NULL, NULL, NULL, 10),

-- 2. Size (with Validation Logic)
('size', 'Cake Size', 'string', 'What size cake would you like?', 
    '[
        {"label": "6\"", "value": "6", "price": 0}, 
        {"label": "8\"", "value": "8", "price": 0}, 
        {"label": "9\"", "value": "9", "price": 0}, 
        {"label": "10\"", "value": "10", "price": 0}, 
        {"label": "12\"", "value": "12", "price": 0}, 
        {"label": "Quarter Sheet", "value": "quarter sheet", "price": 0}, 
        {"label": "Half Sheet", "value": "half sheet", "price": 0}
    ]'::jsonb, 
    NULL, 
    '{
        "controlled_by": "layer",
        "allowed_map": {
            "1": ["6", "8", "9", "10", "12", "quarter sheet", "half sheet"],
            "2": ["6", "8", "9", "10", "12", "quarter sheet", "half sheet"],
            "3": ["6", "8"]
        }
    }'::jsonb, 
    'A 3-layer cake is only available in 6" or 8" sizes due to weight and stability.', 20),

-- 3. Flavor
('flavor', 'Cake Flavor', 'string', 'Which flavor would you like for your cake?', 
    '[
        {"label": "Vanilla", "value": "Vanilla", "price": 0}, {"label": "Carrot", "value": "Carrot", "price": 0}, 
        {"label": "Lemon", "value": "Lemon", "price": 0}, {"label": "Coconut", "value": "Coconut", "price": 0}, 
        {"label": "Marble", "value": "Marble", "price": 0}, {"label": "Chocolate", "value": "Chocolate", "price": 0}, 
        {"label": "Strawberry", "value": "Strawberry", "price": 0}, {"label": "Cookies and Cream", "value": "Cookies and Cream", "price": 0}, 
        {"label": "Red Velvet", "value": "Red Velvet", "price": 0}, {"label": "Banana Bread", "value": "Banana Bread", "price": 0}, 
        {"label": "Caribbean Fruit", "value": "Caribbean Fruit", "price": 0}, {"label": "Caribbean Rum", "value": "Caribbean Rum", "price": 0}, 
        {"label": "Butter Pecan", "value": "Butter Pecan", "price": 0}, {"label": "White Chocolate Sponge", "value": "White Chocolate Sponge", "price": 0}, 
        {"label": "Pineapple Sponge", "value": "Pineapple Sponge", "price": 0}
    ]'::jsonb, 
    NULL, NULL, NULL, 30),

-- 4. Theme
('cake_theme', 'Theme/Design', 'string', 'Do you have a specific theme or design in mind for the cake?', '[]'::jsonb, NULL, NULL, NULL, 40),

-- 5. AC Check
 ('has_ac', 'Air Conditioning', 'boolean', 'Will the cake be kept in an air-conditioned environment?', 
 '[
        {"label": "Yes (Climate Controlled)", "value": "true", "price": 0}, 
        {"label": "No (Ambient/Outdoor)", "value": "false", "price": 0}
    ]'::jsonb, 
    'This is important for the stability of our frostings.', 50
),

-- 6. Delivery Mode
('delivery', 'Delivery Service', 'boolean', 'Do you require delivery for this order?', 
    '[
        {"label": "Delivery", "value": "true", "price": 0}, 
        {"label": "Pickup", "value": "false", "price": 0}
    ]'::jsonb, 60
),
-- 7. Delivery Address (with Visibility Rule)
('delivery_address', 'Delivery Address', 'string', 'What is the full delivery address?', '[]'::jsonb, 
    '{"depends_on": "delivery", "show_if": "true"}'::jsonb, 
    NULL, NULL, 70),

-- 8. Event Date
('event_date', 'Event Date', 'date', 'What is the date of your event?', '[]'::jsonb, NULL, NULL, NULL, 80),

-- 9. Client Name
('client_name', 'Your Name', 'string', 'Lastly, what name should we put on the order?', '[]'::jsonb, NULL, NULL, NULL, 90);

INSERT INTO user_intents (intent_key, classification_guide) VALUES
('NEW_ORDER', 'User expresses a desire to start a new purchase or asks "can I buy something?". Look for keywords like "order", "buy", "get", or "purchase".'),
('CHANGE_ORDER', 'User wants to modify their selection or provides specific order details (e.g., flavors, sizes, delivery address, or choosing between "pickup" and "delivery"). Any input that answers a request for information or fills a field in the order draft should be classified here.'),
('CONFIRM_ORDER', 'User indicates they are finished and ready to finalize. Keywords: "done", "that is all", "confirm", "checkout", "send it", "place order".'),
('VIEW_HISTORY', 'User is asking about their past behavior, previous purchases, or "the usual". Keywords: "past", "history", "last time", "previous".'),
('VIEW_MENU', 'User is asking for options, prices, or what is available to buy. Keywords: "menu", "list", "options", "prices", "what do you have?".'),
('TALK_TO_HUMAN', 'User wants to bypass the AI. Look for frustration, "agent", "human", "person", "representative", or "help" in a non-automated context.'),
('CANCEL_ORDER', 'User wants to stop the process and delete the current draft or pending request entirely. Keywords: "cancel", "stop", "delete this".'),
('RESET_ORDER', 'User wants to wipe the slate clean and start the conversation from the beginning without necessarily leaving the chat.'),
('CHECK_STATUS', 'User is specifically asking about an order they already placed. Keywords: "status", "where is it?", "tracking", "is it approved?".'),
('UNKNOWN', 'User input is unrelated to ordering, is gibberish, or the intent is completely unclear. Use this as a fallback.'),
('GREETING', 'User is initiating a conversation or responding with social pleasantries. Look for keywords like "hello", "hi", "hey", "good morning", or "is anyone there?". This intent typically marks the start of an interaction before a specific request is made.'),
('HELP', 'User is confused or explicitly asking for guidance on how to use the bot. Keywords: "help", "how does this work?", "what can I do?", "guide", "instructions", "commands".');


-- Add the step_group column to handle conversational stages
ALTER TABLE order_config 
ADD COLUMN IF NOT EXISTS step_group VARCHAR(50);

-- 1. Add the stage grouping column
ALTER TABLE order_config 
ADD COLUMN IF NOT EXISTS step_group VARCHAR(50);

-- 2. Add the constraints column for single-field rules (like min_days_notice)
ALTER TABLE order_config 
ADD COLUMN IF NOT EXISTS constraints JSONB DEFAULT '{}'::jsonb;

-- 1. Categorize fields into 'Design' stage
UPDATE order_config 
SET step_group = '1. Design' 
WHERE field_key IN ('layer', 'size', 'flavor', 'cake_theme');

-- 2. Categorize fields into 'Logistics' stage
UPDATE order_config 
SET step_group = '2. Logistics' 
WHERE field_key IN ('has_ac', 'delivery', 'delivery_address', 'event_date');

-- 3. Categorize fields into 'Finalize' stage
UPDATE order_config 
SET step_group = '3. Finalize' 
WHERE field_key IN ('client_name');

-- 4. Apply the 7-day rule to the new 'constraints' column
UPDATE order_config 
SET constraints = '{"min_days_notice": 7}'::jsonb
WHERE field_key = 'event_date';