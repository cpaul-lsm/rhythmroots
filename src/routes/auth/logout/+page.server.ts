import { redirect } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import { createServerSupabaseClient } from '$lib/supabase-server-helpers';

export const load: PageServerLoad = async ({ cookies, url, locals }) => {
	// Create server-side Supabase client
	const supabase = createServerSupabaseClient({ url, locals, cookies } as any);
	
	// Sign out using server-side client
	await supabase.auth.signOut({ scope: 'global' });
	
	// Redirect to login page
	throw redirect(302, '/auth/login?signedOut=true');
};
