-- Simple fix without enum casting - run this if the above doesn't work
-- Run this in your Supabase SQL Editor

-- Drop the existing trigger and function
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user();

-- Create a simple function that uses text instead of enum
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    user_role_value text;
BEGIN
    -- Extract role from metadata
    user_role_value := COALESCE(NEW.raw_user_meta_data->>'role', 'student');
    
    -- Validate the role value
    IF user_role_value NOT IN ('student', 'teacher', 'super_admin') THEN
        user_role_value := 'student';
    END IF;
    
    -- Insert the profile
    INSERT INTO profiles (id, first_name, last_name, email, role, account_slug)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'first_name', 'User'),
        COALESCE(NEW.raw_user_meta_data->>'last_name', 'Name'),
        NEW.email,
        user_role_value,
        generate_account_slug()
    );
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log the error but don't fail the user creation
        RAISE LOG 'Error creating profile for user %: %', NEW.id, SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

SELECT 'Simple trigger function created successfully' as status;
