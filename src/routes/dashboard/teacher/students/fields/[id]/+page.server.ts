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
        .order('order_index', { ascending: true });

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
                .order('order_index', { ascending: true });
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
            const half_width = form.get('half_width') === 'on';

            // Section titles should never be required or half-width
            const isSectionTitle = type === 'section_title';
            const finalRequired = isSectionTitle ? false : required;
            const finalHalfWidth = isSectionTitle ? false : half_width;

            if (!name || !type) {
                return { success: false, error: 'Name and type are required' };
            }

            // Convert name to key (lowercase, replace spaces with underscores)
            const key = name.toLowerCase().replace(/[^a-z0-9]/g, '_');

            // Validate field type
            const validTypes = ['text', 'textarea', 'number', 'boolean', 'date', 'email', 'phone', 'select', 'multiselect', 'section_title'];
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

            // Get the next order index
            const { data: maxOrder } = await (admin as any)
                .from('student_fields')
                .select('order_index')
                .eq('field_set_id', params.id)
                .order('order_index', { ascending: false })
                .limit(1)
                .single();

            const nextOrderIndex = (maxOrder?.order_index ?? -1) + 1;

            const { error } = await (admin as any)
                .from('student_fields')
                .insert({
                    field_set_id: params.id,
                    key,
                    label: name,
                    type,
                    required: finalRequired,
                    options: parsedOptions,
                    half_width: finalHalfWidth,
                    order_index: nextOrderIndex
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
            const half_width = form.get('half_width') === 'on';

            // Section titles should never be required or half-width
            const isSectionTitle = type === 'section_title';
            const finalRequired = isSectionTitle ? false : required;
            const finalHalfWidth = isSectionTitle ? false : half_width;

            if (!fieldId || !name || !type) {
                return { success: false, error: 'Missing required fields' };
            }

            // Convert name to key (lowercase, replace spaces with underscores)
            const key = name.toLowerCase().replace(/[^a-z0-9]/g, '_');

            const validTypes = ['text', 'textarea', 'number', 'boolean', 'date', 'email', 'phone', 'select', 'multiselect', 'section_title'];
            if (!validTypes.includes(type)) {
                console.log('Update field - Invalid field type:', type, 'Valid types:', validTypes);
                return { success: false, error: `Invalid field type: ${type}` };
            }

            let parsedOptions = null;
            if (type === 'select' || type === 'multiselect') {
                if (!options.trim()) {
                    return { success: false, error: 'Options are required for select fields' };
                }
                parsedOptions = options.split('\n').map(opt => opt.trim()).filter(opt => opt);
            }

            console.log('Update field - Processing:', { fieldId, name, type, required, options: parsedOptions });
            const admin = getSupabaseAdmin();
            
            // Verify the field belongs to this teacher's field set
            const { data: field, error: fieldError } = await (admin as any)
                .from('student_fields')
                .select('id, field_set_id, student_field_sets!inner(teacher_id)')
                .eq('id', fieldId)
                .eq('student_field_sets.teacher_id', profile.id)
                .single();

            if (fieldError || !field) {
                console.log('Update field - Field not found:', { fieldError, field });
                return { success: false, error: 'Field not found' };
            }

            console.log('Update field - Updating with data:', { key, label: name, type, required: finalRequired, options: parsedOptions, half_width: finalHalfWidth });
            const { error } = await (admin as any)
                .from('student_fields')
                .update({ key, label: name, type, required: finalRequired, options: parsedOptions, half_width: finalHalfWidth })
                .eq('id', fieldId);

            if (error) {
                console.log('Update field - Database error:', error);
                return { success: false, error: error.message };
            }
            console.log('Update field - Success');
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
    },

    update_field_order: async ({ request, url, locals, cookies, params }) => {
        try {
            const supabase = createServerSupabaseClient({ url, locals, cookies } as any);
            const { profile } = await AuthService.getCurrentUserServer(supabase);
            if (!profile || profile.role !== 'teacher') {
                return { success: false, error: 'Access denied' };
            }

            const form = await request.formData();
            const fieldOrdersJson = String(form.get('field_orders') || '').trim();
            
            if (!fieldOrdersJson) {
                return { success: false, error: 'Missing field orders' };
            }

            let fieldOrders;
            try {
                fieldOrders = JSON.parse(fieldOrdersJson);
            } catch (e) {
                return { success: false, error: 'Invalid field orders format' };
            }

            if (!Array.isArray(fieldOrders)) {
                return { success: false, error: 'Field orders must be an array' };
            }

            const admin = getSupabaseAdmin();
            
            // Verify the field set belongs to this teacher
            const { data: fieldSet, error: setError } = await (admin as any)
                .from('student_field_sets')
                .select('id, teacher_id')
                .eq('id', params.id)
                .eq('teacher_id', profile.id)
                .single();

            if (setError || !fieldSet) {
                return { success: false, error: 'Field set not found' };
            }

            // Update each field's order
            for (const fieldOrder of fieldOrders) {
                if (!fieldOrder.id || typeof fieldOrder.order_index !== 'number') {
                    continue;
                }

                const { error } = await (admin as any)
                    .from('student_fields')
                    .update({ order_index: fieldOrder.order_index })
                    .eq('id', fieldOrder.id)
                    .eq('field_set_id', params.id);

                if (error) {
                    console.error('Error updating field order:', error);
                    return { success: false, error: `Failed to update field order: ${error.message}` };
                }
            }

            return { success: true };
        } catch (e: any) {
            return { success: false, error: e?.message || 'Unknown error' };
        }
    },

    duplicate_field: async ({ request, url, locals, cookies, params }) => {
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

            console.log('Duplicate field - fieldId:', fieldId, 'params.id:', params.id, 'profile.id:', profile.id);

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

            // Get the original field
            const { data: originalField, error: fieldError } = await (admin as any)
                .from('student_fields')
                .select('*')
                .eq('id', fieldId)
                .eq('field_set_id', params.id)
                .single();

            if (fieldError || !originalField) {
                return { success: false, error: 'Field not found' };
            }

            // Get the order index of the original field
            const originalOrderIndex = originalField.order_index;

            // Get all fields that come after the original field and update their order indices
            const { data: fieldsToUpdate, error: updateError } = await (admin as any)
                .from('student_fields')
                .select('id, order_index')
                .eq('field_set_id', params.id)
                .gt('order_index', originalOrderIndex);

            if (updateError) {
                console.error('Error getting fields to update:', updateError);
                return { success: false, error: 'Failed to get fields for update' };
            }

            // Update each field's order index
            for (const field of fieldsToUpdate || []) {
                await (admin as any)
                    .from('student_fields')
                    .update({ order_index: field.order_index + 1 })
                    .eq('id', field.id);
            }

            // Create the duplicate field with a modified label and key
            const duplicateLabel = `${originalField.label} (Copy)`;
            const duplicateKey = `${originalField.key}_copy_${Date.now()}`;

            const { error: insertError } = await (admin as any)
                .from('student_fields')
                .insert({
                    field_set_id: params.id,
                    key: duplicateKey,
                    label: duplicateLabel,
                    type: originalField.type,
                    required: originalField.required,
                    options: originalField.options,
                    half_width: originalField.half_width,
                    order_index: originalOrderIndex + 1
                });

            if (insertError) {
                console.error('Error duplicating field:', insertError);
                return { success: false, error: insertError.message };
            }

            console.log('Field duplicated successfully');
            return { success: true };
        } catch (e: any) {
            return { success: false, error: e?.message || 'Unknown error' };
        }
    }
};
