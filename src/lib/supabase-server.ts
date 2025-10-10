import { createClient } from '@supabase/supabase-js';
import { PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY } from '$env/static/public';
import type { Database } from './supabase';

if (!PUBLIC_SUPABASE_URL) {
	throw new Error('Missing PUBLIC_SUPABASE_URL environment variable');
}

if (!PUBLIC_SUPABASE_ANON_KEY) {
	throw new Error('Missing PUBLIC_SUPABASE_ANON_KEY environment variable');
}

// Server-side Supabase client
export const supabaseServer = createClient<Database>(PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY, {
	auth: {
		autoRefreshToken: false,
		persistSession: false
	}
});
