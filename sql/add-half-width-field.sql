-- Add half_width column to student_fields table
-- This allows fields to be displayed in a two-column layout

-- Add the half_width column
ALTER TABLE student_fields 
ADD COLUMN IF NOT EXISTS half_width BOOLEAN DEFAULT false;

-- Add a comment to document the purpose
COMMENT ON COLUMN student_fields.half_width IS 'When true, field takes up half width and aligns with the field above if it is also half width';
