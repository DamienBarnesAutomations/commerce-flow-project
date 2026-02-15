\c custom_order

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
    MAX(display_label) FILTER (WHERE field_key = ''layers'') AS layers,
    MAX(display_label) FILTER (WHERE field_key = ''size'') AS size,
    MAX(display_label) FILTER (WHERE field_key = ''flavor'') AS flavor,
    MAX(display_label) FILTER (WHERE field_key = ''cake_theme'') AS cake_theme,
    MAX(display_label) FILTER (WHERE field_key = ''has_ac'') AS has_ac,
    MAX(display_label) FILTER (WHERE field_key = ''delivery'') AS delivery_method,
    MAX(display_label) FILTER (WHERE field_key = ''delivery_address'') AS delivery_address,
    
    MAX(price_increment) FILTER (WHERE field_key = ''layers'') AS price_layers,
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
    MAX(display_label) FILTER (WHERE field_key = ''layers'') AS layers,
    MAX(display_label) FILTER (WHERE field_key = ''size'') AS size,
    MAX(display_label) FILTER (WHERE field_key = ''flavor'') AS flavor,
    MAX(display_label) FILTER (WHERE field_key = ''cake_theme'') AS cake_theme,
    MAX(display_label) FILTER (WHERE field_key = ''has_ac'') AS has_ac,
    MAX(display_label) FILTER (WHERE field_key = ''delivery'') AS delivery_method,
    MAX(display_label) FILTER (WHERE field_key = ''delivery_address'') AS delivery_address,
    MAX(price_increment) FILTER (WHERE field_key = ''layers'') AS price_layer,
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
{{layers}}

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
    MAX(display_text) FILTER (WHERE field_key = ''layers'') AS layers,
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