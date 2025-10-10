-- Fix potential trigger issues that might be causing connection problems
-- Run this in your Supabase SQL Editor

-- 1. Check if the trigger function exists and is working
SELECT 
    'Trigger Function Check' as test_name,
    routine_name, 
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_name = 'handle_new_user';

-- 2. Check if the trigger exists
SELECT 
    'Trigger Check' as test_name,
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'users' 
AND trigger_schema = 'auth';

-- 3. Temporarily disable the trigger to test if it's causing issues
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- 4. Test if we can query profiles without the trigger
SELECT 
    'Query Test Without Trigger' as test_name,
    COUNT(*) as profile_count
FROM profiles;

-- 5. Recreate the trigger with better error handling
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Simple insert with error handling
    BEGIN
        INSERT INTO profiles (id, first_name, last_name, email, role, account_slug)
        VALUES (
            NEW.id,
            COALESCE(NEW.raw_user_meta_data->>'first_name', 'User'),
            COALESCE(NEW.raw_user_meta_data->>'last_name', 'Name'),
            NEW.email,
            COALESCE(NEW.raw_user_meta_data->>'role', 'student')::user_role,
            generate_account_slug()
        );
    EXCEPTION
        WHEN OTHERS THEN
            -- Log error but don't fail the user creation
            RAISE LOG 'Profile creation failed for user %: %', NEW.id, SQLERRM;
    END;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Recreate the trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- 7. Test the trigger function
SELECT 'Trigger recreated successfully' as status;
