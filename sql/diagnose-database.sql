-- Diagnostic queries to check database structure
-- Run these in your Supabase SQL Editor to diagnose the issue

-- 1. Check if the profiles table exists and its structure
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'profiles' 
ORDER BY ordinal_position;

-- 2. Check if the user_role enum exists
SELECT 
    typname as enum_name,
    enumlabel as enum_value
FROM pg_type t 
JOIN pg_enum e ON t.oid = e.enumtypid 
WHERE typname = 'user_role'
ORDER BY e.enumsortorder;

-- 3. Check if the generate_account_slug function exists
SELECT 
    routine_name, 
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_name = 'generate_account_slug';

-- 4. Check current trigger status
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'users' 
AND trigger_schema = 'auth';

-- 5. Test if we can insert a test profile (this will fail if there are issues)
-- Uncomment the next lines to test:
/*
INSERT INTO profiles (id, first_name, last_name, email, role, account_slug)
VALUES (
    '00000000-0000-0000-0000-000000000000',
    'Test',
    'User',
    'test@example.com',
    'student',
    '123456'
);
*/
