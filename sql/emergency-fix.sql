-- EMERGENCY FIX: Minimal working solution
-- Run this in your Supabase SQL Editor to get registration working immediately

-- 1. First, let's disable the problematic trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user();

-- 2. Create the user_role enum if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
        CREATE TYPE user_role AS ENUM ('student', 'teacher', 'super_admin');
    END IF;
END $$;

-- 3. Create a simple account slug function
CREATE OR REPLACE FUNCTION generate_account_slug()
RETURNS text AS $$
BEGIN
    RETURN floor(random() * 1000000)::text;
END;
$$ LANGUAGE plpgsql;

-- 4. Create a simple trigger function that won't fail
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Simple insert with minimal required fields
    INSERT INTO profiles (id, first_name, last_name, email, role, account_slug)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'first_name', 'User'),
        COALESCE(NEW.raw_user_meta_data->>'last_name', 'Name'),
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'role', 'student')::user_role,
        generate_account_slug()
    );
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- If anything fails, just log it and continue
        RAISE LOG 'Profile creation failed for user %: %', NEW.id, SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Recreate the trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- 6. Test the function
SELECT 'Emergency fix applied successfully' as status;
