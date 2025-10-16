-- Add textarea field type to the custom_field_type enum
-- Run this in your Supabase SQL Editor

-- Add textarea to the enum if it doesn't exist
DO $$
BEGIN
    -- Check if textarea value already exists
    IF NOT EXISTS (
        SELECT 1 FROM pg_enum 
        WHERE enumlabel = 'textarea' 
        AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'custom_field_type')
    ) THEN
        -- Add textarea to the enum
        ALTER TYPE custom_field_type ADD VALUE 'textarea';
    END IF;
END$$;

-- Verify the enum now includes textarea
SELECT enumlabel 
FROM pg_enum 
WHERE enumtypid = (SELECT oid FROM pg_type WHERE typname = 'custom_field_type')
ORDER BY enumsortorder;
