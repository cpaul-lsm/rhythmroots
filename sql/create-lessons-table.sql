-- Create the lessons table
-- Run this in your Supabase SQL Editor

CREATE TABLE IF NOT EXISTS lessons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    image_url TEXT,
    content_blocks JSONB DEFAULT '[]',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Disable RLS on lessons table (for now)
ALTER TABLE lessons DISABLE ROW LEVEL SECURITY;

-- Test the table
INSERT INTO lessons (title, description, content_blocks)
VALUES (
    'Test Lesson',
    'This is a test lesson',
    '[]'
);

-- Verify it worked
SELECT 
    'Lessons table created successfully' as status,
    COUNT(*) as lesson_count
FROM lessons;

-- Clean up test data
DELETE FROM lessons WHERE title = 'Test Lesson';

SELECT 'Lessons table setup completed' as status;
