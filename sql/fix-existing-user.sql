-- Fix the existing user who doesn't have a profile
-- Replace the user_id below with the actual user ID from the error message
-- The user ID from your error is: 0e7c1b29-0c6c-4e06-a25e-efe254cb5e3f

-- First, let's check if the user exists in auth.users
SELECT id, email, raw_user_meta_data 
FROM auth.users 
WHERE id = '0e7c1b29-0c6c-4e06-a25e-efe254cb5e3f';

-- Create the missing profile for this user
INSERT INTO profiles (id, first_name, last_name, email, role, account_slug)
VALUES (
    '0e7c1b29-0c6c-4e06-a25e-efe254cb5e3f',
    COALESCE((SELECT raw_user_meta_data->>'first_name' FROM auth.users WHERE id = '0e7c1b29-0c6c-4e06-a25e-efe254cb5e3f'), 'User'),
    COALESCE((SELECT raw_user_meta_data->>'last_name' FROM auth.users WHERE id = '0e7c1b29-0c6c-4e06-a25e-efe254cb5e3f'), 'Name'),
    (SELECT email FROM auth.users WHERE id = '0e7c1b29-0c6c-4e06-a25e-efe254cb5e3f'),
    COALESCE((SELECT raw_user_meta_data->>'role' FROM auth.users WHERE id = '0e7c1b29-0c6c-4e06-a25e-efe254cb5e3f'), 'student')::user_role,
    generate_account_slug()
);

-- Verify the profile was created
SELECT * FROM profiles WHERE id = '0e7c1b29-0c6c-4e06-a25e-efe254cb5e3f';
