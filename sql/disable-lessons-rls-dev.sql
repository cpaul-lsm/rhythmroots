-- Disable RLS on lessons table for development
-- This allows unrestricted access to the lessons table

-- 1. Disable RLS on lessons table
ALTER TABLE lessons DISABLE ROW LEVEL SECURITY;

-- 2. Drop all existing policies (they're not needed when RLS is disabled)
DROP POLICY IF EXISTS "Teachers can view their own lessons" ON lessons;
DROP POLICY IF EXISTS "Teachers can insert their own lessons" ON lessons;
DROP POLICY IF EXISTS "Teachers can update their own lessons" ON lessons;
DROP POLICY IF EXISTS "Teachers can delete their own lessons" ON lessons;
DROP POLICY IF EXISTS "Teachers can access their lessons" ON lessons;

-- 3. Verify RLS is disabled
SELECT 
    'RLS Status' as check_type,
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'lessons';

-- 4. Test that we can now access lessons
SELECT 
    'Test Access' as check_type,
    COUNT(*) as total_lessons,
    array_agg(teacher_id) as teacher_ids
FROM lessons;

-- 5. Show all lessons for the specific teacher
SELECT 
    'Teacher Lessons' as check_type,
    id,
    title,
    teacher_id,
    created_at
FROM lessons
WHERE teacher_id = '0e7c1b29-0c6c-4e06-a25e-efe254cb5e3f'
ORDER BY created_at DESC;
