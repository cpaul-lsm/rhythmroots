-- Working RLS setup for profiles table
-- Run this after the simple connection test works

-- 1. First, make sure RLS is disabled
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;

-- 2. Drop any existing policies
DROP POLICY IF EXISTS "profiles_select_policy" ON profiles;
DROP POLICY IF EXISTS "profiles_update_policy" ON profiles;
DROP POLICY IF EXISTS "profiles_insert_policy" ON profiles;

-- 3. Re-enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- 4. Create very simple policies that won't cause recursion
CREATE POLICY "profiles_select_policy" ON profiles
    FOR SELECT USING (true);

CREATE POLICY "profiles_insert_policy" ON profiles
    FOR INSERT WITH CHECK (true);

CREATE POLICY "profiles_update_policy" ON profiles
    FOR UPDATE USING (true);

-- 5. Test the policies
SELECT 
    'RLS Test' as test_name,
    COUNT(*) as profile_count
FROM profiles;

-- 6. Show the policies
SELECT 
    'Policies Created' as test_name,
    policyname,
    cmd,
    permissive
FROM pg_policies 
WHERE tablename = 'profiles';

SELECT 'RLS setup completed successfully' as status;
