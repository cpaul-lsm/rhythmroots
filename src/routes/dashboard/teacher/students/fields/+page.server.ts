import type { Actions, PageServerLoad } from './$types';
import { getSupabaseAdmin } from '$lib/supabase-admin';
import { createServerSupabaseClient } from '$lib/supabase-server-helpers';
import { AuthService } from '$lib/auth';

export const load: PageServerLoad = async ({ parent }) => {
    const { profile } = await parent();

    if (!profile || profile.role !== 'teacher') {
        throw new Error('Access denied');
    }

    return { profile };
};

export const actions: Actions = {
    list_sets: async ({ url, locals, cookies }) => {
        try {
            const supabase = createServerSupabaseClient({ url, locals, cookies } as any);
            const { profile } = await AuthService.getCurrentUserServer(supabase);
            if (!profile || profile.role !== 'teacher') {
                return { success: false, error: 'Access denied' };
            }
            const admin = getSupabaseAdmin();
            const { data: rows, error } = await (admin as any)
                .from('student_field_sets')
                .select('*')
                .eq('teacher_id', profile.id)
                .order('created_at', { ascending: false });
            if (error) return { success: false, error: error.message };
            return { success: true, sets: rows || [] };
        } catch (e: any) {
            return { success: false, error: e?.message || 'Unknown error' };
        }
    },
    create_set: async ({ request, url, locals, cookies }) => {
        try {
            const supabase = createServerSupabaseClient({ url, locals, cookies } as any);
            const { profile } = await AuthService.getCurrentUserServer(supabase);
            if (!profile || profile.role !== 'teacher') {
                return { success: false, error: 'Access denied' };
            }
            const form = await request.formData();
            const name = String(form.get('name') || '').trim();
            const description = String(form.get('description') || '').trim();
            if (!name) return { success: false, error: 'Name is required' };
            const admin = getSupabaseAdmin();
            const { error } = await (admin as any)
                .from('student_field_sets')
                .insert({ teacher_id: profile.id, name, description: description || null });
            if (error) return { success: false, error: error.message };
            return { success: true };
        } catch (e: any) {
            return { success: false, error: e?.message || 'Unknown error' };
        }
    },
    update_set: async ({ request, url, locals, cookies }) => {
        try {
            const supabase = createServerSupabaseClient({ url, locals, cookies } as any);
            const { profile } = await AuthService.getCurrentUserServer(supabase);
            if (!profile || profile.role !== 'teacher') {
                return { success: false, error: 'Access denied' };
            }
            const form = await request.formData();
            const id = String(form.get('id') || '').trim();
            const name = String(form.get('name') || '').trim();
            const description = String(form.get('description') || '').trim();
            if (!id || !name) return { success: false, error: 'Missing required fields' };
            const admin = getSupabaseAdmin();
            const { data: own, error: ownErr } = await (admin as any)
                .from('student_field_sets')
                .select('id, teacher_id')
                .eq('id', id)
                .single();
            if (ownErr || !own || own.teacher_id !== profile.id) return { success: false, error: 'Not found' };
            const { error } = await (admin as any)
                .from('student_field_sets')
                .update({ name, description: description || null })
                .eq('id', id);
            if (error) return { success: false, error: error.message };
            return { success: true };
        } catch (e: any) {
            return { success: false, error: e?.message || 'Unknown error' };
        }
    },
    delete_set: async ({ request, url, locals, cookies }) => {
        try {
            const supabase = createServerSupabaseClient({ url, locals, cookies } as any);
            const { profile } = await AuthService.getCurrentUserServer(supabase);
            if (!profile || profile.role !== 'teacher') {
                return { success: false, error: 'Access denied' };
            }
            const form = await request.formData();
            const id = String(form.get('id') || '').trim();
            if (!id) return { success: false, error: 'Missing id' };
            const admin = getSupabaseAdmin();
            const { data: own, error: ownErr } = await (admin as any)
                .from('student_field_sets')
                .select('id, teacher_id')
                .eq('id', id)
                .single();
            if (ownErr || !own || own.teacher_id !== profile.id) return { success: false, error: 'Not found' };
            const { error } = await (admin as any)
                .from('student_field_sets')
                .delete()
                .eq('id', id);
            if (error) return { success: false, error: error.message };
            return { success: true };
        } catch (e: any) {
            return { success: false, error: e?.message || 'Unknown error' };
        }
    }
};


