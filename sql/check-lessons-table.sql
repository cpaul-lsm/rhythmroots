-- Check if lessons table exists and is accessible
-- Run this in your Supabase SQL Editor

-- 1. Check table structure
SELECT 
    'Table Structure' as test_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'lessons'
ORDER BY ordinal_position;

-- 2. Check if we can query the table
SELECT 
    'Query Test' as test_name,
    COUNT(*) as lesson_count
FROM lessons;

-- 3. Try to insert a test lesson
INSERT INTO lessons (title, description, content_blocks)
VALUES (
    'Test Lesson from SQL',
    'This is a test lesson created via SQL',
    '[]'
);

-- 4. Verify the insert worked
SELECT 
    'Insert Verification' as test_name,
    id,
    title,
    description,
    created_at
FROM lessons
WHERE title = 'Test Lesson from SQL';

-- 5. Clean up
DELETE FROM lessons WHERE title = 'Test Lesson from SQL';

SELECT 'Lessons table check completed' as status;
