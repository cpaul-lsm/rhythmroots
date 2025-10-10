import type { PageServerLoad, Actions } from './$types';
import { redirect } from '@sveltejs/kit';
import { AuthService } from '$lib/auth';

export const load: PageServerLoad = async ({ url, locals }) => {
	// Check if user is already logged in
	const { user, profile } = await AuthService.getCurrentUser();
	
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
	default: async ({ request, cookies }) => {
		const formData = await request.formData();
		const email = formData.get('email') as string;
		const password = formData.get('password') as string;

		if (!email || !password) {
			return {
				error: 'Please fill in all fields'
			};
		}

		try {
			const { data, error: authError } = await AuthService.signIn(email, password);
			
			if (authError) {
				return {
					error: authError.message
				};
			}

			if (data.user) {
				// Get profile to determine redirect
				const { profile } = await AuthService.getCurrentUser();
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
