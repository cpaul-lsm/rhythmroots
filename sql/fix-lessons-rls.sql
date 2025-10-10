-- Fix RLS policies for lessons table
-- This script will ensure teachers can see their own lessons

-- 1. Check current RLS status
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'lessons';

-- 2. Check existing policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd as operation,
    qual as condition
FROM pg_policies 
WHERE tablename = 'lessons'
ORDER BY policyname;

-- 3. Drop existing policies if they exist
DROP POLICY IF EXISTS "Teachers can view their own lessons" ON lessons;
DROP POLICY IF EXISTS "Teachers can insert their own lessons" ON lessons;
DROP POLICY IF EXISTS "Teachers can update their own lessons" ON lessons;
DROP POLICY IF EXISTS "Teachers can delete their own lessons" ON lessons;

-- 4. Create proper RLS policies for lessons
-- Policy: Teachers can view their own lessons
CREATE POLICY "Teachers can view their own lessons" ON lessons
    FOR SELECT USING (
        teacher_id = auth.uid()::text::uuid
    );

-- Policy: Teachers can insert their own lessons
CREATE POLICY "Teachers can insert their own lessons" ON lessons
    FOR INSERT WITH CHECK (
        teacher_id = auth.uid()::text::uuid
    );

-- Policy: Teachers can update their own lessons
CREATE POLICY "Teachers can update their own lessons" ON lessons
    FOR UPDATE USING (
        teacher_id = auth.uid()::text::uuid
    );

-- Policy: Teachers can delete their own lessons
CREATE POLICY "Teachers can delete their own lessons" ON lessons
    FOR DELETE USING (
        teacher_id = auth.uid()::text::uuid
    );

-- 5. Verify policies were created
SELECT 
    'RLS policies created' as status,
    COUNT(*) as policy_count
FROM pg_policies 
WHERE tablename = 'lessons';

-- 6. Test the policies work
SELECT 
    'Test query' as test,
    COUNT(*) as accessible_lessons
FROM lessons
WHERE teacher_id = auth.uid()::text::uuid;
