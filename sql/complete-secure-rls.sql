-- Complete secure RLS setup for all tables
-- Run this to fix all "unrestricted" warnings

-- 1. PROFILES TABLE - Most important for security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "users_read_own_profile" ON profiles;
DROP POLICY IF EXISTS "users_update_own_profile" ON profiles;
DROP POLICY IF EXISTS "system_insert_profiles" ON profiles;

-- Create secure policies for profiles
CREATE POLICY "users_read_own_profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "users_update_own_profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "system_insert_profiles" ON profiles
    FOR INSERT WITH CHECK (true);

-- 2. COURSES TABLE
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "courses_select_policy" ON courses;
DROP POLICY IF EXISTS "courses_insert_policy" ON courses;
DROP POLICY IF EXISTS "courses_update_policy" ON courses;

CREATE POLICY "courses_public_read" ON courses
    FOR SELECT USING (is_published = true);

CREATE POLICY "teachers_manage_own_courses" ON courses
    FOR ALL USING (auth.uid() = teacher_id);

-- 3. LESSONS TABLE
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "lessons_select_policy" ON lessons;
DROP POLICY IF EXISTS "lessons_insert_policy" ON lessons;
DROP POLICY IF EXISTS "lessons_update_policy" ON lessons;

CREATE POLICY "lessons_public_read" ON lessons
    FOR SELECT USING (true);

CREATE POLICY "authenticated_users_manage_lessons" ON lessons
    FOR ALL USING (auth.role() = 'authenticated');

-- 4. COURSE_LESSONS TABLE
ALTER TABLE course_lessons ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "course_lessons_select_policy" ON course_lessons;
DROP POLICY IF EXISTS "course_lessons_insert_policy" ON course_lessons;
DROP POLICY IF EXISTS "course_lessons_update_policy" ON course_lessons;

CREATE POLICY "course_lessons_public_read" ON course_lessons
    FOR SELECT USING (true);

CREATE POLICY "authenticated_users_manage_course_lessons" ON course_lessons
    FOR ALL USING (auth.role() = 'authenticated');

-- 5. Test all tables
SELECT 
    'RLS Status Check' as test_name,
    schemaname, 
    tablename, 
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename IN ('profiles', 'courses', 'lessons', 'course_lessons')
ORDER BY tablename;

-- 6. Test that we can still query profiles
SELECT 
    'Profiles Query Test' as test_name,
    COUNT(*) as profile_count
FROM profiles;

SELECT 'Complete secure RLS setup finished' as status;
