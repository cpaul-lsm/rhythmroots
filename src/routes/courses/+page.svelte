<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { BookOpen, Search, Filter } from 'lucide-svelte';

	let courses = $state<any[]>([]);
	let loading = $state(true);
	let searchTerm = $state('');
	let filteredCourses = $state<any[]>([]);

	onMount(async () => {
		await loadCourses();
	});

	async function loadCourses() {
		try {
			const { data: allCourses, error } = await supabase
				.from('courses')
				.select(`
					*,
					profiles!courses_teacher_id_fkey (
						first_name,
						last_name
					)
				`)
				.eq('is_published', true)
				.order('created_at', { ascending: false });

			if (error) {
				console.error('Error loading courses:', error);
			} else {
				courses = allCourses || [];
				filteredCourses = courses;
			}
		} catch (error) {
			console.error('Error loading courses:', error);
		} finally {
			loading = false;
		}
	}

	function filterCourses() {
		if (!searchTerm.trim()) {
			filteredCourses = courses;
		} else {
			filteredCourses = courses.filter(course =>
				course.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
				course.description?.toLowerCase().includes(searchTerm.toLowerCase()) ||
				`${course.profiles.first_name} ${course.profiles.last_name}`.toLowerCase().includes(searchTerm.toLowerCase())
			);
		}
	}

	$effect(() => {
		filterCourses();
	});
</script>

<div class="min-h-screen bg-gray-50">
	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
		<div class="mb-8">
			<h1 class="text-3xl font-bold text-gray-900">Browse Courses</h1>
			<p class="mt-2 text-gray-600">Discover amazing courses from our talented teachers.</p>
		</div>

		<!-- Search and Filter -->
		<div class="mb-8">
			<div class="relative">
				<div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
					<Search class="h-5 w-5 text-gray-400" />
				</div>
				<input
					type="text"
					placeholder="Search courses, teachers, or topics..."
					bind:value={searchTerm}
					class="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-md leading-5 bg-white placeholder-gray-500 focus:outline-none focus:placeholder-gray-400 focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
				/>
			</div>
		</div>

		{#if loading}
			<div class="flex items-center justify-center py-12">
				<div class="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
			</div>
		{:else if filteredCourses.length === 0}
			<div class="text-center py-12">
				<BookOpen class="mx-auto h-12 w-12 text-gray-400" />
				<h3 class="mt-2 text-sm font-medium text-gray-900">
					{searchTerm ? 'No courses found' : 'No courses available'}
				</h3>
				<p class="mt-1 text-sm text-gray-500">
					{searchTerm ? 'Try adjusting your search terms.' : 'Check back later for new courses.'}
				</p>
			</div>
		{:else}
			<div class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
				{#each filteredCourses as course}
					<div class="bg-white border border-gray-200 rounded-lg shadow-sm hover:shadow-md transition-shadow">
						{#if course.image_url}
							<img
								src={course.image_url}
								alt={course.title}
								class="w-full h-48 object-cover rounded-t-lg"
							/>
						{:else}
							<div class="w-full h-48 bg-gray-200 rounded-t-lg flex items-center justify-center">
								<BookOpen class="h-12 w-12 text-gray-400" />
							</div>
						{/if}
						
						<div class="p-6">
							<h3 class="text-lg font-medium text-gray-900 mb-2">
								{course.title}
							</h3>
							<p class="text-sm text-gray-600 mb-4 line-clamp-3">
								{course.description || 'No description available.'}
							</p>
							<div class="flex items-center justify-between mb-4">
								<span class="text-sm text-gray-500">
									By {course.profiles.first_name} {course.profiles.last_name}
								</span>
								<span class="text-lg font-semibold text-gray-900">
									${course.price}
								</span>
							</div>
							<div class="flex space-x-2">
								<a
									href="/courses/{course.id}"
									class="flex-1 bg-indigo-600 text-white text-center px-4 py-2 rounded-md text-sm font-medium hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
								>
									View Details
								</a>
								<button
									class="flex-1 bg-gray-100 text-gray-700 px-4 py-2 rounded-md text-sm font-medium hover:bg-gray-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-500"
								>
									Enroll
								</button>
							</div>
						</div>
					</div>
				{/each}
			</div>
		{/if}
	</div>
</div>
