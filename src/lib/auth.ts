import { supabase } from './supabase';
import type { Tables } from './supabase';

export type UserRole = 'student' | 'teacher' | 'super_admin';
export type UserProfile = Tables<'profiles'>;

export class AuthService {
	/**
	 * Get current user with profile data
	 */
	static async getCurrentUser(): Promise<{ user: any; profile: UserProfile | null; error: any }> {
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
	 * Sign up a new user
	 */
	static async signUp(
		email: string, 
		password: string, 
		firstName: string, 
		lastName: string, 
		role: UserRole = 'student'
	) {
		const { data, error } = await supabase.auth.signUp({
			email,
			password,
			options: {
				data: {
					first_name: firstName,
					last_name: lastName,
					role: role
				}
			}
		});

		return { data, error };
	}

	/**
	 * Sign in with email and password
	 */
	static async signIn(email: string, password: string) {
		const { data, error } = await supabase.auth.signInWithPassword({
			email,
			password
		});

		return { data, error };
	}

	/**
	 * Sign out current user
	 */
	static async signOut() {
		// Sign out from all sessions
		const { error } = await supabase.auth.signOut({ scope: 'global' });
		return { error };
	}

	/**
	 * Check if user has specific role
	 */
	static hasRole(profile: UserProfile | null, role: UserRole): boolean {
		return profile?.role === role;
	}

	/**
	 * Check if user has any of the specified roles
	 */
	static hasAnyRole(profile: UserProfile | null, roles: UserRole[]): boolean {
		return profile ? roles.includes(profile.role) : false;
	}

	/**
	 * Check if user is suspended
	 */
	static isSuspended(profile: UserProfile | null): boolean {
		return profile?.is_suspended || false;
	}

	/**
	 * Get redirect path based on user role
	 */
	static getRedirectPath(profile: UserProfile | null): string {
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
	 * Listen to auth state changes
	 */
	static onAuthStateChange(callback: (event: string, session: any) => void) {
		return supabase.auth.onAuthStateChange(callback);
	}

	/**
	 * Update user profile
	 */
	static async updateProfile(updates: any) {
		const { data: { user } } = await supabase.auth.getUser();
		
		if (!user) {
			return { data: null, error: new Error('No user found') };
		}

		const { data, error } = await supabase
			.from('profiles')
			.update(updates as any)
			.eq('id', user.id)
			.select()
			.single();

		return { data, error };
	}

	/**
	 * Get user's subscription status
	 */
	static getSubscriptionStatus(profile: UserProfile | null): {
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
