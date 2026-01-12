INSERT INTO order_status (order_status_id, display_name, description, display_order) VALUES
('DRAFT', 'Draft', 'Order is currently being edited and has not been submitted.', 1),
('AWAITING_APPROVAL', 'Awaiting Approval', 'Order is pending internal verification by a supervisor.', 2),
('AWAITING_DEPOSIT', 'Awaiting Deposit', 'Payment is required before the order can proceed to production.', 3),
('AWAITING_REVIEW', 'In Review', 'The order is being reviewed for quality or specifications.', 4),
('CANCELLED', 'Cancelled', 'The order was stopped and will not be fulfilled.', 5),
('COMPLETED', 'Completed', 'The order has been successfully fulfilled and closed.', 6);


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

INSERT INTO user_intents_config (
    intent_key,
    is_ai_action,
    response_template,
    sql_query
) VALUES
-- CANCEL_ORDER
('CANCEL_ORDER', false, 
 '🛑 *ORDER CANCELED*\n\n
    Understood, {{{client_name}}}. Your order for the **{{{cake_theme}}}** cake has been successfully canceled.\n\n
    If this was a mistake or you''ve changed your mind, you can start a new order at any time by typing **""NEW ORDER""**.\n\n
    _We hope to bake something special for your next celebration!_', 
 'UPDATE custom_orders
SET status = ''CANCELLED''
WHERE status in (''DRAFT'', ''AWAITING_APPROVAL'', ''AWAITING_DEPOSIT'', ''AWAITING_REVIEW'')
AND whatsapp_num = $1
RETURNING *'),

-- CHECK_STATUS
('CHECK_STATUS', false, 
 '🔍 *ORDER STATUS*

Hi **{{client_name}}**, here is the current status of your cake for **{{event_date}}**:

📌 *Current Status*: **{{status}}**

🎂 *Cake Details*:
• **Size**: {{size}} (${{price_size}}) 
• **Layers**: {{layer}} (${{price_layer}})
• **Flavor**: {{flavor}} (${{price_flavor}})
• **Theme**: {{cake_theme}}

🚚 *Logistics*:
• **A/C**: {{has_ac}} 
• **Method**: {{delivery_method}} (${{price_delivery}})
{{#delivery_address}}
• **Location**: {{delivery_address}}

{{/delivery_address}}
---
💰 *Financial Summary*:
• **Total Amount**: **${{final_total_price}}**
---

_Need further help? Just ask to talk to a human!_', 
 'WITH exploded_selections AS (
    SELECT 
        o.order_id,
        o.status,
        kv.key AS field_key,
        kv.value AS selected_value
    FROM custom_orders o,
    jsonb_each_text(o.selections) AS kv
    WHERE whatsapp_num = $1
	AND status in (''DRAFT'', ''AWAITING_APPROVAL'', ''AWAITING_DEPOSIT'')
),
priced_details AS (
    SELECT 
        es.order_id,
        es.status,
        es.field_key,
        COALESCE((
            SELECT opt->>''label'' 
            FROM jsonb_array_elements(oc.options) AS opt 
            WHERE opt->>''value'' = es.selected_value
        ), es.selected_value) AS display_label,
        COALESCE((
            SELECT (opt->>''price'')::DECIMAL 
            FROM jsonb_array_elements(oc.options) AS opt 
            WHERE opt->>''value'' = es.selected_value
        ), 0.00) AS price_increment
    FROM exploded_selections es
    LEFT JOIN order_config oc ON es.field_key = oc.field_key
)
SELECT 
    order_id,
    status,
    MAX(display_label) FILTER (WHERE field_key = ''client_name'') AS client_name,
    MAX(display_label) FILTER (WHERE field_key = ''event_date'') AS event_date,
    MAX(display_label) FILTER (WHERE field_key = ''layer'') AS layer,
    MAX(display_label) FILTER (WHERE field_key = ''size'') AS size,
    MAX(display_label) FILTER (WHERE field_key = ''flavor'') AS flavor,
    MAX(display_label) FILTER (WHERE field_key = ''cake_theme'') AS cake_theme,
    MAX(display_label) FILTER (WHERE field_key = ''has_ac'') AS has_ac,
    MAX(display_label) FILTER (WHERE field_key = ''delivery'') AS delivery_method,
    MAX(display_label) FILTER (WHERE field_key = ''delivery_address'') AS delivery_address,
    
    MAX(price_increment) FILTER (WHERE field_key = ''layer'') AS price_layer,
    MAX(price_increment) FILTER (WHERE field_key = ''size'') AS price_size,
    MAX(price_increment) FILTER (WHERE field_key = ''flavor'') AS price_flavor,
    MAX(price_increment) FILTER (WHERE field_key = ''has_ac'') AS price_ac,
    MAX(price_increment) FILTER (WHERE field_key = ''delivery'') AS price_delivery,
    
    SUM(price_increment) AS final_total_price
FROM priced_details
GROUP BY order_id, status;'),

-- CONFIRM_ORDER
('CONFIRM_ORDER', false, 
 '"Thank you for your order! 📝 It is now registered in our system. To finalize your booking and secure your date, a 60% deposit is required. We will send your official confirmation once the payment has been processed. Thank you for choosing us!"', 
 'UPDATE custom_orders
SET status = ''AWAITING_REVIEW''
WHERE status in (''AWAITING_APPROVAL'')
  AND whatsapp_num = $1'),

-- GREETING
('GREETING', false, 
 'Good day! Welcome to Precious'' Place. 🎂

We''d love to help make your event special with a custom cake. To get started and provide you with an accurate quote, I''ll just need to ask you a few questions about your vision—like the date, flavor, and design.

We are located on lower St. Mary''s Street and offer online payment for your convenience.

Ready to start your order? Just let me know the date of your event!', 
 'SELECT 1'),

-- HELP
('HELP', false, 
 '🛠️ **PRECIOUS'' PLACE ASSISTANT: HELP MENU**
━━━━━━━━━━━━━━━━━━━━━━━━━━

**I can help you with:**
📝 **NEW ORDER** •  Type ""I want to buy a cake""
📋 **VIEW MENU** •  Type ""Show me the menu""
🛒 **MY CART** •  Type ""What did I pick so far?""
❌ **CANCEL** •  Type ""Start over"" or ""Cancel""

**Common Questions:**
📍 **Where?** •  Lower St. Mary''s Street
💳 **Payment?** •  Online payment links available
🚚 **Delivery?** •  Yes! Just provide your address
👤 **Human?** •  Type ""Talk to a person""

━━━━━━━━━━━━━━━━━━━━━━━━━━
**How can I assist you right now?**', 
 'SELECT 1'),

-- RESET_ORDER
('RESET_ORDER', false, 
 '🔄 *ORDER RESET*\n\n
All information has been cleared, ${order.client_name}. You''re back at the beginning and ready for a fresh start!\n\n
When you''re ready to design your next masterpiece, just type **""NEW ORDER""** or tell me the **cake theme** you''re thinking of.\n\n
_Let''s create something delicious!_', 
 'UPDATE custom_orders
SET status = ''CANCELLED''
WHERE status in (''DRAFT'', ''AWAITING_APPROVAL'')
AND whatsapp_num = $1
RETURNING *'),

-- TALK_TO_HUMAN
('TALK_TO_HUMAN', false, 
 '🤝 *Connecting you with our team...*\n\n 
I''ve notified one of our team members that you''d like to chat. Someone will jump in shortly to assist you with your request!\n\n
📍 *Note*: Our team is typically available between 9:00 AM and 6:00 PM. If it''s outside these hours, we will get back to you first thing in the morning.\n\n
_Thank you for your patience!_;', 
 'UPDATE chat_sessions
SET current_state = ''TALK_TO_HUMAN''
WHERE whatsapp_num = $1'),

-- VIEW_HISTORY
('VIEW_HISTORY', false, 
 '📜 *ORDER HISTORY*
Hi {{client_name}}, here are your past and current orders:

[REPEATING_ROW]
📅 {{event_date}} - {{cake_theme}}
💰 Total: ${{final_total_price}} (Status: {{status}})
[REPEATING_ROW]

---
_Need details? Ask to ""Check Status"" for a specific date!_', 
 'WITH exploded_selections AS (
    SELECT 
        o.order_id,
        o.status,
        kv.key AS field_key,
        kv.value AS selected_value
    FROM custom_orders o,
    jsonb_each_text(o.selections) AS kv
    WHERE whatsapp_num = $1
	AND status <> ''CANCELLED''
),
priced_details AS (
    SELECT 
        es.order_id,
        es.status,
        es.field_key,
        COALESCE((
            SELECT opt->>''label'' 
            FROM jsonb_array_elements(oc.options) AS opt 
            WHERE opt->>''value'' = es.selected_value
        ), es.selected_value) AS display_label,
        COALESCE((
            SELECT (opt->>''price'')::DECIMAL 
            FROM jsonb_array_elements(oc.options) AS opt 
            WHERE opt->>''value'' = es.selected_value
        ), 0.00) AS price_increment
    FROM exploded_selections es
    LEFT JOIN order_config oc ON es.field_key = oc.field_key
)
    SELECT 
    order_id,
    status,
    MAX(display_label) FILTER (WHERE field_key = ''client_name'') AS client_name,
    MAX(display_label) FILTER (WHERE field_key = ''event_date'') AS event_date,
    MAX(display_label) FILTER (WHERE field_key = ''layer'') AS layer,
    MAX(display_label) FILTER (WHERE field_key = ''size'') AS size,
    MAX(display_label) FILTER (WHERE field_key = ''flavor'') AS flavor,
    MAX(display_label) FILTER (WHERE field_key = ''cake_theme'') AS cake_theme,
    MAX(display_label) FILTER (WHERE field_key = ''has_ac'') AS has_ac,
    MAX(display_label) FILTER (WHERE field_key = ''delivery'') AS delivery_method,
    MAX(display_label) FILTER (WHERE field_key = ''delivery_address'') AS delivery_address,
    MAX(price_increment) FILTER (WHERE field_key = ''layer'') AS price_layer,
    MAX(price_increment) FILTER (WHERE field_key = ''size'') AS price_size,
    MAX(price_increment) FILTER (WHERE field_key = ''flavor'') AS price_flavor,
    MAX(price_increment) FILTER (WHERE field_key = ''delivery'') AS price_delivery,
    SUM(price_increment) AS final_total_price
FROM priced_details
GROUP BY order_id, status
ORDER BY event_date DESC;'),

-- VIEW_MENU
('VIEW_MENU', false, 
 '✨ **PRECIOUS'' PLACE CUSTOM CAKES** ✨

🎂 **LAYERS**
{{layer}}

📏 **SIZES**
{{size}}

🍓 **FLAVORS**
{{flavor}}

🎨 **DESIGN & THEME**
We bring your vision to life! Send us a description or a photo.

📍 **INFO & LOGISTICS**
* **Location:** Lower St. Mary''s Street
* **Payment:** Online Payment 💳
* **Notice:** 7 Days Minimum 🗓️

*Ready to start? Tell me your Event Date or a Flavor!*', 
 'SELECT 
    MAX(display_text) FILTER (WHERE field_key = ''layer'') AS layer,
    MAX(display_text) FILTER (WHERE field_key = ''size'') AS size,
    MAX(display_text) FILTER (WHERE field_key = ''flavor'') AS flavor
FROM (
    SELECT 
        field_key,
        string_agg(
            (elem->>''label'') || 
            CASE 
                WHEN elem->>''price'' IS NOT NULL 
                     AND (elem->>''price'')::text != ''0'' 
                     AND (elem->>''price'')::text != ''''
                THEN concat('': '', chr(36)) || (elem->>''price'')::text
                ELSE '''' 
            END, 
            '' • ''
        ) AS display_text
    FROM order_config,
    jsonb_array_elements(options) AS elem
    GROUP BY field_key
) subquery;');


-- Unified INSERT without static_prompt
-- COMPLETE INSERT for order_config - 100% uniform array format + pricing
INSERT INTO order_config (
    field_key, display_name, field_type, options, rules, 
    extraction_hint, is_required, is_active, step_group, sort_order
) VALUES
-- 1. Layers
('layer', 'Number of Layers', 'integer', 
    '[{"label": "1 Layer", "value": "1", "price": 0}, {"label": "2 Layers", "value": "2", "price": 0}, {"label": "3 Layers", "value": "3", "price": 0}]'::jsonb,
    '[]'::jsonb,
    'Extract numbers 1-3 indicating cake layers. Look for "single layer", "double layer", or exact numbers.',
    true, true, 1, 10),

-- 2. Size (layer-dependent validation) - UNIFORM ARRAY FORMAT
('size', 'Cake Size', 'string', 
    '[{"label": "6\"", "value": "6", "price": 0}, {"label": "8\"", "value": "8", "price": 0}, {"label": "9\"", "value": "9", "price": 0}, {"label": "10\"", "value": "10", "price": 0}, {"label": "12\"", "value": "12", "price": 0}, {"label": "Quarter Sheet", "value": "quarter sheet", "price": 0}, {"label": "Half Sheet", "value": "half sheet", "price": 0}]'::jsonb,
    '[{"type": "validation", "depends_on": "layer", "allowed_map": {"1": ["6","8","9","10","12","quarter sheet","half sheet"], "2": ["6","8","9","10","12","quarter sheet","half sheet"], "3": ["6","8"]}}]'::jsonb,
    'Extract cake diameter in inches (6,8,9,10,12) or sheet size (quarter sheet, half sheet).',
    true, true, 1, 20),

-- 3. Flavor
('flavor', 'Cake Flavor', 'string', 
    '[{"label": "Vanilla", "value": "Vanilla", "price": 0}, {"label": "Chocolate", "value": "Chocolate", "price": 0}, {"label": "Red Velvet", "value": "Red Velvet", "price": 0}, {"label": "Carrot", "value": "Carrot", "price": 0}, {"label": "Lemon", "value": "Lemon", "price": 0}, {"label": "Coconut", "value": "Coconut", "price": 0}]'::jsonb,
    '[]'::jsonb,
    'Extract exact flavor name from user message. Match against known flavors.',
    true, true, 1, 30),

-- 4. Theme (free text)
('cake_theme', 'Theme/Design', 'string', '[]'::jsonb,
    '[]'::jsonb,
    'Extract theme, design, character, or decoration description. Free text.',
    true, true, 1, 40),

-- 5. AC Check
('has_ac', 'Air Conditioning', 'boolean', 
    '[{"label": "Yes (Climate Controlled)", "value": true, "price": 0}, {"label": "No (Ambient/Outdoor)", "value": false, "price": 0}]'::jsonb,
    '[]'::jsonb,
    'True for AC/indoor/climate controlled. False for outdoor/ambient.',
    true, true, 1, 50),

-- 6. Delivery Mode
('delivery', 'Delivery Service', 'boolean', 
    '[{"label": "Delivery", "value": true, "price": 0}, {"label": "Pickup", "value": false, "price": 0}]'::jsonb,
    '[]'::jsonb,
    'True for delivery/drop off. False for pickup/self-collect.',
    true, true, 1, 60),

-- 7. Delivery Address (visibility rule)
('delivery_address', 'Delivery Address', 'string', '[]'::jsonb,
    '[{"type": "visibility", "depends_on": "delivery", "operator": "eq", "value": true}]'::jsonb,
    'Extract complete street address when delivery requested.',
    true, true, 1, 70),

-- 8. Event Date (7-day constraint)
('event_date', 'Event Date', 'date', '[]'::jsonb,
    '[{"type": "constraint", "operator": "min_days_ahead", "days": 7}]'::jsonb,
    'Extract event date in YYYY-MM-DD or parse natural language dates.',
    true, true, 1, 80),

-- 9. Client Name
('client_name', 'Your Name', 'string', '[]'::jsonb,
    '[]'::jsonb,
    'Extract customer full name for order.',
    true, true, 3, 90);

