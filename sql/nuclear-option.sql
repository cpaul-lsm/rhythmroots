-- NUCLEAR OPTION: Completely disable RLS to get working
-- Run this if the definitive fix still doesn't work

-- 1. Disable RLS on all tables
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE courses DISABLE ROW LEVEL SECURITY;
ALTER TABLE lessons DISABLE ROW LEVEL SECURITY;
ALTER TABLE course_lessons DISABLE ROW LEVEL SECURITY;

-- 2. Drop ALL policies
DROP POLICY IF EXISTS "profiles_simple" ON profiles;
DROP POLICY IF EXISTS "courses_simple" ON courses;
DROP POLICY IF EXISTS "lessons_simple" ON lessons;
DROP POLICY IF EXISTS "course_lessons_simple" ON course_lessons;

-- 3. Test connection
SELECT 
    'Nuclear Option Test' as test_name,
    COUNT(*) as profile_count
FROM profiles;

-- 4. Show RLS status
SELECT 
    'RLS Status' as test_name,
    schemaname, 
    tablename, 
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename IN ('profiles', 'courses', 'lessons', 'course_lessons')
ORDER BY tablename;

SELECT 'Nuclear option applied - RLS completely disabled' as status;
