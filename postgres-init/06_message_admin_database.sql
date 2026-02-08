--- Run as postgres superuser
CREATE DATABASE message_admin OWNER message_admin_user;

-- Switch context to the new database
\c message_admin


-- Standardize the public schema for the new owner
ALTER SCHEMA public OWNER TO message_admin_user;

-- Grant explicit rights just to be safe
GRANT ALL ON SCHEMA public TO message_admin_user;

-- Ensure future tables created by any user are accessible
ALTER DEFAULT PRIVILEGES IN SCHEMA public 
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO message_admin_user;

GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO message_admin_user;

-- Ensure future sequences are accessible
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL ON SEQUENCES TO message_admin_user;


CREATE TABLE IF NOT EXISTS user_states (
    user_id BIGINT PRIMARY KEY,
    current_mode TEXT DEFAULT 'MAIN',
    last_updated TIMESTAMP DEFAULT NOW()
);


CREATE TABLE IF NOT EXISTS user_message_history (
    user_id BIGINT PRIMARY KEY,
    message TEXT DEFAULT 'MAIN',
    last_updated TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255),
    email VARCHAR(255) UNIQUE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Optional: trigger to automatically update updated_at on row change
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();
