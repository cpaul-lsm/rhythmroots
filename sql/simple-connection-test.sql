-- Simple connection test without any inserts
-- Run this in your Supabase SQL Editor

-- 1. Disable RLS on profiles table
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;

-- 2. Test basic query
SELECT 
    'Basic Query Test' as test_name,
    COUNT(*) as profile_count
FROM profiles;

-- 3. Test selecting specific columns
SELECT 
    'Column Selection Test' as test_name,
    id,
    first_name,
    last_name,
    email,
    role
FROM profiles
LIMIT 3;

-- 4. Check table structure
SELECT 
    'Table Structure' as test_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'profiles' 
ORDER BY ordinal_position;

-- 5. Check if there are any users in auth.users
SELECT 
    'Auth Users Check' as test_name,
    COUNT(*) as user_count
FROM auth.users;

-- 6. Show any existing profiles
SELECT 
    'Existing Profiles' as test_name,
    p.id,
    p.first_name,
    p.last_name,
    p.email,
    p.role,
    u.email as auth_email
FROM profiles p
LEFT JOIN auth.users u ON p.id = u.id
LIMIT 5;

SELECT 'Simple connection test completed' as status;
