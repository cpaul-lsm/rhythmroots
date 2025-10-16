import type { Actions, PageServerLoad } from './$types';
import { getSupabaseAdmin } from '$lib/supabase-admin';
import { createServerSupabaseClient } from '$lib/supabase-server-helpers';
import { AuthService } from '$lib/auth';

export const load: PageServerLoad = async ({ parent }) => {
    const { profile } = await parent();

    if (!profile || profile.role !== 'teacher') {
        throw new Error('Access denied');
    }

    const admin = getSupabaseAdmin();
    
    // Load teacher's courses
    const { data: courses, error: coursesError } = await (admin as any)
        .from('courses')
        .select('id, title, course_code')
        .eq('teacher_id', profile.id)
        .order('title', { ascending: true });

    if (coursesError) {
        console.error('Error loading courses:', coursesError);
    }

    return { 
        profile, 
        courses: courses || [] 
    };
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
                
            if (ownErr || !own || own.teacher_id !== profile.id) {
                return { success: false, error: 'Not found' };
            }
            
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
    },
    
    assign_to_course: async ({ request, url, locals, cookies }) => {
        try {
            const supabase = createServerSupabaseClient({ url, locals, cookies } as any);
            const { profile } = await AuthService.getCurrentUserServer(supabase);
            if (!profile || profile.role !== 'teacher') {
                return { success: false, error: 'Access denied' };
            }
            
            const form = await request.formData();
            const fieldSetId = String(form.get('field_set_id') || '').trim();
            const courseId = String(form.get('course_id') || '').trim();
            
            if (!fieldSetId || !courseId) {
                return { success: false, error: 'Missing required fields' };
            }
            
            const admin = getSupabaseAdmin();
            
            // Verify the field set belongs to this teacher
            const { data: fieldSet, error: setError } = await (admin as any)
                .from('student_field_sets')
                .select('id')
                .eq('id', fieldSetId)
                .eq('teacher_id', profile.id)
                .single();
                
            if (setError || !fieldSet) {
                console.error('Field set verification error:', setError);
                return { success: false, error: 'Field set not found' };
            }
            
            // Verify the course belongs to this teacher
            const { data: course, error: courseError } = await (admin as any)
                .from('courses')
                .select('id')
                .eq('id', courseId)
                .eq('teacher_id', profile.id)
                .single();
                
            if (courseError || !course) {
                console.error('Course verification error:', courseError);
                return { success: false, error: 'Course not found' };
            }
            
            // Insert the assignment (upsert to handle duplicates)
            const { error } = await (admin as any)
                .from('course_field_sets')
                .upsert({
                    course_id: courseId,
                    field_set_id: fieldSetId,
                    active: true
                }, {
                    onConflict: 'course_id,field_set_id'
                });
                
            if (error) {
                console.error('Course assignment insert error:', error);
                return { success: false, error: error.message };
            }
            return { success: true };
        } catch (e: any) {
            console.error('assign_to_course error:', e);
            return { success: false, error: e?.message || 'Unknown error' };
        }
    },
    
    unassign_from_course: async ({ request, url, locals, cookies }) => {
        try {
            const supabase = createServerSupabaseClient({ url, locals, cookies } as any);
            const { profile } = await AuthService.getCurrentUserServer(supabase);
            if (!profile || profile.role !== 'teacher') {
                return { success: false, error: 'Access denied' };
            }
            
            const form = await request.formData();
            const fieldSetId = String(form.get('field_set_id') || '').trim();
            const courseId = String(form.get('course_id') || '').trim();
            
            if (!fieldSetId || !courseId) {
                return { success: false, error: 'Missing required fields' };
            }
            
            const admin = getSupabaseAdmin();
            
            // Verify the field set belongs to this teacher
            const { data: fieldSet, error: setError } = await (admin as any)
                .from('student_field_sets')
                .select('id')
                .eq('id', fieldSetId)
                .eq('teacher_id', profile.id)
                .single();
                
            if (setError || !fieldSet) {
                return { success: false, error: 'Field set not found' };
            }
            
            // Verify the course belongs to this teacher
            console.log('Unassign: Looking for course with ID:', courseId, 'type:', typeof courseId);
            const { data: course, error: courseError } = await (admin as any)
                .from('courses')
                .select('id')
                .eq('id', courseId)
                .eq('teacher_id', profile.id)
                .single();
                
            console.log('Unassign: Course query result:', { course, courseError });
            if (courseError || !course) {
                return { success: false, error: 'Course not found' };
            }
            
            // Remove the assignment
            const { error } = await (admin as any)
                .from('course_field_sets')
                .delete()
                .eq('course_id', courseId)
                .eq('field_set_id', fieldSetId);
                
            if (error) return { success: false, error: error.message };
            return { success: true };
        } catch (e: any) {
            return { success: false, error: e?.message || 'Unknown error' };
        }
    },
    
    get_course_assignments: async ({ request, url, locals, cookies }) => {
        try {
            const supabase = createServerSupabaseClient({ url, locals, cookies } as any);
            const { profile } = await AuthService.getCurrentUserServer(supabase);
            if (!profile || profile.role !== 'teacher') {
                return { success: false, error: 'Access denied' };
            }
            
            const form = await request.formData();
            const fieldSetId = String(form.get('field_set_id') || '').trim();
            
            if (!fieldSetId) {
                return { success: false, error: 'Missing field set ID' };
            }
            
            const admin = getSupabaseAdmin();
            
            // Verify the field set belongs to this teacher
            const { data: fieldSet, error: setError } = await (admin as any)
                .from('student_field_sets')
                .select('id')
                .eq('id', fieldSetId)
                .eq('teacher_id', profile.id)
                .single();
                
            if (setError || !fieldSet) {
                console.error('Field set verification error:', setError);
                return { success: false, error: 'Field set not found' };
            }
            
            // Get course assignments for this field set
            const { data: assignments, error } = await (admin as any)
                .from('course_field_sets')
                .select(`
                    course_id,
                    courses!inner(
                        title,
                        course_code
                    )
                `)
                .eq('field_set_id', fieldSetId)
                .eq('active', true);
                
            if (error) {
                console.error('Course assignments query error:', error);
                return { success: false, error: error.message };
            }
            
            // Transform the data to a simpler format
            const transformedAssignments = (assignments || []).map((assignment: any) => ({
                course_id: assignment.course_id,
                courses: {
                    title: assignment.courses.title,
                    course_code: assignment.courses.course_code
                }
            }));
            
            return { success: true, assignments: transformedAssignments };
        } catch (e: any) {
            console.error('get_course_assignments error:', e);
            return { success: false, error: e?.message || 'Unknown error' };
        }
    }
};


