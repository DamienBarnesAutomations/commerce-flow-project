--- Run as postgres superuser
CREATE ROLE message_admin_user LOGIN PASSWORD 'strong_password_here';
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
