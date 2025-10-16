import { AuthService } from '$lib/auth';
import { createServerSupabaseClient } from '$lib/supabase-server-helpers';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals, cookies, url }) => {
	// Create server-side Supabase client
	const supabase = createServerSupabaseClient({ url, locals, cookies } as any);
	
	const { user, profile } = await AuthService.getCurrentUserServer(supabase);

	if (!user || !profile) {
		throw new Error('User not authenticated');
	}

	// Ensure user is a teacher
	if (profile.role !== 'teacher') {
		throw new Error('Access denied');
	}

	return {
		user,
		profile
	};
};
