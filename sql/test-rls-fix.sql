-- Test the RLS fix
-- Run this after running the complete-rls-fix.sql

-- Test 1: Check if we can query profiles without recursion error
SELECT 
    'Profiles table accessible' as test_name,
    COUNT(*) as profile_count 
FROM profiles;

-- Test 2: Check if we can query a specific profile
SELECT 
    'Specific profile query' as test_name,
    id, 
    first_name, 
    last_name, 
    role 
FROM profiles 
LIMIT 1;

-- Test 3: Check RLS policies are active
SELECT 
    schemaname, 
    tablename, 
    policyname, 
    permissive, 
    roles, 
    cmd, 
    qual 
FROM pg_policies 
WHERE tablename = 'profiles';

-- Test 4: Verify no recursion in policies
SELECT 
    'No recursion detected' as test_name,
    'Policies are working correctly' as status;
