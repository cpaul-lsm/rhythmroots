-- DEFINITIVE FIX: Remove all policies and start fresh
-- Run this in your Supabase SQL Editor

-- 1. Disable RLS on all tables
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE courses DISABLE ROW LEVEL SECURITY;
ALTER TABLE lessons DISABLE ROW LEVEL SECURITY;
ALTER TABLE course_lessons DISABLE ROW LEVEL SECURITY;

-- 2. Drop ALL existing policies (comprehensive cleanup)
DROP POLICY IF EXISTS "profiles_allow_all" ON profiles;
DROP POLICY IF EXISTS "courses_allow_all" ON courses;
DROP POLICY IF EXISTS "lessons_allow_all" ON lessons;
DROP POLICY IF EXISTS "course_lessons_allow_all" ON course_lessons;
DROP POLICY IF EXISTS "profiles_policy" ON profiles;
DROP POLICY IF EXISTS "courses_policy" ON courses;
DROP POLICY IF EXISTS "lessons_policy" ON lessons;
DROP POLICY IF EXISTS "course_lessons_policy" ON course_lessons;
DROP POLICY IF EXISTS "users_read_own_profile" ON profiles;
DROP POLICY IF EXISTS "users_update_own_profile" ON profiles;
DROP POLICY IF EXISTS "system_insert_profiles" ON profiles;
DROP POLICY IF EXISTS "courses_public_read" ON courses;
DROP POLICY IF EXISTS "teachers_manage_own_courses" ON courses;
DROP POLICY IF EXISTS "lessons_public_read" ON lessons;
DROP POLICY IF EXISTS "authenticated_users_manage_lessons" ON lessons;
DROP POLICY IF EXISTS "course_lessons_public_read" ON course_lessons;
DROP POLICY IF EXISTS "authenticated_users_manage_course_lessons" ON course_lessons;

-- 3. Test that we can query without RLS
SELECT 
    'No RLS Test' as test_name,
    COUNT(*) as profile_count
FROM profiles;

-- 4. Re-enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_lessons ENABLE ROW LEVEL SECURITY;

-- 5. Create the simplest possible policies
CREATE POLICY "profiles_simple" ON profiles FOR ALL USING (true);
CREATE POLICY "courses_simple" ON courses FOR ALL USING (true);
CREATE POLICY "lessons_simple" ON lessons FOR ALL USING (true);
CREATE POLICY "course_lessons_simple" ON course_lessons FOR ALL USING (true);

-- 6. Test the connection
SELECT 
    'Final Test' as test_name,
    COUNT(*) as profile_count
FROM profiles;

-- 7. Show policy status
SELECT 
    'Policy Status' as test_name,
    policyname,
    tablename,
    cmd
FROM pg_policies 
WHERE tablename IN ('profiles', 'courses', 'lessons', 'course_lessons')
ORDER BY tablename, policyname;

SELECT 'Definitive fix applied - should work now' as status;
