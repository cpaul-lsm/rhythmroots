-- Complete script to add teacher-lesson connections and course-lesson relationships
-- This allows teachers to only see their own lessons and students to see lessons from their enrolled courses

-- 1. Add teacher_id to lessons table
ALTER TABLE lessons 
ADD COLUMN IF NOT EXISTS teacher_id UUID REFERENCES profiles(id) ON DELETE CASCADE;

-- 2. Update existing lessons to have a default teacher (set to first teacher in system)
UPDATE lessons 
SET teacher_id = (
    SELECT id FROM profiles 
    WHERE role = 'teacher' 
    ORDER BY created_at 
    LIMIT 1
)
WHERE teacher_id IS NULL;

-- 3. Make teacher_id NOT NULL after setting default values
ALTER TABLE lessons 
ALTER COLUMN teacher_id SET NOT NULL;

-- 4. Add index for better query performance
CREATE INDEX IF NOT EXISTS idx_lessons_teacher_id ON lessons(teacher_id);

-- 5. Create course_lessons junction table
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

-- 6. Add indexes for course_lessons
CREATE INDEX IF NOT EXISTS idx_course_lessons_course_id ON course_lessons(course_id);
CREATE INDEX IF NOT EXISTS idx_course_lessons_lesson_id ON course_lessons(lesson_id);
CREATE INDEX IF NOT EXISTS idx_course_lessons_status ON course_lessons(status);

-- 7. Update RLS policies for lessons table
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Teachers can view their own lessons" ON lessons;
DROP POLICY IF EXISTS "Teachers can insert their own lessons" ON lessons;
DROP POLICY IF EXISTS "Teachers can update their own lessons" ON lessons;
DROP POLICY IF EXISTS "Teachers can delete their own lessons" ON lessons;

-- Create new policies for lessons
CREATE POLICY "Teachers can view their own lessons" ON lessons
    FOR SELECT USING (
        teacher_id = auth.uid()::text::uuid
    );

CREATE POLICY "Teachers can insert their own lessons" ON lessons
    FOR INSERT WITH CHECK (
        teacher_id = auth.uid()::text::uuid
    );

CREATE POLICY "Teachers can update their own lessons" ON lessons
    FOR UPDATE USING (
        teacher_id = auth.uid()::text::uuid
    );

CREATE POLICY "Teachers can delete their own lessons" ON lessons
    FOR DELETE USING (
        teacher_id = auth.uid()::text::uuid
    );

-- 8. Add RLS policies for course_lessons
ALTER TABLE course_lessons ENABLE ROW LEVEL SECURITY;

-- Teachers can view course_lessons for their courses
CREATE POLICY "Teachers can view course_lessons for their courses" ON course_lessons
    FOR SELECT USING (
        course_id IN (
            SELECT id FROM courses WHERE teacher_id = auth.uid()::text::uuid
        )
    );

-- Students can view course_lessons for their enrolled courses
CREATE POLICY "Students can view course_lessons for enrolled courses" ON course_lessons
    FOR SELECT USING (
        course_id IN (
            SELECT course_id FROM student_courses 
            WHERE student_id = auth.uid()::text::uuid 
            AND payment_status = 'paid'
        )
    );

-- Teachers can manage course_lessons for their courses
CREATE POLICY "Teachers can insert course_lessons for their courses" ON course_lessons
    FOR INSERT WITH CHECK (
        course_id IN (
            SELECT id FROM courses WHERE teacher_id = auth.uid()::text::uuid
        )
    );

CREATE POLICY "Teachers can update course_lessons for their courses" ON course_lessons
    FOR UPDATE USING (
        course_id IN (
            SELECT id FROM courses WHERE teacher_id = auth.uid()::text::uuid
        )
    );

CREATE POLICY "Teachers can delete course_lessons for their courses" ON course_lessons
    FOR DELETE USING (
        course_id IN (
            SELECT id FROM courses WHERE teacher_id = auth.uid()::text::uuid
        )
    );

-- 9. Test the changes
SELECT 
    'Database updated successfully' as status,
    (SELECT COUNT(*) FROM lessons) as total_lessons,
    (SELECT COUNT(DISTINCT teacher_id) FROM lessons) as unique_teachers,
    (SELECT COUNT(*) FROM course_lessons) as total_course_lessons;
