-- Comprehensive diagnostic for connection issues
-- Run this in your Supabase SQL Editor to identify the problem

-- 1. Check if profiles table exists and its structure
SELECT 
    'Table Structure Check' as test_name,
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'profiles' 
ORDER BY ordinal_position;

-- 2. Check RLS status
SELECT 
    'RLS Status Check' as test_name,
    schemaname, 
    tablename, 
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'profiles';

-- 3. Check existing policies
SELECT 
    'Existing Policies Check' as test_name,
    policyname, 
    permissive, 
    roles, 
    cmd, 
    qual
FROM pg_policies 
WHERE tablename = 'profiles';

-- 4. Check if we can query the table directly (bypass RLS)
SET row_security = off;
SELECT 
    'Direct Query Test' as test_name,
    COUNT(*) as profile_count
FROM profiles;
SET row_security = on;

-- 5. Check auth.uid() function
SELECT 
    'Auth UID Test' as test_name,
    auth.uid() as current_user_id;

-- 6. Check if there are any profiles
SELECT 
    'Profile Count Test' as test_name,
    COUNT(*) as total_profiles,
    COUNT(CASE WHEN id IS NOT NULL THEN 1 END) as profiles_with_id
FROM profiles;

-- 7. Test a simple insert (this might fail but will show the error)
-- Uncomment the next lines to test:
/*
INSERT INTO profiles (id, first_name, last_name, email, role, account_slug)
VALUES (
    '00000000-0000-0000-0000-000000000000',
    'Test',
    'User',
    'test@example.com',
    'student',
    '123456'
);
*/
