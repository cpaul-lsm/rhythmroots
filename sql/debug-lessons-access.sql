-- Comprehensive debugging script for lessons table access
-- Run this in Supabase SQL Editor to diagnose the issue

-- 1. Check if RLS is enabled on lessons table
SELECT 
    'RLS Status' as check_type,
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'lessons';

-- 2. Check all policies on lessons table
SELECT 
    'Current Policies' as check_type,
    policyname,
    permissive,
    roles,
    cmd as operation,
    qual as condition
FROM pg_policies 
WHERE tablename = 'lessons'
ORDER BY policyname;

-- 3. Check if lessons exist at all (bypassing RLS)
SET row_security = off;
SELECT 
    'Lessons Count (RLS OFF)' as check_type,
    COUNT(*) as total_lessons
FROM lessons;
SET row_security = on;

-- 4. Check what teacher_ids exist in lessons
SET row_security = off;
SELECT 
    'Teacher IDs in lessons' as check_type,
    teacher_id,
    COUNT(*) as lesson_count
FROM lessons 
GROUP BY teacher_id;
SET row_security = on;

-- 5. Check current auth context
SELECT 
    'Auth Context' as check_type,
    auth.uid() as current_user_id,
    auth.role() as current_role;

-- 6. Test direct query with current user
SELECT 
    'Direct Query Test' as check_type,
    COUNT(*) as accessible_lessons
FROM lessons
WHERE teacher_id = auth.uid()::text::uuid;

-- 7. Test with string conversion
SELECT 
    'String Conversion Test' as check_type,
    COUNT(*) as accessible_lessons
FROM lessons
WHERE teacher_id = auth.uid()::text;

-- 8. Check if there are any lessons for the specific teacher ID
SET row_security = off;
SELECT 
    'Specific Teacher Check' as check_type,
    COUNT(*) as lessons_for_teacher
FROM lessons
WHERE teacher_id = '0e7c1b29-0c6c-4e06-a25e-efe254cb5e3f';
SET row_security = on;

-- 9. Disable RLS temporarily to test
ALTER TABLE lessons DISABLE ROW LEVEL SECURITY;

-- 10. Test query without RLS
SELECT 
    'Without RLS' as check_type,
    COUNT(*) as total_lessons,
    array_agg(teacher_id) as teacher_ids
FROM lessons;

-- 11. Re-enable RLS
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;

-- 12. Create a simple test policy
DROP POLICY IF EXISTS "test_policy" ON lessons;
CREATE POLICY "test_policy" ON lessons
    FOR ALL USING (true);

-- 13. Test with the simple policy
SELECT 
    'With Simple Policy' as check_type,
    COUNT(*) as accessible_lessons
FROM lessons;

-- 14. Remove test policy and create proper one
DROP POLICY IF EXISTS "test_policy" ON lessons;
CREATE POLICY "Teachers can access their lessons" ON lessons
    FOR ALL USING (
        teacher_id = auth.uid()
    );

-- 15. Final test
SELECT 
    'Final Test' as check_type,
    COUNT(*) as accessible_lessons
FROM lessons;
