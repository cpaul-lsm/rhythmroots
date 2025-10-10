import type { PageServerLoad } from './$types';
import { AuthService } from '$lib/auth';

export const load: PageServerLoad = async ({ parent }) => {
	const { profile } = await parent();
	
	if (!profile || profile.role !== 'teacher') {
		throw new Error('Access denied');
	}

	return {
		profile
	};
};
