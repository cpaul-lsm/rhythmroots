-- EMERGENCY FIX: Disable RLS temporarily to get connection working
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

-- 4. Check if we can insert a test record
INSERT INTO profiles (id, first_name, last_name, email, role, account_slug)
VALUES (
    '00000000-0000-0000-0000-000000000000',
    'Test',
    'User',
    'test@example.com',
    'student',
    '123456'
);

-- 5. Verify the insert worked
SELECT 
    'Insert Test' as test_name,
    COUNT(*) as profile_count
FROM profiles;

-- 6. Clean up test record
DELETE FROM profiles WHERE id = '00000000-0000-0000-0000-000000000000';

SELECT 'Emergency fix applied - RLS disabled on profiles table' as status;
