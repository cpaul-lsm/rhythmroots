import { createServerClient } from '@supabase/ssr';
import { PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY } from '$env/static/public';
import type { Database } from './supabase';
import type { RequestEvent } from '@sveltejs/kit';

/**
 * Create a Supabase client for server-side operations
 * This properly handles cookies and session management for SvelteKit
 */
export function createServerSupabaseClient(event: RequestEvent) {
	const supabaseUrl = PUBLIC_SUPABASE_URL;
	const supabaseAnonKey = PUBLIC_SUPABASE_ANON_KEY;

	return createServerClient<Database>(supabaseUrl, supabaseAnonKey, {
		cookies: {
			getAll() {
				return event.cookies.getAll();
			},
			setAll(cookiesToSet) {
				cookiesToSet.forEach(({ name, value, options }) => {
					event.cookies.set(name, value, options);
				});
			},
		},
	});
}

/**
 * Server-side authentication utilities
 */
export class ServerAuthService {
	/**
	 * Get current user with profile data using server-side client
	 */
	static async getCurrentUser(supabase: ReturnType<typeof createServerSupabaseClient>): Promise<{ 
		user: any; 
		profile: any | null; 
		error: any 
	}> {
		try {
			const { data: { user }, error: userError } = await supabase.auth.getUser();
			
			if (userError || !user) {
				return { user: null, profile: null, error: userError };
			}

			const { data: profile, error: profileError } = await supabase
				.from('profiles')
				.select('*')
				.eq('id', user.id)
				.single();

			return { user, profile, error: profileError };
		} catch (error) {
			return { user: null, profile: null, error };
		}
	}

	/**
	 * Sign in with email and password using server-side client
	 */
	static async signIn(
		supabase: ReturnType<typeof createServerSupabaseClient>,
		email: string, 
		password: string
	) {
		const { data, error } = await supabase.auth.signInWithPassword({
			email,
			password
		});

		return { data, error };
	}

	/**
	 * Sign out current user using server-side client
	 */
	static async signOut(supabase: ReturnType<typeof createServerSupabaseClient>) {
		const { error } = await supabase.auth.signOut({ scope: 'global' });
		return { error };
	}

	/**
	 * Check if user is suspended
	 */
	static isSuspended(profile: any | null): boolean {
		return profile?.is_suspended || false;
	}

	/**
	 * Get redirect path based on user role
	 */
	static getRedirectPath(profile: any | null): string {
		if (!profile) return '/auth/login';
		
		switch (profile.role) {
			case 'student':
				return '/dashboard/student';
			case 'teacher':
				return '/dashboard/teacher';
			case 'super_admin':
				return '/dashboard/admin';
			default:
				return '/dashboard/student';
		}
	}

	/**
	 * Get user's subscription status
	 */
	static getSubscriptionStatus(profile: any | null): {
		plan: string;
		active: boolean;
		expired: boolean;
	} {
		if (!profile) {
			return { plan: 'none', active: false, expired: true };
		}

		const now = new Date();
		const endDate = profile.subscription_end_date ? new Date(profile.subscription_end_date) : null;
		const expired = endDate ? now > endDate : false;

		return {
			plan: profile.subscription_plan,
			active: profile.subscription_active && !expired,
			expired
		};
	}
}
