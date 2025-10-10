<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { Plus, Edit, Eye, Trash2, BookOpen, Calendar, Search, Filter } from 'lucide-svelte';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();
	let lessons = $state<any[]>([]);
	let courses = $state<any[]>([]);
	let loading = $state(true);
	let showCreateModal = $state(false);
	let editingLesson = $state<any>(null);
	let searchTerm = $state('');
	let selectedCourse = $state('all');
	let submitting = $state(false);

	// Form data for creating/editing lessons
	let formData = $state({
		title: '',
		description: '',
		content_blocks: []
	});

	onMount(async () => {
		await Promise.all([loadLessons(), loadCourses()]);
	});

	async function loadLessons() {
		try {
			loading = true;
			console.log('Loading lessons for teacher ID:', data.profile.id);
			
			// Simple query - just get all lessons first
			const { data: allLessons, error: allError } = await supabase
				.from('lessons')
				.select('*');
			
			console.log('All lessons query:', { allLessons, allError, count: allLessons?.length });
			
			// If we get lessons, filter by teacher_id
			if (allLessons && allLessons.length > 0) {
				lessons = allLessons.filter(lesson => lesson.teacher_id === data.profile.id);
				console.log('Filtered lessons:', lessons.length);
			} else {
				lessons = [];
				console.log('No lessons found in database');
			}
		} catch (err) {
			console.error('Error loading lessons:', err);
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

	async function createLesson() {
		console.log('Creating lesson with data:', $state.snapshot(formData));
		
		if (!formData.title.trim()) {
			alert('Please enter a lesson title');
			return;
		}

		submitting = true;

		try {
			const { data: newLesson, error } = await supabase
				.from('lessons')
				.insert({
					title: formData.title.trim(),
					description: formData.description.trim(),
					content_blocks: formData.content_blocks,
					teacher_id: data.profile.id
				})
				.select()
				.single();

			if (error) {
				console.error('Error creating lesson:', error);
				alert(`Error creating lesson: ${error.message}`);
			} else {
				lessons = [newLesson, ...lessons];
				resetForm();
				showCreateModal = false;
			}
		} catch (err) {
			console.error('Error creating lesson:', err);
			alert(`Error creating lesson: ${err instanceof Error ? err.message : 'Unknown error'}`);
		} finally {
			submitting = false;
		}
	}

	async function updateLesson() {
		if (!editingLesson) return;

		try {
			const { data: updatedLesson, error } = await supabase
				.from('lessons')
				.update({
					title: formData.title,
					description: formData.description,
					content_blocks: formData.content_blocks
				})
				.eq('id', editingLesson.id)
				.select()
				.single();

			if (error) {
				console.error('Error updating lesson:', error);
			} else {
				lessons = lessons.map(lesson => 
					lesson.id === editingLesson.id ? updatedLesson : lesson
				);
				resetForm();
				showCreateModal = false;
			}
		} catch (err) {
			console.error('Error updating lesson:', err);
		}
	}

	async function deleteLesson(lessonId: string) {
		if (!confirm('Are you sure you want to delete this lesson?')) return;

		try {
			const { error } = await supabase
				.from('lessons')
				.delete()
				.eq('id', lessonId);

			if (error) {
				console.error('Error deleting lesson:', error);
			} else {
				lessons = lessons.filter(lesson => lesson.id !== lessonId);
			}
		} catch (err) {
			console.error('Error deleting lesson:', err);
		}
	}

	function editLesson(lesson: any) {
		editingLesson = lesson;
		formData = {
			title: lesson.title,
			description: lesson.description || '',
			content_blocks: lesson.content_blocks || []
		};
		showCreateModal = true;
	}

	function resetForm() {
		formData = {
			title: '',
			description: '',
			content_blocks: []
		};
		editingLesson = null;
	}

	function openCreateModal() {
		resetForm();
		showCreateModal = true;
	}

	function closeModal() {
		showCreateModal = false;
		resetForm();
	}

	// Filter lessons based on search term
	let filteredLessons = $state([]);
	
	// Update filtered lessons when lessons or searchTerm changes
	$effect(() => {
		const filtered = lessons.filter(lesson => {
			const matchesSearch = !searchTerm || 
				lesson.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
				(lesson.description && lesson.description.toLowerCase().includes(searchTerm.toLowerCase()));
			
			return matchesSearch;
		});
		
		filteredLessons = filtered;
	});
</script>

<div class="px-4 sm:px-6 lg:px-8 py-8">
	<div class="mb-8">
		<div class="flex justify-between items-center">
			<div>
				<h1 class="text-3xl font-bold text-gray-900">My Lessons</h1>
				<p class="mt-2 text-gray-600">Create and manage your lesson content</p>
			</div>
			<button
				onclick={openCreateModal}
				class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
			>
				<Plus class="h-4 w-4 mr-2" />
				Create Lesson
			</button>
		</div>
	</div>

	<!-- Search -->
	<div class="mb-6">
		<div class="relative">
			<Search class="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
			<input
				type="text"
				placeholder="Search lessons..."
				bind:value={searchTerm}
				class="pl-10 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
			/>
		</div>
	</div>

	{#if loading}
		<div class="flex justify-center py-12">
			<div class="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
		</div>
	{:else if filteredLessons.length === 0}
		<div class="text-center py-12">
			<BookOpen class="mx-auto h-12 w-12 text-gray-400" />
			<h3 class="mt-2 text-sm font-medium text-gray-900">
				{searchTerm ? 'No lessons found' : 'No lessons yet'}
			</h3>
			<p class="mt-1 text-sm text-gray-500">
				{searchTerm 
					? 'Try adjusting your search criteria.' 
					: 'Get started by creating your first lesson.'}
			</p>
			{#if !searchTerm}
				<div class="mt-6">
					<button
						onclick={openCreateModal}
						class="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700"
					>
						<Plus class="h-4 w-4 mr-2" />
						Create Lesson
					</button>
				</div>
			{/if}
		</div>
	{:else}
		<div class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
			{#each filteredLessons as lesson}
				<div class="bg-white overflow-hidden shadow rounded-lg">
					<div class="p-6">
						<div class="flex items-center justify-between">
							<div class="flex-1 min-w-0">
								<h3 class="text-lg font-medium text-gray-900 truncate">
									{lesson.title}
								</h3>
								<p class="mt-1 text-sm text-gray-500 line-clamp-2">
									{lesson.description || 'No description'}
								</p>
							</div>
						</div>
						
						<div class="mt-4">
							<div class="flex items-center text-sm text-gray-500">
								<Calendar class="h-4 w-4 mr-1" />
								{new Date(lesson.created_at).toLocaleDateString()}
							</div>
							{#if lesson.content_blocks && lesson.content_blocks.length > 0}
								<div class="mt-2 text-sm text-gray-500">
									{lesson.content_blocks.length} content block{lesson.content_blocks.length !== 1 ? 's' : ''}
								</div>
							{/if}
						</div>
						
						<div class="px-6 py-4 bg-gray-50 border-t border-gray-200">
							<div class="flex justify-end space-x-2">
								<button
									onclick={() => editLesson(lesson)}
									class="text-indigo-600 hover:text-indigo-900"
								>
									<Edit class="h-4 w-4" />
								</button>
								<button
									onclick={() => deleteLesson(lesson.id)}
									class="text-red-600 hover:text-red-900"
								>
									<Trash2 class="h-4 w-4" />
								</button>
							</div>
						</div>
					</div>
				</div>
			{/each}
		</div>
	{/if}
</div>

<!-- Create/Edit Lesson Modal -->
{#if showCreateModal}
	<div class="fixed inset-0 z-50 overflow-y-auto">
		<div class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
			<div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" onclick={closeModal}></div>
			
			<div class="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full">
				<form onsubmit={(e) => { e.preventDefault(); editingLesson ? updateLesson() : createLesson(); }}>
					<div class="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
						<div class="sm:flex sm:items-start">
							<div class="w-full">
								<h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">
									{editingLesson ? 'Edit Lesson' : 'Create New Lesson'}
								</h3>
								
								<div class="space-y-4">
									<div>
										<label for="title" class="block text-sm font-medium text-gray-700">Lesson Title</label>
										<input
											type="text"
											id="title"
											bind:value={formData.title}
											required
											class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
										/>
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
										<label class="block text-sm font-medium text-gray-700">Content Blocks</label>
										<p class="mt-1 text-sm text-gray-500">
											Content blocks will be added in a future update. For now, you can create the basic lesson structure.
										</p>
									</div>
								</div>
							</div>
						</div>
					</div>
					
					<div class="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
						<button
							type="submit"
							disabled={submitting}
							class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-indigo-600 text-base font-medium text-white hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50 disabled:cursor-not-allowed sm:ml-3 sm:w-auto sm:text-sm"
						>
							{#if submitting}
								<div class="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
							{/if}
							{editingLesson ? 'Update Lesson' : 'Create Lesson'}
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
