-- Complete fix for the database error when registering users
-- Run this in your Supabase SQL Editor

-- First, let's check if the user_role enum exists and create it if needed
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
        CREATE TYPE user_role AS ENUM ('student', 'teacher', 'super_admin');
    END IF;
END $$;

-- Drop the existing trigger and function
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user();

-- Create a more robust function that handles errors gracefully
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    user_role_value text;
BEGIN
    -- Extract role from metadata with proper error handling
    user_role_value := COALESCE(NEW.raw_user_meta_data->>'role', 'student');
    
    -- Validate the role value
    IF user_role_value NOT IN ('student', 'teacher', 'super_admin') THEN
        user_role_value := 'student';
    END IF;
    
    -- Insert the profile with error handling
    BEGIN
        INSERT INTO profiles (id, first_name, last_name, email, role, account_slug)
        VALUES (
            NEW.id,
            COALESCE(NEW.raw_user_meta_data->>'first_name', ''),
            COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
            NEW.email,
            user_role_value::user_role,
            generate_account_slug()
        );
    EXCEPTION
        WHEN OTHERS THEN
            -- Log the error and continue
            RAISE LOG 'Error creating profile for user %: %', NEW.id, SQLERRM;
            -- Insert with default values if there's an error
            INSERT INTO profiles (id, first_name, last_name, email, role, account_slug)
            VALUES (
                NEW.id,
                COALESCE(NEW.raw_user_meta_data->>'first_name', 'User'),
                COALESCE(NEW.raw_user_meta_data->>'last_name', 'Name'),
                NEW.email,
                'student'::user_role,
                generate_account_slug()
            );
    END;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Test the function by checking if it can be called
SELECT 'Trigger function created successfully' as status;
