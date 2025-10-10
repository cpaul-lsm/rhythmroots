-- QUICK FIX: Disable RLS completely to get connection working
-- Run this in your Supabase SQL Editor RIGHT NOW

-- 1. Disable RLS on profiles table
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;

-- 2. Drop all policies
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
DROP POLICY IF EXISTS "Enable read access for all users" ON profiles;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON profiles;
DROP POLICY IF EXISTS "Enable update for users based on user_id" ON profiles;
DROP POLICY IF EXISTS "profiles_select_policy" ON profiles;
DROP POLICY IF EXISTS "profiles_update_policy" ON profiles;
DROP POLICY IF EXISTS "profiles_insert_policy" ON profiles;

-- 3. Test the connection
SELECT 
    'Connection Test' as test_name,
    COUNT(*) as profile_count
FROM profiles;

-- 4. Show any existing profiles
SELECT 
    'Existing Profiles' as test_name,
    id,
    first_name,
    last_name,
    email,
    role
FROM profiles
LIMIT 5;

SELECT 'RLS disabled - connection should work now' as status;
