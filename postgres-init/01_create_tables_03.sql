-- Unified rules validation for new schema
CREATE OR REPLACE FUNCTION validate_rules_array(rules jsonb) 
RETURNS boolean AS $$
DECLARE
    rule jsonb;
    rule_type text;
    depends_on_field text;
BEGIN
    -- 1. NULL or empty array = valid
    IF rules IS NULL OR rules = '[]'::jsonb THEN 
        RETURN TRUE; 
    END IF;

    -- 2. MUST be array - no single objects allowed
    IF jsonb_typeof(rules) != 'array' THEN
        RETURN FALSE;
    END IF;

    -- 3. Validate each rule
    FOR rule IN SELECT * FROM jsonb_array_elements(rules) LOOP
        rule_type := rule->>'type';
        
        -- Must have type
        IF rule_type IS NULL THEN RETURN FALSE; END IF;

        -- VISIBILITY: requires depends_on, operator, value
        IF rule_type = 'visibility' THEN
            IF NOT (rule ? 'depends_on' AND rule ? 'operator' AND rule ? 'value') THEN
                RETURN FALSE;
            END IF;
            -- Check field exists (insert order workaround below)
        END IF;

        -- VALIDATION: requires depends_on, allowed_map
        IF rule_type = 'validation' THEN
            IF NOT (rule ? 'depends_on' AND rule ? 'allowed_map') THEN
                RETURN FALSE;
            END IF;
        END IF;

        -- CONSTRAINT: requires operator + params
        IF rule_type = 'constraint' THEN
            IF NOT (rule ? 'operator') THEN RETURN FALSE; END IF;
        END IF;

        -- Unknown types forbidden
        IF rule_type NOT IN ('visibility', 'validation', 'constraint') THEN
            RETURN FALSE;
        END IF;
    END LOOP;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

ALTER TABLE order_config ADD CONSTRAINT enforce_rules_integrity 
CHECK (validate_rules_array(rules));

-- Index for faster validation queries
CREATE INDEX IF NOT EXISTS idx_order_config_rules_gin ON order_config USING GIN (rules);


CREATE OR REPLACE FUNCTION validate_options_pricing(opts jsonb) 
RETURNS boolean AS $$
DECLARE
    item jsonb;
BEGIN
    -- If it's empty or null, that's fine (e.g., for text input fields)
    IF opts IS NULL OR jsonb_array_length(opts) = 0 THEN 
        RETURN TRUE; 
    END IF;

    -- Iterate through each object in the array
    FOR item IN SELECT * FROM jsonb_array_elements(opts) LOOP
        IF NOT (item ? 'value' AND item ? 'price') THEN
            RETURN FALSE;
        END IF;
        
        IF jsonb_typeof(item->'price') != 'number' THEN
            RETURN FALSE;
        END IF;
    END LOOP;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

ALTER TABLE order_config
ADD CONSTRAINT enforce_options_pricing 
CHECK (validate_options_pricing(options));