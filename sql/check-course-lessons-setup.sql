-- Check if course_lessons table and policies are already set up correctly
-- This script will only create what's missing

-- 1. Check if course_lessons table exists and create if needed
CREATE TABLE IF NOT EXISTS course_lessons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    lesson_id UUID NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
    status lesson_status DEFAULT 'inactive',
    scheduled_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Ensure unique combination of course and lesson
    UNIQUE(course_id, lesson_id)
);

-- 2. Add indexes if they don't exist
CREATE INDEX IF NOT EXISTS idx_course_lessons_course_id ON course_lessons(course_id);
CREATE INDEX IF NOT EXISTS idx_course_lessons_lesson_id ON course_lessons(lesson_id);
CREATE INDEX IF NOT EXISTS idx_course_lessons_status ON course_lessons(status);

-- 3. Enable RLS if not already enabled
ALTER TABLE course_lessons ENABLE ROW LEVEL SECURITY;

-- 4. Check what policies exist and show status
SELECT 
    'Course_lessons table status' as info,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'course_lessons') 
        THEN 'Table exists' 
        ELSE 'Table missing' 
    END as table_status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'course_lessons') 
        THEN 'Policies exist' 
        ELSE 'No policies' 
    END as policy_status;

-- 5. Show current policies
SELECT 
    'Current policies' as info,
    policyname,
    cmd as operation
FROM pg_policies 
WHERE tablename = 'course_lessons'
ORDER BY policyname;

-- 6. Test table access
SELECT 
    'Table test' as info,
    COUNT(*) as total_records
FROM course_lessons;
