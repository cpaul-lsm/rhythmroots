<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
import { Users, Mail, Phone, Calendar, BookOpen, DollarSign, Search, Plus } from 'lucide-svelte';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();
	let students = $state<any[]>([]);
	let loading = $state(true);
	let searchTerm = $state('');
	let selectedCourse = $state('all');
let showCreateModal = $state(false);
let showCustomFieldsModal = $state(false);

	// Get unique courses for filtering
	let courses = $state<any[]>([]);
let dynamicFields = $state<any[]>([]);
let fieldSets = $state<any[]>([]);
let selectedFieldSetId = $state<string>('');
let fieldsForSelectedSet = $state<any[]>([]);
let setForm = $state({ name: '', description: '' });
let fieldForm = $state({ key: '', label: '', type: 'text', required: false, options: '' as any, order_index: 0 });
let mappingCourseId = $state<string>('');
let attachedSetIdsForCourse = $state<string[]>([]);

	onMount(async () => {
		await Promise.all([loadStudents(), loadCourses()]);
	});

	async function loadStudents() {
		try {
			loading = true;
			
			// Get students enrolled in this teacher's courses
			const { data: enrollments, error: enrollmentError } = await supabase
				.from('student_courses')
				.select(`
					*,
					courses!inner(teacher_id),
					profiles!inner(*)
				`)
				.eq('courses.teacher_id', data.profile.id);

			if (enrollmentError) {
				console.error('Error loading students:', enrollmentError);
			} else {
				// Group by student and get unique students
				const studentMap = new Map();
	enrollments?.forEach((enrollment: any) => {
				const student = enrollment.profiles;
					if (!studentMap.has(student.id)) {
						studentMap.set(student.id, {
							...student,
							enrollments: []
						});
					}
					studentMap.get(student.id).enrollments.push(enrollment);
				});
				
				students = Array.from(studentMap.values());
			}
		} catch (err) {
			console.error('Error loading students:', err);
		} finally {
			loading = false;
		}
	}

	async function loadCourses() {
		try {
			const { data: coursesData, error } = await supabase
				.from('courses')
				.select('id, title')
				.eq('teacher_id', data.profile.id);

			if (error) {
				console.error('Error loading courses:', error);
			} else {
				courses = coursesData || [];
			}
		} catch (err) {
			console.error('Error loading courses:', err);
		}
	}

	// Load dynamic fields for a selected course by fetching attached field sets and fields
	function loadDynamicFields(courseId: string) {
		dynamicFields = [];
		if (!courseId) return;
		supabase
			.from('course_field_sets')
			.select('field_set_id, student_fields:student_field_sets(student_fields(*))')
			.eq('course_id', courseId)
			.eq('active', true)
			.order('order_index')
			.then(({ data, error }) => {
				if (error) {
					console.error('Error loading dynamic fields:', error);
					return;
				}
				const fields: any[] = [];
				(data || []).forEach((row: any) => {
					const setFields = row.student_fields?.student_fields || [];
					setFields
						.filter((f: any) => f.active)
						.sort((a: any, b: any) => (a.order_index ?? 0) - (b.order_index ?? 0))
						.forEach((f: any) => fields.push(f));
				});
				dynamicFields = fields;
			});
	}

// Custom fields manager helpers
async function loadFieldSets() {
    const { data: rows, error } = await (supabase as any)
        .from('student_field_sets')
        .select('*')
        .eq('teacher_id', data.profile.id)
        .order('created_at', { ascending: false });
    if (!error) {
        fieldSets = rows || [];
        if (fieldSets.length && !selectedFieldSetId) {
            selectedFieldSetId = fieldSets[0].id;
            await loadFieldsForSet(selectedFieldSetId);
        }
    } else {
        console.error('Error loading field sets:', error);
    }
}

async function loadFieldsForSet(fieldSetId: string) {
    selectedFieldSetId = fieldSetId;
    const { data: rows2, error } = await (supabase as any)
        .from('student_fields')
        .select('*')
        .eq('field_set_id', fieldSetId)
        .eq('active', true)
        .order('order_index');
    if (!error) {
        fieldsForSelectedSet = rows2 || [];
    } else {
        console.error('Error loading fields:', error);
    }
}

async function createFieldSet() {
    if (!setForm.name.trim()) return;
    const { data: created, error } = await (supabase as any)
        .from('student_field_sets')
        .insert({ teacher_id: data.profile.id, name: setForm.name.trim(), description: setForm.description.trim() || null })
        .select()
        .single();
    if (!error && created) {
        setForm = { name: '', description: '' };
        await loadFieldSets();
    } else {
        console.error('Error creating field set:', error);
    }
}

async function deleteFieldSet(id: string) {
    if (!confirm('Delete this field set?')) return;
    const { error } = await (supabase as any).from('student_field_sets').delete().eq('id', id);
    if (!error) {
        if (selectedFieldSetId === id) {
            selectedFieldSetId = '';
            fieldsForSelectedSet = [];
        }
        await loadFieldSets();
    } else {
        console.error('Error deleting field set:', error);
    }
}

async function createField() {
    if (!selectedFieldSetId || !fieldForm.key.trim() || !fieldForm.label.trim()) return;
    const optionsValue = (() => {
        if (fieldForm.type === 'select' || fieldForm.type === 'multiselect') {
            try {
                const parsed = typeof fieldForm.options === 'string' ? JSON.parse(fieldForm.options || '[]') : fieldForm.options;
                return Array.isArray(parsed) ? parsed : [];
            } catch {
                return [];
            }
        }
        return null;
    })();
    const { error } = await (supabase as any)
        .from('student_fields')
        .insert({
            field_set_id: selectedFieldSetId,
            key: fieldForm.key.trim(),
            label: fieldForm.label.trim(),
            type: fieldForm.type,
            required: fieldForm.required,
            options: optionsValue,
            order_index: Number(fieldForm.order_index) || 0,
            active: true
        });
    if (!error) {
        fieldForm = { key: '', label: '', type: 'text', required: false, options: '', order_index: 0 };
        await loadFieldsForSet(selectedFieldSetId);
    } else {
        console.error('Error creating field:', error);
    }
}

async function deleteField(id: string) {
    const { error } = await (supabase as any).from('student_fields').delete().eq('id', id);
    if (!error) {
        await loadFieldsForSet(selectedFieldSetId);
    } else {
        console.error('Error deleting field:', error);
    }
}

async function loadCourseMappings(courseId: string) {
    mappingCourseId = courseId;
    attachedSetIdsForCourse = [];
    if (!courseId) return;
    const { data, error } = await (supabase as any)
        .from('course_field_sets')
        .select('field_set_id')
        .eq('course_id', courseId)
        .eq('active', true);
    if (!error) {
        attachedSetIdsForCourse = (data || []).map((r: any) => r.field_set_id);
    }
}

async function toggleCourseSet(fieldSetId: string, checked: boolean) {
    if (!mappingCourseId) return;
    if (checked) {
        const { error } = await (supabase as any)
            .from('course_field_sets')
            .insert({ course_id: mappingCourseId, field_set_id: fieldSetId });
        if (error) console.error('Error attaching set:', error);
    } else {
        const { error } = await (supabase as any)
            .from('course_field_sets')
            .delete()
            .eq('course_id', mappingCourseId)
            .eq('field_set_id', fieldSetId);
        if (error) console.error('Error detaching set:', error);
    }
    await loadCourseMappings(mappingCourseId);
}

	// Filter students based on search term and course
	let filteredStudents = $derived(
		students.filter(student => {
			const matchesSearch = !searchTerm ||
				student.first_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
				student.last_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
				student.email.toLowerCase().includes(searchTerm.toLowerCase());

			const matchesCourse = selectedCourse === 'all' ||
				student.enrollments.some((enrollment: any) => enrollment.course_id === selectedCourse);

			return matchesSearch && matchesCourse;
		})
	);

	function getTotalRevenue(student: any) {
		return student.enrollments.reduce((total: number, enrollment: any) => {
			return total + (enrollment.amount_paid || 0);
		}, 0);
	}

	function getEnrolledCourses(student: any) {
		return student.enrollments.length;
	}
</script>

<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
	<div class="mb-8">
		<div class="flex justify-between items-center">
			<div>
				<h1 class="text-3xl font-bold text-gray-900">My Students</h1>
				<p class="mt-2 text-gray-600">View and manage your enrolled students</p>
			</div>
			<button
				onclick={() => (showCreateModal = true)}
				class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
			>
				<Plus class="h-4 w-4 mr-2" />
				Add Student
			</button>
			<a href="/dashboard/teacher/students/fields" class="ml-2 inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md shadow-sm text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">Custom Fields</a>
		</div>
	</div>

	<!-- Search and Filter -->
	<div class="mb-6 bg-white p-4 rounded-lg shadow">
		<div class="flex flex-col sm:flex-row gap-4">
			<div class="flex-1">
				<div class="relative">
					<Search class="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
					<input
						type="text"
						placeholder="Search students..."
						bind:value={searchTerm}
						class="pl-10 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
					/>
				</div>
			</div>
			<div class="sm:w-48">
				<select
					bind:value={selectedCourse}
					class="block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
				>
					<option value="all">All Courses</option>
					{#each courses as course}
						<option value={course.id}>{course.title}</option>
					{/each}
				</select>
			</div>
		</div>
	</div>

	{#if loading}
		<div class="flex justify-center py-12">
			<div class="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
		</div>
	{:else if filteredStudents.length === 0}
		<div class="text-center py-12">
			<Users class="mx-auto h-12 w-12 text-gray-400" />
			<h3 class="mt-2 text-sm font-medium text-gray-900">
				{searchTerm || selectedCourse !== 'all' ? 'No students found' : 'No students yet'}
			</h3>
			<p class="mt-1 text-sm text-gray-500">
				{searchTerm || selectedCourse !== 'all' 
					? 'Try adjusting your search or filter criteria.' 
					: 'Students will appear here once they enroll in your courses.'}
			</p>
		</div>
	{:else}
		<div class="bg-white shadow overflow-hidden sm:rounded-md">
			<ul class="divide-y divide-gray-200">
				{#each filteredStudents as student}
					<li class="px-6 py-4">
						<div class="flex items-center justify-between">
							<div class="flex items-center">
								<div class="flex-shrink-0 h-10 w-10">
									<div class="h-10 w-10 rounded-full bg-indigo-100 flex items-center justify-center">
										<span class="text-sm font-medium text-indigo-600">
											{student.first_name.charAt(0)}{student.last_name.charAt(0)}
										</span>
									</div>
								</div>
								<div class="ml-4">
									<div class="flex items-center">
										<p class="text-sm font-medium text-gray-900">
											{student.first_name} {student.last_name}
										</p>
										<span class="ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
											{student.role}
										</span>
									</div>
									<div class="flex items-center text-sm text-gray-500">
										<Mail class="h-4 w-4 mr-1" />
										{student.email}
									</div>
									{#if student.phone}
										<div class="flex items-center text-sm text-gray-500">
											<Phone class="h-4 w-4 mr-1" />
											{student.phone}
										</div>
									{/if}
								</div>
							</div>
							<div class="flex items-center space-x-6">
								<div class="text-right">
									<div class="flex items-center text-sm text-gray-500">
										<BookOpen class="h-4 w-4 mr-1" />
										{getEnrolledCourses(student)} courses
									</div>
									<div class="flex items-center text-sm font-medium text-gray-900">
										<DollarSign class="h-4 w-4 mr-1" />
										${getTotalRevenue(student).toFixed(2)}
									</div>
								</div>
								<div class="text-sm text-gray-500">
									<Calendar class="h-4 w-4" />
									{new Date(student.created_at).toLocaleDateString()}
								</div>
							</div>
						</div>
						
						<!-- Enrolled Courses -->
						<div class="mt-4 ml-14">
							<h4 class="text-sm font-medium text-gray-900 mb-2">Enrolled Courses:</h4>
							<div class="flex flex-wrap gap-2">
								{#each student.enrollments as enrollment}
									<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
										{enrollment.courses?.title || 'Unknown Course'}
									</span>
								{/each}
							</div>
						</div>
					</li>
				{/each}
			</ul>
		</div>
	{/if}
</div>

<!-- Create Student Modal -->
{#if showCreateModal}
	<div class="fixed inset-0 z-50 overflow-y-auto">
		<div class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
			<button type="button" class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" aria-label="Close" onclick={() => (showCreateModal = false)}></button>

			<div class="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full">
				<form method="POST" action="?/add_student" onsubmit={async (e: SubmitEvent) => {
					e.preventDefault();
					const form = e.currentTarget as HTMLFormElement;
					const formData = new FormData(form);
					const res = await fetch(form.action, { method: 'POST', body: formData });
					const resp = await res.json().catch(() => null);
					if (res.ok && (resp as any)?.success) {
						await loadStudents();
						form.reset();
						showCreateModal = false;
					}
				}}>
					<div class="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
						<div class="sm:flex sm:items-start">
							<div class="w-full">
								<h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">Add Student</h3>
								<div class="space-y-4">
									<div>
										<label for="first_name" class="block text-sm font-medium text-gray-700">First name</label>
										<input id="first_name" name="first_name" type="text" required class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
									</div>
									<div>
										<label for="last_name" class="block text-sm font-medium text-gray-700">Last name</label>
										<input id="last_name" name="last_name" type="text" required class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
									</div>
									<div>
										<label for="email" class="block text-sm font-medium text-gray-700">Email</label>
										<input id="email" name="email" type="email" required class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
									</div>
									<div>
										<label for="phone" class="block text-sm font-medium text-gray-700">Phone (optional)</label>
										<input id="phone" name="phone" type="tel" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
									</div>

									<div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
										<div>
											<label for="address_line1" class="block text-sm font-medium text-gray-700">Address line 1</label>
											<input id="address_line1" name="address_line1" type="text" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
										</div>
										<div>
											<label for="address_line2" class="block text-sm font-medium text-gray-700">Address line 2</label>
											<input id="address_line2" name="address_line2" type="text" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
										</div>
										<div>
											<label for="city" class="block text-sm font-medium text-gray-700">City</label>
											<input id="city" name="city" type="text" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
										</div>
										<div>
											<label for="state" class="block text-sm font-medium text-gray-700">State/Province</label>
											<input id="state" name="state" type="text" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
										</div>
										<div>
											<label for="postal_code" class="block text-sm font-medium text-gray-700">Postal code</label>
											<input id="postal_code" name="postal_code" type="text" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
										</div>
										<div>
											<label for="country" class="block text-sm font-medium text-gray-700">Country</label>
											<input id="country" name="country" type="text" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
										</div>
									</div>

									<div>
										<label for="custom_fields" class="block text-sm font-medium text-gray-700">Custom fields (JSON)</label>
									<textarea id="custom_fields" name="custom_fields" rows="3" placeholder="&#123;&quot;instrument&quot;:&quot;piano&quot;,&quot;level&quot;:&quot;beginner&quot;&#125;" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"></textarea>
										<p class="mt-1 text-xs text-gray-500">Optional JSON for any teacher-defined fields.</p>
									</div>
									<div>
										<label for="course_id" class="block text-sm font-medium text-gray-700">Enroll in course (optional)</label>
                <select id="course_id" name="course_id" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" onchange={(e) => loadDynamicFields((e.target as HTMLSelectElement).value)}>
											<option value="">No course</option>
											{#each courses as course}
												<option value={course.id}>{course.title}</option>
											{/each}
										</select>
									</div>
                                </div>

                                {#if dynamicFields.length > 0}
                                <div class="mt-6 space-y-4">
                                    <h4 class="text-sm font-medium text-gray-900">Course-specific fields</h4>
                                    {#each dynamicFields as field}
                                        <div>
                                            <label for={`field_${field.id}`} class="block text-sm font-medium text-gray-700">{field.label}{field.required ? ' *' : ''}</label>
                                            {#if field.type === 'text'}
                                                <input id={`field_${field.id}`} name={`field_${field.id}`} type="text" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
                                            {:else if field.type === 'number'}
                                                <input id={`field_${field.id}`} name={`field_${field.id}`} type="number" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
                                            {:else if field.type === 'boolean'}
                                                <select id={`field_${field.id}`} name={`field_${field.id}`} class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm">
                                                    <option value="">Select...</option>
                                                    <option value="true">Yes</option>
                                                    <option value="false">No</option>
                                                </select>
                                            {:else if field.type === 'date'}
                                                <input id={`field_${field.id}`} name={`field_${field.id}`} type="date" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
                                            {:else if field.type === 'select'}
                                                <select id={`field_${field.id}`} name={`field_${field.id}`} class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm">
                                                    <option value="">Select...</option>
                                                    {#each (Array.isArray(field.options) ? field.options : field.options?.options || []) as opt}
                                                        <option value={opt}>{opt}</option>
                                                    {/each}
                                                </select>
                                            {:else if field.type === 'multiselect'}
                                                <textarea id={`field_${field.id}`} name={`field_${field.id}`} rows="2" placeholder="Comma-separated values or JSON array" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"></textarea>
                                                <p class="mt-1 text-xs text-gray-500">Enter a JSON array, e.g. ["Mon","Wed"]</p>
                                            {:else}
                                                <input id={`field_${field.id}`} name={`field_${field.id}`} type="text" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
                                            {/if}
                                        </div>
                                    {/each}
                                </div>
                                {/if}
							</div>
						</div>
					</div>

					<div class="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
						<button type="submit" class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-indigo-600 text-base font-medium text-white hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:ml-3 sm:w-auto sm:text-sm">
							Add Student
						</button>
						<button type="button" onclick={() => (showCreateModal = false)} class="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm">
							Cancel
						</button>
					</div>
				</form>
			</div>
		</div>
	</div>
{/if}

<!-- Custom Fields Manager Modal -->
{#if showCustomFieldsModal}
	<div class="fixed inset-0 z-50 overflow-y-auto">
		<div class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
			<button type="button" class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" aria-label="Close" onclick={() => (showCustomFieldsModal = false)}></button>

			<div class="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-4xl sm:w-full">
				<div class="bg-white p-6 grid grid-cols-1 md:grid-cols-2 gap-6">
					<div>
						<h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">Field Sets</h3>
						<div class="space-y-3">
							<div class="flex gap-2">
								<input placeholder="Set name" bind:value={setForm.name} class="flex-1 border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
								<input placeholder="Description" bind:value={setForm.description} class="flex-1 border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
								<button class="px-3 py-2 bg-indigo-600 text-white rounded" onclick={createFieldSet}>Add Set</button>
							</div>
							<ul class="divide-y divide-gray-200 bg-white rounded border">
								{#each fieldSets as set}
								<li class="p-3 flex items-center justify-between">
									<button class="text-left" onclick={() => loadFieldsForSet(set.id)}>{set.name}</button>
									<button class="text-red-600" onclick={() => deleteFieldSet(set.id)}>Delete</button>
								</li>
								{/each}
							</ul>
						</div>
					</div>
					<div>
						<h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">Fields {selectedFieldSetId ? '' : '(select a set)'}</h3>
						{#if selectedFieldSetId}
						<div class="space-y-3">
							<div class="grid grid-cols-1 md:grid-cols-6 gap-2">
								<input placeholder="key" bind:value={fieldForm.key} class="md:col-span-2 border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
								<input placeholder="label" bind:value={fieldForm.label} class="md:col-span-2 border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
								<select bind:value={fieldForm.type} class="border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm">
									<option value="text">text</option>
									<option value="number">number</option>
									<option value="boolean">boolean</option>
									<option value="date">date</option>
									<option value="select">select</option>
									<option value="multiselect">multiselect</option>
								</select>
								<label class="inline-flex items-center text-sm text-gray-700"><input type="checkbox" bind:checked={fieldForm.required} class="mr-2">Required</label>
								<input type="number" placeholder="order" bind:value={fieldForm.order_index} class="border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
								<input placeholder='options JSON ["A","B"]' bind:value={fieldForm.options} class="md:col-span-3 border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
								<button class="px-3 py-2 bg-indigo-600 text-white rounded" onclick={createField}>Add Field</button>
							</div>

							<ul class="divide-y divide-gray-200 bg-white rounded border mt-2">
								{#each fieldsForSelectedSet as f}
								<li class="p-3 flex items-center justify-between">
									<div class="text-sm text-gray-700">{f.label} <span class="text-gray-400">({f.type})</span></div>
									<button class="text-red-600" onclick={() => deleteField(f.id)}>Delete</button>
								</li>
								{/each}
							</ul>
						</div>
						{/if}
					</div>

					<div class="md:col-span-2">
						<h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">Attach Sets to Course</h3>
						<div class="grid grid-cols-1 md:grid-cols-3 gap-2 items-end">
							<div>
								<label for="mapping_course" class="block text-sm font-medium text-gray-700">Course</label>
								<select id="mapping_course" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" bind:value={mappingCourseId} onchange={(e) => loadCourseMappings((e.target as HTMLSelectElement).value)}>
									<option value="">Select course</option>
									{#each courses as c}
										<option value={c.id}>{c.title}</option>
									{/each}
								</select>
							</div>
							<div class="md:col-span-2">
								{#if mappingCourseId}
								<div class="grid grid-cols-1 sm:grid-cols-2 gap-2">
									{#each fieldSets as set}
									<label class="inline-flex items-center">
										<input type="checkbox" checked={attachedSetIdsForCourse.includes(set.id)} onchange={(e) => toggleCourseSet(set.id, (e.target as HTMLInputElement).checked)} class="mr-2">
										<span>{set.name}</span>
									</label>
									{/each}
								</div>
								{/if}
							</div>
						</div>
					</div>

					<div class="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
						<button type="button" onclick={() => (showCustomFieldsModal = false)} class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-indigo-600 text-base font-medium text-white hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:ml-3 sm:w-auto sm:text-sm">
							Close
						</button>
					</div>
				</div>
			</div>
		</div>
	</div>
{/if}
