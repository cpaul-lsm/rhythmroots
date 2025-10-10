-- Complete RLS fix for all tables
-- Run this in your Supabase SQL Editor

-- 1. Drop all existing policies to prevent recursion
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
DROP POLICY IF EXISTS "Enable read access for all users" ON profiles;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON profiles;
DROP POLICY IF EXISTS "Enable update for users based on user_id" ON profiles;

-- 2. Disable RLS on all tables temporarily
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE courses DISABLE ROW LEVEL SECURITY;
ALTER TABLE lessons DISABLE ROW LEVEL SECURITY;
ALTER TABLE course_lessons DISABLE ROW LEVEL SECURITY;

-- 3. Re-enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_lessons ENABLE ROW LEVEL SECURITY;

-- 4. Create simple, non-recursive policies for profiles
CREATE POLICY "profiles_select_policy" ON profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "profiles_update_policy" ON profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "profiles_insert_policy" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- 5. Create basic policies for other tables
CREATE POLICY "courses_select_policy" ON courses
    FOR SELECT USING (true);

CREATE POLICY "courses_insert_policy" ON courses
    FOR INSERT WITH CHECK (auth.uid() = teacher_id);

CREATE POLICY "courses_update_policy" ON courses
    FOR UPDATE USING (auth.uid() = teacher_id);

CREATE POLICY "lessons_select_policy" ON lessons
    FOR SELECT USING (true);

CREATE POLICY "lessons_insert_policy" ON lessons
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "lessons_update_policy" ON lessons
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "course_lessons_select_policy" ON course_lessons
    FOR SELECT USING (true);

CREATE POLICY "course_lessons_insert_policy" ON course_lessons
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "course_lessons_update_policy" ON course_lessons
    FOR UPDATE USING (auth.role() = 'authenticated');

-- 6. Test the setup
SELECT 'RLS policies created successfully' as status;

-- 7. Test if we can query profiles
SELECT COUNT(*) as profile_count FROM profiles;
