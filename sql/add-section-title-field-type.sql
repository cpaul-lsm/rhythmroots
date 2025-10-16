-- Add section_title field type to the custom_field_type enum
-- Run this in your Supabase SQL Editor

-- Add section_title to the enum if it doesn't exist
DO $$
BEGIN
    -- Check if section_title value already exists
    IF NOT EXISTS (
        SELECT 1 FROM pg_enum 
        WHERE enumlabel = 'section_title' 
        AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'custom_field_type')
    ) THEN
        -- Add section_title to the enum
        ALTER TYPE custom_field_type ADD VALUE 'section_title';
    END IF;
END$$;

-- Verify the enum now includes section_title
SELECT enumlabel 
FROM pg_enum 
WHERE enumtypid = (SELECT oid FROM pg_type WHERE typname = 'custom_field_type')
ORDER BY enumsortorder;
