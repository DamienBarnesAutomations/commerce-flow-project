ALTER TABLE chat_sessions
ADD COLUMN welcome_message_sent BOOLEAN NOT NULL DEFAULT FALSE;

UPDATE order_config
SET options = '[
    {"label": "Vanilla Bean", "value": "vanilla bean"},
    {"label": "Carrot", "value": "carrot"},
    {"label": "Lemon", "value": "lemon"},
    {"label": "Coconut", "value": "coconut"},
    {"label": "Marble", "value": "marble"},
    {"label": "Chocolate", "value": "chocolate"},
    {"label": "Strawberry", "value": "strawberry"},
    {"label": "Cookies and Cream", "value": "cookies and cream"},
    {"label": "Red Velvet", "value": "red velvet"},
    {"label": "Banana Bread", "value": "banana bread"},
    {"label": "Caribbean Fruit/ Rum", "value": "caribbean fruit/ rum"},
    {"label": "Butter Pecan", "value": "butter pecan"},
    {"label": "White Chocolate Sponge", "value": "white chocolate sponge"},
    {"label": "Pineapple Sponge", "value": "pineapple sponge"}
]'::jsonb
WHERE field_key = 'flavor';