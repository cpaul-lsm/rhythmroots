import type { Actions, PageServerLoad } from './$types';
import { getSupabaseAdmin } from '$lib/supabase-admin';
import { createServerSupabaseClient } from '$lib/supabase-server-helpers';
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

export const actions: Actions = {
	add_student: async ({ request, url, locals, cookies }) => {
		// Build server-side client to get the current teacher profile
		const supabase = createServerSupabaseClient({ url, locals, cookies } as any);
		const { profile } = await AuthService.getCurrentUserServer(supabase);
		const formData = await request.formData();
		const email = String(formData.get('email') || '').trim().toLowerCase();
		const firstName = String(formData.get('first_name') || '').trim();
		const lastName = String(formData.get('last_name') || '').trim();
		const courseId = String(formData.get('course_id') || '').trim();
		const phone = String(formData.get('phone') || '').trim() || null;
		const address = {
			line1: String(formData.get('address_line1') || '').trim() || null,
			line2: String(formData.get('address_line2') || '').trim() || null,
			city: String(formData.get('city') || '').trim() || null,
			state: String(formData.get('state') || '').trim() || null,
			postal_code: String(formData.get('postal_code') || '').trim() || null,
			country: String(formData.get('country') || '').trim() || null
		};
		let customFields: any = null;
		const customFieldsRaw = String(formData.get('custom_fields') || '').trim();
		if (customFieldsRaw) {
			try {
				customFields = JSON.parse(customFieldsRaw);
			} catch (e) {
				return { success: false, error: 'Custom fields must be valid JSON' };
			}
		}

		if (!email || !firstName || !lastName) {
			return { success: false, error: 'Missing required fields' };
		}

		// Verify current user is teacher; course validation only if provided
		const teacherId = profile?.id as string | undefined;
		if (!teacherId) {
			return { success: false, error: 'Not authenticated' };
		}

        const supabaseAdmin = getSupabaseAdmin();

        if (courseId) {
            const { data: courseCheck, error: courseErr } = await supabaseAdmin
				.from('courses')
				.select('id, teacher_id')
				.eq('id', courseId)
				.single();

			if (courseErr || !courseCheck || (courseCheck as any).teacher_id !== teacherId) {
				return { success: false, error: 'You do not have access to this course' };
			}
		}

		// Step 1: Find or create auth user by email
		// Try to find existing user by email in auth
		let userId: string | null = null;
		// Try to find existing profile by email to get user id
        const { data: existingProfile } = await (supabaseAdmin as any)
			.from('profiles')
			.select('id')
			.eq('email', email)
			.maybeSingle();

		if (existingProfile?.id) {
			userId = existingProfile.id as string;
		} else {
			// Create a user without sending invite email; they can set password later
            const { data: created, error: createErr } = await supabaseAdmin.auth.admin.createUser({
				email,
				email_confirm: true,
				user_metadata: { first_name: firstName, last_name: lastName, role: 'student' }
			});
			if (createErr || !created?.user) {
				return { success: false, error: createErr?.message || 'Failed to create user' };
			}
			userId = created.user.id;
		}

		// Ensure profile exists and is student role; update names if missing
        const { data: profRow, error: profErr } = await (supabaseAdmin as any)
			.from('profiles')
			.select('id, role, first_name, last_name, email')
			.eq('id', userId)
			.single();

		if (profErr) {
			// Create profile row (service role not needed due to trigger usually, but fallback)
			const { error: insertProfErr } = await (supabaseAdmin as any)
				.from('profiles')
				.insert({ id: userId!, role: 'student', first_name: firstName, last_name: lastName, email, phone, address, custom_fields: customFields ?? {} });
			if (insertProfErr) {
				return { success: false, error: insertProfErr.message };
			}
		} else {
			if ((profRow as any).role !== 'student') {
				return { success: false, error: 'User exists but is not a student' };
			}
			// Update names if blank
			const updateData: any = {};
			if (!(profRow as any).first_name) updateData.first_name = firstName;
			if (!(profRow as any).last_name) updateData.last_name = lastName;
			if (phone) updateData.phone = phone;
			if (Object.values(address).some(v => v)) updateData.address = address;
			if (customFields) updateData.custom_fields = customFields;
			if (Object.keys(updateData).length > 0) {
				await (supabaseAdmin as any).from('profiles').update(updateData).eq('id', userId);
			}
		}

		// Step 3: Upsert dynamic custom field values for selected course
		if (courseId) {
			// Load active fields attached to this course
			const { data: fields } = await (supabaseAdmin as any)
				.from('course_field_sets')
				.select('field_set_id, student_field_sets!inner(teacher_id), student_fields:student_field_sets(id, student_fields(*))')
				.eq('course_id', courseId)
				.eq('active', true);

			if (fields && Array.isArray(fields)) {
				for (const set of fields as any[]) {
					const setFields: any[] = set.student_fields?.student_fields || [];
					for (const field of setFields) {
						const formKey = `field_${field.id}`;
						const raw = formData.get(formKey);
						
						// Skip validation for section titles as they don't store user input
						if (field.type === 'section_title') {
							continue;
						}
						
						if (raw == null || String(raw).trim() === '') {
							if (field.required) {
								return { success: false, error: `Missing required field: ${field.label}` };
							}
							continue;
						}
						let value: any;
						switch (field.type) {
							case 'number': value = Number(raw); if (Number.isNaN(value)) return { success: false, error: `${field.label} must be a number` }; break;
							case 'boolean': value = String(raw) === 'true'; break;
							case 'date': value = String(raw); break;
							case 'multiselect':
								try { value = JSON.parse(String(raw)); if (!Array.isArray(value)) throw new Error('not array'); } catch { return { success: false, error: `${field.label} must be an array` }; }
								break;
							case 'section_title': value = ''; break; // Section titles don't store values
							case 'select':
							case 'text':
							case 'textarea':
							default: value = String(raw); break;
						}

						// Validate select options
						if ((field.type === 'select' || field.type === 'multiselect') && field.options) {
							const opts = Array.isArray(field.options) ? field.options : field.options?.options;
							if (field.type === 'select' && !opts?.includes(value)) {
								return { success: false, error: `${field.label} must be one of the provided options` };
							}
							if (field.type === 'multiselect' && Array.isArray(value) && !value.every((v: any) => opts?.includes(v))) {
								return { success: false, error: `${field.label} has invalid selection(s)` };
							}
						}

						await (supabaseAdmin as any)
							.from('student_field_values')
							.upsert({ student_id: userId!, course_id: courseId, field_id: field.id, value }, { onConflict: 'student_id,course_id,field_id' });
					}
				}
			}
		}

		// Enroll student in the course if provided (idempotent)
        if (courseId) {
            const { data: existingEnrollment } = await (supabaseAdmin as any)
				.from('student_courses')
				.select('id')
				.eq('student_id', userId)
				.eq('course_id', courseId)
				.maybeSingle();

			if (!existingEnrollment) {
                const { error: enrollErr } = await (supabaseAdmin as any)
					.from('student_courses')
					.insert({ student_id: userId!, course_id: courseId, payment_status: 'pending' });
				if (enrollErr) {
					return { success: false, error: enrollErr.message };
				}
			}
		}

		return { success: true };
	}
};
