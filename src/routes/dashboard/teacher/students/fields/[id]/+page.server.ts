import type { Actions, PageServerLoad } from './$types';
import { getSupabaseAdmin } from '$lib/supabase-admin';
import { createServerSupabaseClient } from '$lib/supabase-server-helpers';
import { AuthService } from '$lib/auth';

export const load: PageServerLoad = async ({ params, parent }) => {
    const { profile } = await parent();

    if (!profile || profile.role !== 'teacher') {
        throw new Error('Access denied');
    }

    const admin = getSupabaseAdmin();
    
    // Get the field set details
    const { data: fieldSet, error: setError } = await (admin as any)
        .from('student_field_sets')
        .select('*')
        .eq('id', params.id)
        .eq('teacher_id', profile.id)
        .single();

    if (setError || !fieldSet) {
        throw new Error('Field set not found');
    }

    // Get fields for this set
    const { data: fields, error: fieldsError } = await (admin as any)
        .from('student_fields')
        .select('*')
        .eq('field_set_id', params.id)
        .order('created_at', { ascending: true });

    if (fieldsError) {
        throw new Error('Failed to load fields');
    }

    return { 
        profile, 
        fieldSet, 
        fields: fields || [] 
    };
};

export const actions: Actions = {
    list_fields: async ({ url, locals, cookies, params }) => {
        try {
            const supabase = createServerSupabaseClient({ url, locals, cookies } as any);
            const { profile } = await AuthService.getCurrentUserServer(supabase);
            if (!profile || profile.role !== 'teacher') {
                return { success: false, error: 'Access denied' };
            }
            
            const admin = getSupabaseAdmin();
            const { data: rows, error } = await (admin as any)
                .from('student_fields')
                .select('*')
                .eq('field_set_id', params.id)
                .order('created_at', { ascending: true });
            if (error) return { success: false, error: error.message };
            return { success: true, fields: rows || [] };
        } catch (e: any) {
            return { success: false, error: e?.message || 'Unknown error' };
        }
    },
    create_field: async ({ request, url, locals, cookies, params }) => {
        try {
            const supabase = createServerSupabaseClient({ url, locals, cookies } as any);
            const { profile } = await AuthService.getCurrentUserServer(supabase);
            if (!profile || profile.role !== 'teacher') {
                return { success: false, error: 'Access denied' };
            }

            const form = await request.formData();
            const name = String(form.get('name') || '').trim();
            const type = String(form.get('type') || '').trim();
            const required = form.get('required') === 'on';
            const options = String(form.get('options') || '').trim();

            if (!name || !type) {
                return { success: false, error: 'Name and type are required' };
            }

            // Convert name to key (lowercase, replace spaces with underscores)
            const key = name.toLowerCase().replace(/[^a-z0-9]/g, '_');

            // Validate field type
            const validTypes = ['text', 'number', 'boolean', 'date', 'select', 'multiselect'];
            if (!validTypes.includes(type)) {
                return { success: false, error: 'Invalid field type' };
            }

            // Parse options for select/multiselect fields
            let parsedOptions = null;
            if (type === 'select' || type === 'multiselect') {
                if (!options.trim()) {
                    return { success: false, error: 'Options are required for select fields' };
                }
                parsedOptions = options.split('\n').map(opt => opt.trim()).filter(opt => opt);
            }

            const admin = getSupabaseAdmin();
            
            // Verify the field set belongs to this teacher
            const { data: fieldSet, error: setError } = await (admin as any)
                .from('student_field_sets')
                .select('id')
                .eq('id', params.id)
                .eq('teacher_id', profile.id)
                .single();

            if (setError || !fieldSet) {
                return { success: false, error: 'Field set not found' };
            }

            const { error } = await (admin as any)
                .from('student_fields')
                .insert({
                    field_set_id: params.id,
                    key,
                    label: name,
                    type,
                    required,
                    options: parsedOptions
                });

            if (error) return { success: false, error: error.message };
            return { success: true };
        } catch (e: any) {
            return { success: false, error: e?.message || 'Unknown error' };
        }
    },

    update_field: async ({ request, url, locals, cookies, params }) => {
        try {
            const supabase = createServerSupabaseClient({ url, locals, cookies } as any);
            const { profile } = await AuthService.getCurrentUserServer(supabase);
            if (!profile || profile.role !== 'teacher') {
                return { success: false, error: 'Access denied' };
            }

            const form = await request.formData();
            const fieldId = String(form.get('field_id') || '').trim();
            const name = String(form.get('name') || '').trim();
            const type = String(form.get('type') || '').trim();
            const required = form.get('required') === 'on';
            const options = String(form.get('options') || '').trim();

            if (!fieldId || !name || !type) {
                return { success: false, error: 'Missing required fields' };
            }

            // Convert name to key (lowercase, replace spaces with underscores)
            const key = name.toLowerCase().replace(/[^a-z0-9]/g, '_');

            const validTypes = ['text', 'number', 'boolean', 'date', 'select', 'multiselect'];
            if (!validTypes.includes(type)) {
                return { success: false, error: 'Invalid field type' };
            }

            let parsedOptions = null;
            if (type === 'select' || type === 'multiselect') {
                if (!options.trim()) {
                    return { success: false, error: 'Options are required for select fields' };
                }
                parsedOptions = options.split('\n').map(opt => opt.trim()).filter(opt => opt);
            }

            const admin = getSupabaseAdmin();
            
            // Verify the field belongs to this teacher's field set
            const { data: field, error: fieldError } = await (admin as any)
                .from('student_fields')
                .select('id, field_set_id, student_field_sets!inner(teacher_id)')
                .eq('id', fieldId)
                .eq('student_field_sets.teacher_id', profile.id)
                .single();

            if (fieldError || !field) {
                return { success: false, error: 'Field not found' };
            }

            const { error } = await (admin as any)
                .from('student_fields')
                .update({ key, label: name, type, required, options: parsedOptions })
                .eq('id', fieldId);

            if (error) return { success: false, error: error.message };
            return { success: true };
        } catch (e: any) {
            return { success: false, error: e?.message || 'Unknown error' };
        }
    },

    delete_field: async ({ request, url, locals, cookies, params }) => {
        try {
            const supabase = createServerSupabaseClient({ url, locals, cookies } as any);
            const { profile } = await AuthService.getCurrentUserServer(supabase);
            if (!profile || profile.role !== 'teacher') {
                return { success: false, error: 'Access denied' };
            }

            const form = await request.formData();
            const fieldId = String(form.get('field_id') || '').trim();

            if (!fieldId) {
                return { success: false, error: 'Missing field ID' };
            }

            console.log('Delete field - fieldId:', fieldId, 'params.id:', params.id, 'profile.id:', profile.id);

            const admin = getSupabaseAdmin();
            
            // First verify the field set belongs to this teacher
            const { data: fieldSet, error: setError } = await (admin as any)
                .from('student_field_sets')
                .select('id')
                .eq('id', params.id)
                .eq('teacher_id', profile.id)
                .single();

            if (setError || !fieldSet) {
                return { success: false, error: 'Field set not found' };
            }

            // Then verify the field exists in this field set
            const { data: field, error: fieldError } = await (admin as any)
                .from('student_fields')
                .select('id')
                .eq('id', fieldId)
                .eq('field_set_id', params.id)
                .single();

            console.log('Field query result:', { field, fieldError });

            if (fieldError || !field) {
                return { success: false, error: 'Field not found' };
            }

            const { error } = await (admin as any)
                .from('student_fields')
                .delete()
                .eq('id', fieldId);

            if (error) return { success: false, error: error.message };
            return { success: true };
        } catch (e: any) {
            return { success: false, error: e?.message || 'Unknown error' };
        }
    }
};
