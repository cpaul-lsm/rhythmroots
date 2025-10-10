import { redirect } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ cookies }) => {
	// Clear any auth-related cookies
	cookies.delete('sb-access-token', { path: '/' });
	cookies.delete('sb-refresh-token', { path: '/' });
	cookies.delete('supabase-auth-token', { path: '/' });
	
	// Redirect to login page
	throw redirect(302, '/auth/login?signedOut=true');
};
