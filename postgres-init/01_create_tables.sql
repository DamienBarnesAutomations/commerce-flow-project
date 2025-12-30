-- 1. State management for Telegram Offset
CREATE TABLE IF NOT EXISTS bot_state (
    key TEXT PRIMARY KEY,
    value INTEGER DEFAULT 0
);

-- Initialize the offset if it doesn't exist
INSERT INTO bot_state (key, value) VALUES ('tg_offset', 0) ON CONFLICT DO NOTHING;

-- 2. The Products Table
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    price NUMERIC(10, 2),
    img_url TEXT,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_products_name ON products(name);