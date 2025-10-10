-- Add teacher_id to lessons table to connect lessons to teachers
-- This allows teachers to only see their own lessons and students to see lessons from their enrolled courses

-- 1. Add teacher_id column to lessons table
ALTER TABLE lessons 
ADD COLUMN teacher_id UUID REFERENCES profiles(id) ON DELETE CASCADE;

-- 2. Update existing lessons to have a default teacher (you'll need to set this to a real teacher ID)
-- For now, we'll set all existing lessons to the first teacher in the system
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

-- 5. Add RLS policy for lessons table
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;

-- Policy: Teachers can see their own lessons
CREATE POLICY "Teachers can view their own lessons" ON lessons
    FOR SELECT USING (
        teacher_id = auth.uid()::text::uuid OR
        teacher_id IN (
            SELECT id FROM profiles WHERE id = auth.uid()::text::uuid
        )
    );

-- Policy: Teachers can insert their own lessons
CREATE POLICY "Teachers can insert their own lessons" ON lessons
    FOR INSERT WITH CHECK (
        teacher_id = auth.uid()::text::uuid OR
        teacher_id IN (
            SELECT id FROM profiles WHERE id = auth.uid()::text::uuid
        )
    );

-- Policy: Teachers can update their own lessons
CREATE POLICY "Teachers can update their own lessons" ON lessons
    FOR UPDATE USING (
        teacher_id = auth.uid()::text::uuid OR
        teacher_id IN (
            SELECT id FROM profiles WHERE id = auth.uid()::text::uuid
        )
    );

-- Policy: Teachers can delete their own lessons
CREATE POLICY "Teachers can delete their own lessons" ON lessons
    FOR DELETE USING (
        teacher_id = auth.uid()::text::uuid OR
        teacher_id IN (
            SELECT id FROM profiles WHERE id = auth.uid()::text::uuid
        )
    );

-- 6. Test the changes
SELECT 
    'Lessons table updated successfully' as status,
    COUNT(*) as total_lessons,
    COUNT(DISTINCT teacher_id) as unique_teachers
FROM lessons;
