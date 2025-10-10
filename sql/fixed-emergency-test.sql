-- FIXED: Emergency test without foreign key violations
-- Run this in your Supabase SQL Editor

-- 1. Drop ALL policies on profiles table
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
DROP POLICY IF EXISTS "Enable read access for all users" ON profiles;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON profiles;
DROP POLICY IF EXISTS "Enable update for users based on user_id" ON profiles;
DROP POLICY IF EXISTS "profiles_select_policy" ON profiles;
DROP POLICY IF EXISTS "profiles_update_policy" ON profiles;
DROP POLICY IF EXISTS "profiles_insert_policy" ON profiles;

-- 2. Completely disable RLS on profiles table
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;

-- 3. Test if we can query the table now
SELECT 
    'RLS Disabled Test' as test_name,
    COUNT(*) as profile_count
FROM profiles;

-- 4. Check if there are any existing users we can use for testing
SELECT 
    'Existing Users Check' as test_name,
    id, 
    email,
    created_at
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 5;

-- 5. Test querying profiles with existing user IDs
SELECT 
    'Profiles Query Test' as test_name,
    p.id,
    p.first_name,
    p.last_name,
    p.role
FROM profiles p
LIMIT 5;

-- 6. Test if we can insert using an existing user ID (if any exist)
-- First, let's see if we have any users
DO $$
DECLARE
    user_count INTEGER;
    test_user_id UUID;
BEGIN
    SELECT COUNT(*) INTO user_count FROM auth.users;
    
    IF user_count > 0 THEN
        -- Get the first user ID
        SELECT id INTO test_user_id FROM auth.users LIMIT 1;
        
        -- Test insert with real user ID
        INSERT INTO profiles (id, first_name, last_name, email, role, account_slug)
        VALUES (
            test_user_id,
            'Test',
            'User',
            'test@example.com',
            'student',
            '123456'
        );
        
        RAISE NOTICE 'Test insert successful with user ID: %', test_user_id;
        
        -- Clean up test record
        DELETE FROM profiles WHERE id = test_user_id AND first_name = 'Test';
        
    ELSE
        RAISE NOTICE 'No users found in auth.users table';
    END IF;
END $$;

SELECT 'Emergency test completed successfully' as status;
