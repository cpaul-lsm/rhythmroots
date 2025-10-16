import type { PageServerLoad, Actions } from './$types';
import { redirect } from '@sveltejs/kit';
import { AuthService } from '$lib/auth';
import { createServerSupabaseClient } from '$lib/supabase-server-helpers';

export const load: PageServerLoad = async ({ url, locals, cookies }) => {
	// Create server-side Supabase client
	const supabase = createServerSupabaseClient({ url, locals, cookies } as any);
	
	// Check if user is already logged in
	const { user, profile } = await AuthService.getCurrentUserServer(supabase);
	
	if (user && profile) {
		// Redirect to appropriate dashboard
		const redirectPath = AuthService.getRedirectPath(profile);
		throw redirect(302, redirectPath);
	}

	return {
		// No sensitive data in the page load
	};
};

export const actions: Actions = {
	default: async ({ request, cookies, url, locals }) => {
		const formData = await request.formData();
		const email = formData.get('email') as string;
		const password = formData.get('password') as string;

		if (!email || !password) {
			return {
				error: 'Please fill in all fields'
			};
		}

		// Create server-side Supabase client
		const supabase = createServerSupabaseClient({ url, locals, cookies } as any);

		try {
			const { data, error: authError } = await AuthService.signInServer(supabase, email, password);
			
			if (authError) {
				return {
					error: authError.message
				};
			}

			if (data.user) {
				// Get profile to determine redirect
				const { profile } = await AuthService.getCurrentUserServer(supabase);
				if (profile) {
					const redirectPath = AuthService.getRedirectPath(profile);
					throw redirect(302, redirectPath);
				} else {
					return {
						error: 'Profile not found. Please try again.'
					};
				}
			}
		} catch (err) {
			console.error('Login error:', err);
			return {
				error: 'An unexpected error occurred'
			};
		}

		return {
			error: 'Login failed'
		};
	}
};
