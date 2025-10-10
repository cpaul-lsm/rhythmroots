-- Verify lessons data exists and is accessible
-- Run this in Supabase SQL Editor

-- 1. Check if lessons table exists and has data
SELECT 
    'Table Check' as test,
    COUNT(*) as total_lessons
FROM lessons;

-- 2. Show all lessons with their teacher_ids
SELECT 
    'All Lessons' as test,
    id,
    title,
    teacher_id,
    created_at
FROM lessons
ORDER BY created_at DESC;

-- 3. Check specifically for the teacher's lessons
SELECT 
    'Teacher Lessons' as test,
    id,
    title,
    teacher_id,
    created_at
FROM lessons
WHERE teacher_id = '0e7c1b29-0c6c-4e06-a25e-efe254cb5e3f'
ORDER BY created_at DESC;

-- 4. Check if there are any lessons at all (bypassing any potential issues)
SELECT 
    'Raw Count' as test,
    COUNT(*) as count
FROM public.lessons;

-- 5. Check table permissions
SELECT 
    'Permissions' as test,
    table_name,
    privilege_type
FROM information_schema.table_privileges 
WHERE table_name = 'lessons' 
AND grantee = 'authenticated';

-- 6. Check if RLS is actually disabled
SELECT 
    'RLS Status' as test,
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'lessons';
