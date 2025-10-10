-- Test query to check if lessons are accessible and RLS is working
-- Run this in Supabase SQL Editor to debug the lessons visibility issue

-- 1. Check if lessons exist with teacher_id
SELECT 
    'Lessons with teacher_id' as test,
    COUNT(*) as count,
    array_agg(id) as lesson_ids
FROM lessons 
WHERE teacher_id IS NOT NULL;

-- 2. Check all lessons (without RLS filter)
SELECT 
    'All lessons' as test,
    COUNT(*) as count,
    array_agg(id) as lesson_ids
FROM lessons;

-- 3. Check if RLS is enabled on lessons table
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'lessons';

-- 4. Check RLS policies on lessons table
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'lessons';

-- 5. Test a simple select with current user context
SELECT 
    'Current user context test' as test,
    auth.uid() as current_user_id,
    COUNT(*) as accessible_lessons
FROM lessons
WHERE teacher_id = auth.uid()::text::uuid;
