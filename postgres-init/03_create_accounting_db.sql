--- Run as postgres superuser
CREATE DATABASE accounting OWNER accounting_user;

-- Switch context to the new database
\c accounting

-- Standardize the public schema for the new owner
ALTER SCHEMA public OWNER TO accounting_user;

-- Grant explicit rights just to be safe
GRANT ALL ON SCHEMA public TO accounting_user;

-- Ensure future tables created by any user are accessible
ALTER DEFAULT PRIVILEGES IN SCHEMA public 
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO accounting_user;

GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO accounting_user;

-- Ensure future sequences are accessible
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL ON SEQUENCES TO accounting_user;


CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TYPE account_type AS ENUM (
  'asset',
  'liability',
  'equity',
  'income',
  'expense'
);

CREATE TYPE normal_balance AS ENUM (
  'debit',
  'credit'
);

-- 1. Table for Categories
CREATE TABLE account_categories (
    id SERIAL PRIMARY KEY,
    type account_type NOT NULL, -- Uses your existing Enum
    name TEXT NOT NULL UNIQUE,
    label TEXT NOT NULL         -- For UI display (e.g., 'Cash & Bank')
);


CREATE TABLE accounts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,

  type account_type NOT NULL,
  normal_balance normal_balance NOT NULL,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE accounts 
ADD COLUMN category_id INTEGER NOT NULL REFERENCES account_categories(id);

INSERT INTO account_categories (type, name, label) VALUES
-- ASSETS
('asset', 'cash', 'Cash and Bank'),
('asset', 'receivables', 'Accounts Receivable'),
('asset', 'inventory', 'Inventory'),
('asset', 'fixed_assets', 'Fixed Assets'),
('asset', 'other_asset', 'Other Assets'),

-- LIABILITIES
('liability', 'payables', 'Accounts Payable'),
('liability', 'credit_card', 'Credit Cards'),
('liability', 'short_term_debt', 'Current Liabilities'),
('liability', 'long_term_debt', 'Long-term Liabilities'),

-- EQUITY
('equity', 'equity', 'Equity / Capital'),
('equity', 'retained_earnings', 'Retained Earnings'),

-- INCOME
('income', 'operating_revenue', 'Operating Revenue'),
('income', 'other_income', 'Other Income'),

-- EXPENSES
('expense', 'cogs', 'Cost of Goods Sold'),
('expense', 'operating_expense', 'Operating Expenses'),
('expense', 'payroll', 'Payroll Expenses'),
('expense', 'taxes', 'Taxes'),
('expense', 'depreciation', 'Depreciation & Amortization');



CREATE TABLE journal_entries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  entry_date DATE NOT NULL,
  reference TEXT,
  description TEXT,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE journal_lines (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  journal_entry_id UUID NOT NULL
    REFERENCES journal_entries(id)
    ON DELETE CASCADE,

  account_id UUID NOT NULL
    REFERENCES accounts(id),

  debit NUMERIC(12,2) NOT NULL DEFAULT 0,
  credit NUMERIC(12,2) NOT NULL DEFAULT 0,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  CHECK (debit >= 0),
  CHECK (credit >= 0),
  CHECK (
    (debit > 0 AND credit = 0)
    OR
    (credit > 0 AND debit = 0)
  )
);

CREATE OR REPLACE FUNCTION enforce_balanced_journal()
RETURNS TRIGGER AS $$
DECLARE
  total_debit NUMERIC(12,2);
  total_credit NUMERIC(12,2);
BEGIN
  SELECT
    COALESCE(SUM(debit), 0),
    COALESCE(SUM(credit), 0)
  INTO total_debit, total_credit
  FROM journal_lines
  WHERE journal_entry_id = NEW.journal_entry_id;

  IF total_debit != total_credit THEN
    RAISE EXCEPTION
      'Journal entry % is not balanced (debit %, credit %)',
      NEW.journal_entry_id, total_debit, total_credit;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER balanced_journal_trigger
AFTER INSERT OR UPDATE ON journal_lines
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION enforce_balanced_journal();

CREATE INDEX idx_journal_lines_account
  ON journal_lines(account_id);

CREATE INDEX idx_journal_lines_entry
  ON journal_lines(journal_entry_id);

CREATE INDEX idx_journal_entries_date
  ON journal_entries(entry_date);

  CREATE VIEW general_ledger AS
SELECT
  a.code AS account_code,
  a.name AS account_name,
  je.entry_date,
  je.reference,
  je.description,
  jl.debit,
  jl.credit
FROM journal_lines jl
JOIN journal_entries je ON je.id = jl.journal_entry_id
JOIN accounts a ON a.id = jl.account_id
ORDER BY a.code, je.entry_date, jl.created_at;

CREATE VIEW trial_balance AS
SELECT
  a.code AS account_code,
  a.name AS account_name,
  SUM(jl.debit) AS total_debit,
  SUM(jl.credit) AS total_credit
FROM journal_lines jl
JOIN accounts a ON a.id = jl.account_id
GROUP BY a.code, a.name
ORDER BY a.code;


DO $$
DECLARE
    cat_cash_id INTEGER;
    cat_sales_id INTEGER;
BEGIN
    -- 1. Look up category IDs
    SELECT id INTO cat_cash_id FROM account_categories WHERE name = 'cash';
    SELECT id INTO cat_sales_id FROM account_categories WHERE name = 'operating_revenue';

    -- 2. Insert Cash Account
    -- We use ON CONFLICT (code) DO NOTHING to prevent errors on restarts
    INSERT INTO accounts (code, name, type, normal_balance, category_id)
    VALUES ('1000', 'Main Cash Account', 'asset', 'debit', cat_cash_id)
    ON CONFLICT (code) DO NOTHING;

    -- 3. Insert Sales Account
    INSERT INTO accounts (code, name, type, normal_balance, category_id)
    VALUES ('4000', 'General Sales', 'income', 'credit', cat_sales_id)
    ON CONFLICT (code) DO NOTHING;

    RAISE NOTICE 'Seed accounts verified/created.';
END $$;

