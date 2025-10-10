# Database Error Troubleshooting Guide

## Issue: Database error saving new user when teacher is selected

### Error Details
```
lzwkqwhlzycyabdkznio.supabase.co/auth/v1/signup:1 Failed to load resource: the server responded with a status of 500 ()
Registration error: AuthApiError: Database error saving new user
```

### Root Cause
The database trigger function `handle_new_user()` is failing when trying to create a profile for new users. This could be due to:
1. Missing or incorrect `user_role` enum
2. Issues with the `generate_account_slug()` function
3. Problems with the trigger function itself
4. Missing profiles table or incorrect structure

### Solution

#### Step 1: Diagnose the Issue
First, run the diagnostic queries in `diagnose-database.sql` to check your database structure.

#### Step 2: Try the Robust Fix
Run the SQL in `fix-database-error.sql` - this includes error handling and enum validation.

#### Step 3: If That Fails, Use the Simple Fix
If the robust fix doesn't work, try `simple-fix.sql` which avoids enum casting issues.

#### Step 4: Manual Profile Creation (Last Resort)
If triggers continue to fail, you can temporarily disable the trigger and create profiles manually:

```sql
-- Disable the trigger temporarily
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create profiles manually after user registration
-- (This would require modifying the frontend code)
```

#### Step 2: Verify Environment Variables
Make sure your `.env` file contains the correct Supabase credentials:

```env
PUBLIC_SUPABASE_URL=your_supabase_project_url_here
PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key_here
```

#### Step 3: Test Registration
1. Go to `/auth/register`
2. Select "Teacher" as the account type
3. Fill in the registration form
4. Submit and check for any error messages

### Additional Debugging

#### Check Browser Console
Open browser developer tools and look for any error messages in the console when registering.

#### Check Supabase Logs
1. Go to your Supabase dashboard
2. Navigate to Logs > Auth
3. Look for any error messages during user registration

#### Verify Database Schema
Make sure all tables and functions are created correctly by running the full `database-schema.sql` file.

### Common Issues

1. **Missing Environment Variables**: Ensure `.env` file is in the project root
2. **Incorrect Supabase URL/Key**: Double-check your Supabase project settings
3. **Database Permissions**: Ensure RLS policies allow profile creation
4. **Trigger Function Errors**: The trigger might fail if the `user_role` enum doesn't exist

### Testing the Fix

After applying the trigger fix, test with both roles:
- Register as a student → should create profile with `role: 'student'`
- Register as a teacher → should create profile with `role: 'teacher'`

### If Issues Persist

1. Check the browser network tab for failed requests
2. Verify the Supabase project is active and not paused
3. Ensure the database schema was applied completely
4. Check that the `profiles` table has the correct structure
