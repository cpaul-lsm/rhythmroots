-- Test the lessons table
-- Run this in your Supabase SQL Editor

-- 1. Check if lessons table exists
SELECT 
    'Table Exists Check' as test_name,
    table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'lessons'
ORDER BY ordinal_position;

-- 2. Test inserting a lesson
INSERT INTO lessons (title, description, content_blocks)
VALUES (
    'Test Lesson',
    'This is a test lesson',
    '[]'
);

-- 3. Check if the insert worked
SELECT 
    'Insert Test' as test_name,
    COUNT(*) as lesson_count
FROM lessons;

-- 4. Show the inserted lesson
SELECT 
    'Inserted Lesson' as test_name,
    id,
    title,
    description,
    created_at
FROM lessons
ORDER BY created_at DESC
LIMIT 1;

-- 5. Clean up test data
DELETE FROM lessons WHERE title = 'Test Lesson';

SELECT 'Lessons table test completed' as status;
