-- Force disable RLS on lessons table
-- This will definitely disable RLS

-- 1. Disable RLS on lessons table
ALTER TABLE public.lessons DISABLE ROW LEVEL SECURITY;

-- 2. Verify RLS is disabled
SELECT 
    'RLS Status After Disable' as test,
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'lessons';

-- 3. Test access to lessons
SELECT 
    'Test Access' as test,
    COUNT(*) as total_lessons
FROM public.lessons;

-- 4. Show all lessons
SELECT 
    'All Lessons' as test,
    id,
    title,
    teacher_id,
    created_at
FROM public.lessons
ORDER BY created_at DESC;

-- 5. Show lessons for specific teacher
SELECT 
    'Teacher Lessons' as test,
    id,
    title,
    teacher_id,
    created_at
FROM public.lessons
WHERE teacher_id = '0e7c1b29-0c6c-4e06-a25e-efe254cb5e3f'
ORDER BY created_at DESC;
