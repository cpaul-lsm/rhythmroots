-- Quick test to check lessons table
-- Run this in your Supabase SQL Editor

-- Check if lessons table exists
SELECT table_name 
FROM information_schema.tables 
WHERE table_name = 'lessons';

-- If the above returns nothing, the table doesn't exist
-- If it returns 'lessons', then the table exists
