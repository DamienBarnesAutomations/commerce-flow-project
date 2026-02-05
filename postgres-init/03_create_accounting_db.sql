CREATE ROLE accounting_user LOGIN PASSWORD 'strong_password_here';
CREATE DATABASE accounting OWNER accounting_user;

\connect accounting

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

CREATE TABLE accounts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,

  type account_type NOT NULL,
  normal_balance normal_balance NOT NULL,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

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