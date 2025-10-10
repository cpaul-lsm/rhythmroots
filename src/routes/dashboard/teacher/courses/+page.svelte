<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { Plus, Edit, Eye, Trash2, BookOpen, Users, DollarSign } from 'lucide-svelte';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();
	let courses = $state<any[]>([]);
	let loading = $state(true);
	let showCreateModal = $state(false);
	let editingCourse = $state<any>(null);

	// Form data for creating/editing courses
	let formData = $state({
		title: '',
		course_code: '',
		description: '',
		price: 0,
		is_published: false
	});

	onMount(async () => {
		await loadCourses();
	});

	async function loadCourses() {
		try {
			loading = true;
			const { data: coursesData, error } = await supabase
				.from('courses')
				.select('*')
				.eq('teacher_id', data.profile.id)
				.order('created_at', { ascending: false });

			if (error) {
				console.error('Error loading courses:', error);
			} else {
				courses = coursesData || [];
			}
		} catch (err) {
			console.error('Error loading courses:', err);
		} finally {
			loading = false;
		}
	}

	async function createCourse() {
		try {
			const { data: newCourse, error } = await supabase
				.from('courses')
				.insert({
					teacher_id: data.profile.id,
					title: formData.title,
					course_code: formData.course_code,
					description: formData.description,
					price: formData.price,
					is_published: formData.is_published
				})
				.select()
				.single();

			if (error) {
				console.error('Error creating course:', error);
			} else {
				courses = [newCourse, ...courses];
				resetForm();
				showCreateModal = false;
			}
		} catch (err) {
			console.error('Error creating course:', err);
		}
	}

	async function updateCourse() {
		if (!editingCourse) return;

		try {
			const { data: updatedCourse, error } = await supabase
				.from('courses')
				.update({
					title: formData.title,
					course_code: formData.course_code,
					description: formData.description,
					price: formData.price,
					is_published: formData.is_published
				})
				.eq('id', editingCourse.id)
				.select()
				.single();

			if (error) {
				console.error('Error updating course:', error);
			} else {
				courses = courses.map(course => 
					course.id === editingCourse.id ? updatedCourse : course
				);
				resetForm();
				showCreateModal = false;
			}
		} catch (err) {
			console.error('Error updating course:', err);
		}
	}

	async function deleteCourse(courseId: string) {
		if (!confirm('Are you sure you want to delete this course?')) return;

		try {
			const { error } = await supabase
				.from('courses')
				.delete()
				.eq('id', courseId);

			if (error) {
				console.error('Error deleting course:', error);
			} else {
				courses = courses.filter(course => course.id !== courseId);
			}
		} catch (err) {
			console.error('Error deleting course:', err);
		}
	}

	function editCourse(course: any) {
		editingCourse = course;
		formData = {
			title: course.title,
			course_code: course.course_code || '',
			description: course.description || '',
			price: course.price || 0,
			is_published: course.is_published || false
		};
		showCreateModal = true;
	}

	function resetForm() {
		formData = {
			title: '',
			course_code: '',
			description: '',
			price: 0,
			is_published: false
		};
		editingCourse = null;
	}

	function openCreateModal() {
		resetForm();
		showCreateModal = true;
	}

	function closeModal() {
		showCreateModal = false;
		resetForm();
	}
</script>

<div class="px-4 sm:px-6 lg:px-8 py-8">
	<div class="mb-8">
		<div class="flex justify-between items-center">
			<div>
				<h1 class="text-3xl font-bold text-gray-900">My Courses</h1>
				<p class="mt-2 text-gray-600">Manage your courses and track student enrollment</p>
			</div>
			<button
				onclick={openCreateModal}
				class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
			>
				<Plus class="h-4 w-4 mr-2" />
				Create Course
			</button>
		</div>
	</div>

	{#if loading}
		<div class="flex justify-center py-12">
			<div class="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
		</div>
	{:else if courses.length === 0}
		<div class="text-center py-12">
			<BookOpen class="mx-auto h-12 w-12 text-gray-400" />
			<h3 class="mt-2 text-sm font-medium text-gray-900">No courses yet</h3>
			<p class="mt-1 text-sm text-gray-500">Get started by creating your first course.</p>
			<div class="mt-6">
				<button
					onclick={openCreateModal}
					class="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700"
				>
					<Plus class="h-4 w-4 mr-2" />
					Create Course
				</button>
			</div>
		</div>
	{:else}
		<div class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
			{#each courses as course}
				<div class="bg-white overflow-hidden shadow rounded-lg">
					<div class="p-6">
						<div class="flex items-center justify-between">
							<div class="flex-1 min-w-0">
								<h3 class="text-lg font-medium text-gray-900 truncate">
									{course.title}
								</h3>
								<p class="mt-1 text-sm font-medium text-indigo-600">
									{course.course_code || 'No code'}
								</p>
								<p class="mt-1 text-sm text-gray-500 line-clamp-2">
									{course.description || 'No description'}
								</p>
							</div>
							<div class="ml-4 flex-shrink-0">
								<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium {course.is_published ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-yellow-800'}">
									{course.is_published ? 'Published' : 'Draft'}
								</span>
							</div>
						</div>
						
						<div class="px-6 py-4 bg-gray-50 border-t border-gray-200">
							<div class="flex items-center justify-between">
								<div class="flex items-center text-sm text-gray-500">
									<DollarSign class="h-4 w-4 mr-1" />
									${course.price || 0}
								</div>
								<div class="flex space-x-2">
									<button
										onclick={() => editCourse(course)}
										class="text-indigo-600 hover:text-indigo-900"
									>
										<Edit class="h-4 w-4" />
									</button>
									<button
										onclick={() => deleteCourse(course.id)}
										class="text-red-600 hover:text-red-900"
									>
										<Trash2 class="h-4 w-4" />
									</button>
								</div>
							</div>
						</div>
					</div>
				</div>
			{/each}
		</div>
	{/if}
</div>

<!-- Create/Edit Course Modal -->
{#if showCreateModal}
	<div class="fixed inset-0 z-50 overflow-y-auto">
		<div class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
			<div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" onclick={closeModal}></div>
			
			<div class="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full">
				<form onsubmit={(e) => { e.preventDefault(); editingCourse ? updateCourse() : createCourse(); }}>
					<div class="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
						<div class="sm:flex sm:items-start">
							<div class="w-full">
								<h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">
									{editingCourse ? 'Edit Course' : 'Create New Course'}
								</h3>
								
								<div class="space-y-4">
									<div>
										<label for="title" class="block text-sm font-medium text-gray-700">Course Title</label>
										<input
											type="text"
											id="title"
											bind:value={formData.title}
											required
											class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
										/>
									</div>
									
									<div>
										<label for="course_code" class="block text-sm font-medium text-gray-700">Course Code</label>
										<input
											type="text"
											id="course_code"
											bind:value={formData.course_code}
											placeholder="e.g., MATH101, ENG201"
											required
											class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
										/>
										<p class="mt-1 text-sm text-gray-500">A unique identifier for this course (e.g., MATH101, ENG201)</p>
									</div>
									
									<div>
										<label for="description" class="block text-sm font-medium text-gray-700">Description</label>
										<textarea
											id="description"
											bind:value={formData.description}
											rows="3"
											class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
										></textarea>
									</div>
									
									<div>
										<label for="price" class="block text-sm font-medium text-gray-700">Price ($)</label>
										<input
											type="number"
											id="price"
											bind:value={formData.price}
											min="0"
											step="0.01"
											class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
										/>
									</div>
									
									<div class="flex items-center">
										<input
											type="checkbox"
											id="is_published"
											bind:checked={formData.is_published}
											class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
										/>
										<label for="is_published" class="ml-2 block text-sm text-gray-900">
											Publish this course
										</label>
									</div>
								</div>
							</div>
						</div>
					</div>
					
					<div class="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
						<button
							type="submit"
							class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-indigo-600 text-base font-medium text-white hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:ml-3 sm:w-auto sm:text-sm"
						>
							{editingCourse ? 'Update Course' : 'Create Course'}
						</button>
						<button
							type="button"
							onclick={closeModal}
							class="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm"
						>
							Cancel
						</button>
					</div>
				</form>
			</div>
		</div>
	</div>
{/if}
