# Supabase Setup Instructions

## Environment Variables

Create a `.env` file in the root directory with your Supabase credentials:

```env
# Supabase Configuration
PUBLIC_SUPABASE_URL=your_supabase_project_url_here
PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key_here

# Optional: Encryption key for sensitive data
ENCRYPTION_KEY=your_encryption_key_here
```

## Getting Your Supabase Credentials

1. Go to [supabase.com](https://supabase.com) and sign in to your account
2. Create a new project or select an existing one
3. Go to **Settings** → **API**
4. Copy the following values:
   - **Project URL** → Use as `PUBLIC_SUPABASE_URL`
   - **anon public** key → Use as `PUBLIC_SUPABASE_ANON_KEY`

## Project Structure

The Supabase integration is organized as follows:

```
src/lib/
├── supabase.ts          # Main client-side Supabase client
├── supabase-server.ts   # Server-side Supabase client
├── db-utils.ts          # Database utility functions
├── index.ts             # Export all utilities
└── components/
    └── SupabaseTest.svelte  # Test component to verify connection
```

## Usage Examples

### Client-side usage:
```typescript
import { supabase, DatabaseUtils, AuthUtils } from '$lib';

// Get all records from a table
const { data, error } = await DatabaseUtils.getAll('users');

// Get current user
const { user, error } = await AuthUtils.getCurrentUser();

// Insert a new record
const { data, error } = await DatabaseUtils.insert('users', {
  email: 'user@example.com',
  name: 'John Doe'
});
```

### Server-side usage (in +page.server.ts or +layout.server.ts):
```typescript
import { supabaseServer } from '$lib/supabase-server';

// Server-side database operations
const { data, error } = await supabaseServer.from('users').select('*');
```

## Next Steps

1. Set up your environment variables in `.env`
2. Run `npm run dev` to start the development server
3. Visit the homepage to test the Supabase connection
4. Start creating your database tables in the Supabase dashboard
5. Update the `Database` interface in `src/lib/supabase.ts` with your table schemas

## Database Schema Types

As you create tables in Supabase, update the `Database` interface in `src/lib/supabase.ts` to include your table definitions. This will provide full TypeScript support for your database operations.

Example:
```typescript
export interface Database {
  public: {
    Tables: {
      users: {
        Row: {
          id: string;
          email: string;
          name: string;
          created_at: string;
        };
        Insert: {
          id?: string;
          email: string;
          name: string;
          created_at?: string;
        };
        Update: {
          id?: string;
          email?: string;
          name?: string;
          created_at?: string;
        };
      };
    };
    // ... other types
  };
}
```
