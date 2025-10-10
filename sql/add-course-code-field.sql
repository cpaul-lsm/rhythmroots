-- Add course_code field to courses table
-- This will be a unique identifier for each course (e.g., "MATH101", "ENG201")

-- 1. Add course_code column to courses table
ALTER TABLE courses 
ADD COLUMN IF NOT EXISTS course_code VARCHAR(20) UNIQUE;

-- 2. Add index for better query performance
CREATE INDEX IF NOT EXISTS idx_courses_course_code ON courses(course_code);

-- 3. Update existing courses with generated course codes
-- This will create codes like "COURSE-001", "COURSE-002", etc.
-- Using a CTE approach to handle the numbering
WITH numbered_courses AS (
    SELECT 
        id,
        'COURSE-' || LPAD(ROW_NUMBER() OVER (ORDER BY created_at)::TEXT, 3, '0') as new_code
    FROM courses 
    WHERE course_code IS NULL
)
UPDATE courses 
SET course_code = nc.new_code
FROM numbered_courses nc
WHERE courses.id = nc.id;

-- 4. Make course_code NOT NULL after setting default values
ALTER TABLE courses 
ALTER COLUMN course_code SET NOT NULL;

-- 5. Test the changes
SELECT 
    'Course code field added successfully' as status,
    COUNT(*) as total_courses,
    COUNT(DISTINCT course_code) as unique_codes
FROM courses;
