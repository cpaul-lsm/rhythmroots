-- Add email and phone field types to the custom_field_type enum
-- This allows fields to have proper validation for email and phone inputs

-- Add email and phone to the enum if they don't exist
DO $$
BEGIN
    -- Add email type
    IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'email' AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'custom_field_type')) THEN
        ALTER TYPE custom_field_type ADD VALUE 'email';
    END IF;
    
    -- Add phone type
    IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'phone' AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'custom_field_type')) THEN
        ALTER TYPE custom_field_type ADD VALUE 'phone';
    END IF;
END $$;
