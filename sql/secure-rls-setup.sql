-- Secure RLS setup for profiles table
-- Run this in your Supabase SQL Editor to fix the "unrestricted" warning

-- 1. First, let's see what we have
SELECT 
    'Current RLS Status' as test_name,
    schemaname, 
    tablename, 
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'profiles';

-- 2. Drop any existing policies
DROP POLICY IF EXISTS "profiles_select_policy" ON profiles;
DROP POLICY IF EXISTS "profiles_update_policy" ON profiles;
DROP POLICY IF EXISTS "profiles_insert_policy" ON profiles;

-- 3. Re-enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- 4. Create secure but functional policies
-- Allow users to read their own profile
CREATE POLICY "users_read_own_profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

-- Allow users to update their own profile
CREATE POLICY "users_update_own_profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

-- Allow system to insert profiles (for registration)
CREATE POLICY "system_insert_profiles" ON profiles
    FOR INSERT WITH CHECK (true);

-- 5. Test the policies work
SELECT 
    'RLS Test' as test_name,
    COUNT(*) as profile_count
FROM profiles;

-- 6. Show the new policies
SELECT 
    'Policies Created' as test_name,
    policyname,
    cmd,
    permissive,
    roles
FROM pg_policies 
WHERE tablename = 'profiles';

-- 7. Check RLS status
SELECT 
    'Final RLS Status' as test_name,
    schemaname, 
    tablename, 
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'profiles';

SELECT 'Secure RLS setup completed - warning should be gone' as status;
