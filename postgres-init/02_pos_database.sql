--- Run as postgres superuser
CREATE ROLE pos_user LOGIN PASSWORD 'strong_password_here';
CREATE DATABASE pos OWNER pos_user;

-- Switch context to the new database
\c pos

-- Standardize the public schema for the new owner
ALTER SCHEMA public OWNER TO pos_user;

-- Grant explicit rights just to be safe
GRANT ALL ON SCHEMA public TO pos_user;

-- Ensure future tables created by any user are accessible
ALTER DEFAULT PRIVILEGES IN SCHEMA public 
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO pos_user;

-- 4. PRO-TIP: Fix it for ALL FUTURE sequences you might create
ALTER DEFAULT PRIVILEGES IN SCHEMA public 
GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO pos_user;


-- 2. The Products Table
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    price NUMERIC(10, 2),
    img_url TEXT,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
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