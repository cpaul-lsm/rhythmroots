-- Test the fix by creating a profile for the existing user
-- Run this after running the emergency-fix.sql

-- First, let's see what user data we have
SELECT 
    id, 
    email, 
    raw_user_meta_data->>'first_name' as first_name,
    raw_user_meta_data->>'last_name' as last_name,
    raw_user_meta_data->>'role' as role
FROM auth.users 
WHERE id = '0e7c1b29-0c6c-4e06-a25e-efe254cb5e3f';

-- Now create the profile with proper enum casting
INSERT INTO profiles (id, first_name, last_name, email, role, account_slug)
VALUES (
    '0e7c1b29-0c6c-4e06-a25e-efe254cb5e3f',
    COALESCE((SELECT raw_user_meta_data->>'first_name' FROM auth.users WHERE id = '0e7c1b29-0c6c-4e06-a25e-efe254cb5e3f'), 'User'),
    COALESCE((SELECT raw_user_meta_data->>'last_name' FROM auth.users WHERE id = '0e7c1b29-0c6c-4e06-a25e-efe254cb5e3f'), 'Name'),
    (SELECT email FROM auth.users WHERE id = '0e7c1b29-0c6c-4e06-a25e-efe254cb5e3f'),
    COALESCE((SELECT raw_user_meta_data->>'role' FROM auth.users WHERE id = '0e7c1b29-0c6c-4e06-a25e-efe254cb5e3f'), 'student')::user_role,
    generate_account_slug()
);

-- Verify the profile was created successfully
SELECT * FROM profiles WHERE id = '0e7c1b29-0c6c-4e06-a25e-efe254cb5e3f';

-- Test that we can query profiles without errors
SELECT COUNT(*) as total_profiles FROM profiles;
