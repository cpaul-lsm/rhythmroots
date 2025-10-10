import { AuthService } from '$lib/auth';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals }) => {
	const { user, profile } = await AuthService.getCurrentUser();

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
