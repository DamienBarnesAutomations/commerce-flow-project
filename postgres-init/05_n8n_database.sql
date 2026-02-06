--- Run as postgres superuser
CREATE ROLE n8n_user LOGIN PASSWORD 'strong_password_here';
CREATE DATABASE n8n OWNER n8n_user;

-- Switch context to the new database
\c n8n

-- Standardize the public schema for the new owner
ALTER SCHEMA public OWNER TO n8n_user;

-- Grant explicit rights just to be safe
GRANT ALL ON SCHEMA public TO n8n_user;

-- Ensure future tables created by any user are accessible
ALTER DEFAULT PRIVILEGES IN SCHEMA public 
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO n8n_user;
