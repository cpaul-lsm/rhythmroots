import type { LayoutServerLoad } from './$types';
import { AuthService } from '$lib/auth';
import { redirect } from '@sveltejs/kit';

export const load: LayoutServerLoad = async ({ url, parent }) => {
	const { user, profile } = await parent();
	
	if (!user || !profile) {
		throw redirect(302, '/auth/login');
	}

	if (AuthService.isSuspended(profile)) {
		throw redirect(302, '/auth/suspended');
	}

	// Check if user is trying to access a dashboard they don't have access to
	const pathSegments = url.pathname.split('/');
	const dashboardType = pathSegments[2]; // /dashboard/student -> student
	
	if (dashboardType && dashboardType !== profile.role) {
		// Redirect to their appropriate dashboard
		const redirectPath = AuthService.getRedirectPath(profile);
		throw redirect(302, redirectPath);
	}

	return {
		user,
		profile,
		subscriptionStatus: AuthService.getSubscriptionStatus(profile)
	};
};
