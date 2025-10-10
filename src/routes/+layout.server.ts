import type { LayoutServerLoad } from './$types';
import { AuthService } from '$lib/auth';
import { supabaseServer } from '$lib/supabase-server';
import { redirect } from '@sveltejs/kit';

export const load: LayoutServerLoad = async ({ url, locals }) => {
	// Get current user and profile
	const { user, profile, error } = await AuthService.getCurrentUser();
	
	// Only redirect if user is not authenticated and trying to access protected routes
	const protectedRoutes = ['/dashboard'];
	const isProtectedRoute = protectedRoutes.some(route => url.pathname.startsWith(route));
	
	// Skip auth check for logout route
	if (url.pathname === '/auth/logout') {
		return {
			user: null,
			profile: null,
			subscriptionStatus: null
		};
	}
	
	// If trying to access protected routes without authentication
	if (isProtectedRoute && !user) {
		throw redirect(302, '/auth/login');
	}

	// If user is authenticated but suspended
	if (user && profile && AuthService.isSuspended(profile)) {
		throw redirect(302, '/auth/suspended');
	}

	// If user is on login page but already authenticated, redirect to appropriate dashboard
	// Only do this if we're not coming from a sign out
	if (url.pathname === '/auth/login' && user && profile && !url.searchParams.has('signedOut')) {
		const redirectPath = AuthService.getRedirectPath(profile);
		throw redirect(302, redirectPath);
	}

	return {
		user,
		profile,
		subscriptionStatus: profile ? AuthService.getSubscriptionStatus(profile) : null
	};
};
