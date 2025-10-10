-- Create course_lessons junction table to connect courses with lessons
-- This allows lessons to be assigned to multiple courses and students to see lessons from their enrolled courses

-- 1. Create course_lessons junction table
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

-- 2. Add indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_course_lessons_course_id ON course_lessons(course_id);
CREATE INDEX IF NOT EXISTS idx_course_lessons_lesson_id ON course_lessons(lesson_id);
CREATE INDEX IF NOT EXISTS idx_course_lessons_status ON course_lessons(status);

-- 3. Add RLS policies for course_lessons
ALTER TABLE course_lessons ENABLE ROW LEVEL SECURITY;

-- Policy: Teachers can view course_lessons for their courses
CREATE POLICY "Teachers can view course_lessons for their courses" ON course_lessons
    FOR SELECT USING (
        course_id IN (
            SELECT id FROM courses WHERE teacher_id = auth.uid()::text::uuid
        )
    );

-- Policy: Students can view course_lessons for their enrolled courses
CREATE POLICY "Students can view course_lessons for enrolled courses" ON course_lessons
    FOR SELECT USING (
        course_id IN (
            SELECT course_id FROM student_courses 
            WHERE student_id = auth.uid()::text::uuid 
            AND payment_status = 'paid'
        )
    );

-- Policy: Teachers can insert course_lessons for their courses
CREATE POLICY "Teachers can insert course_lessons for their courses" ON course_lessons
    FOR INSERT WITH CHECK (
        course_id IN (
            SELECT id FROM courses WHERE teacher_id = auth.uid()::text::uuid
        )
    );

-- Policy: Teachers can update course_lessons for their courses
CREATE POLICY "Teachers can update course_lessons for their courses" ON course_lessons
    FOR UPDATE USING (
        course_id IN (
            SELECT id FROM courses WHERE teacher_id = auth.uid()::text::uuid
        )
    );

-- Policy: Teachers can delete course_lessons for their courses
CREATE POLICY "Teachers can delete course_lessons for their courses" ON course_lessons
    FOR DELETE USING (
        course_id IN (
            SELECT id FROM courses WHERE teacher_id = auth.uid()::text::uuid
        )
    );

-- 4. Test the table creation
SELECT 
    'Course_lessons table created successfully' as status,
    COUNT(*) as total_course_lessons
FROM course_lessons;
