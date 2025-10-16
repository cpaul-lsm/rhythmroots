-- Ensure course_field_sets table exists with proper structure
-- This script can be run in Supabase SQL Editor

-- Create the table if it doesn't exist
CREATE TABLE IF NOT EXISTS course_field_sets (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_id uuid NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    field_set_id uuid NOT NULL REFERENCES student_field_sets(id) ON DELETE CASCADE,
    order_index int DEFAULT 0,
    active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    UNIQUE(course_id, field_set_id)
);

-- Create index if it doesn't exist
CREATE INDEX IF NOT EXISTS idx_cfs_course ON course_field_sets(course_id);
CREATE INDEX IF NOT EXISTS idx_cfs_field_set ON course_field_sets(field_set_id);

-- Enable RLS
ALTER TABLE course_field_sets ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Teacher manage course set mappings" ON course_field_sets;

-- Create RLS policy for teachers to manage their own course-field set mappings
CREATE POLICY "Teacher manage course set mappings" ON course_field_sets
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM courses c
            WHERE c.id = course_field_sets.course_id AND c.teacher_id = auth.uid()
        )
    ) WITH CHECK (
        EXISTS (
            SELECT 1 FROM courses c
            WHERE c.id = course_field_sets.course_id AND c.teacher_id = auth.uid()
        )
    );

-- Grant necessary permissions
GRANT ALL ON course_field_sets TO authenticated;
GRANT ALL ON course_field_sets TO service_role;
