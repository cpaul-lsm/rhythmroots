<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import { AuthService } from '$lib/auth';
	import { supabase } from '$lib/supabase';
	import { BookOpen, Users, GraduationCap, ArrowRight } from 'lucide-svelte';
	import DatabaseTest from '$lib/components/DatabaseTest.svelte';

	let courses = $state<any[]>([]);
	let loading = $state(true);

	onMount(async () => {
		// Load some sample courses for the landing page
		await loadCourses();
	});

	async function loadCourses() {
		try {
			const { data: sampleCourses, error } = await supabase
				.from('courses')
				.select(`
					*,
					profiles!courses_teacher_id_fkey (
						first_name,
						last_name
					)
				`)
				.eq('is_published', true)
				.limit(6);

			if (error) {
				console.error('Error loading courses:', error);
			} else {
				courses = sampleCourses || [];
			}
		} catch (error) {
			console.error('Error loading courses:', error);
		} finally {
			loading = false;
		}
	}
</script>

<div class="min-h-screen bg-white">
	<!-- Hero Section -->
	<div class="relative bg-gradient-to-r from-indigo-600 to-purple-600">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-24">
			<div class="text-center">
				<h1 class="text-4xl font-extrabold text-white sm:text-5xl md:text-6xl">
					Rhythm Roots
				</h1>
				<p class="mt-3 max-w-md mx-auto text-base text-indigo-200 sm:text-lg md:mt-5 md:text-xl md:max-w-3xl">
					The complete learning management system for music education. Connect teachers and students in a modern, intuitive platform.
				</p>
				<div class="mt-5 max-w-md mx-auto sm:flex sm:justify-center md:mt-8">
					<div class="rounded-md shadow">
						<a
							href="/auth/register"
							class="w-full flex items-center justify-center px-8 py-3 border border-transparent text-base font-medium rounded-md text-indigo-600 bg-white hover:bg-indigo-50 md:py-4 md:text-lg md:px-10"
						>
							Get Started
						</a>
					</div>
					<div class="mt-3 rounded-md shadow sm:mt-0 sm:ml-3">
						<a
							href="/auth/login"
							class="w-full flex items-center justify-center px-8 py-3 border border-transparent text-base font-medium rounded-md text-white bg-indigo-500 hover:bg-indigo-400 md:py-4 md:text-lg md:px-10"
						>
							Sign In
						</a>
					</div>
				</div>
			</div>
		</div>
	</div>

	<!-- Features Section -->
	<div class="py-12 bg-gray-50">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<div class="text-center">
				<h2 class="text-3xl font-extrabold text-gray-900 sm:text-4xl">
					Everything you need to teach and learn
				</h2>
				<p class="mt-4 max-w-2xl text-xl text-gray-600 mx-auto">
					Powerful tools for teachers, engaging experiences for students, and comprehensive analytics for administrators.
				</p>
			</div>

			<div class="mt-12">
				<div class="grid grid-cols-1 gap-8 sm:grid-cols-2 lg:grid-cols-3">
					<div class="text-center">
						<div class="flex items-center justify-center h-12 w-12 rounded-md bg-indigo-500 text-white mx-auto">
							<GraduationCap class="h-6 w-6" />
						</div>
						<h3 class="mt-6 text-lg font-medium text-gray-900">For Students</h3>
						<p class="mt-2 text-base text-gray-500">
							Access your courses, complete lessons, and communicate with your teachers all in one place.
						</p>
					</div>

					<div class="text-center">
						<div class="flex items-center justify-center h-12 w-12 rounded-md bg-indigo-500 text-white mx-auto">
							<Users class="h-6 w-6" />
						</div>
						<h3 class="mt-6 text-lg font-medium text-gray-900">For Teachers</h3>
						<p class="mt-2 text-base text-gray-500">
							Create courses, manage students, track progress, and earn money from your expertise.
						</p>
					</div>

					<div class="text-center">
						<div class="flex items-center justify-center h-12 w-12 rounded-md bg-indigo-500 text-white mx-auto">
							<BookOpen class="h-6 w-6" />
						</div>
						<h3 class="mt-6 text-lg font-medium text-gray-900">For Administrators</h3>
						<p class="mt-2 text-base text-gray-500">
							Monitor platform health, manage users, and track revenue across all courses.
						</p>
					</div>
				</div>
			</div>
		</div>
	</div>

	<!-- Courses Section -->
	<div class="py-12 bg-white">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<div class="text-center">
				<h2 class="text-3xl font-extrabold text-gray-900 sm:text-4xl">
					Featured Courses
				</h2>
				<p class="mt-4 max-w-2xl text-xl text-gray-600 mx-auto">
					Discover amazing courses created by our talented teachers.
				</p>
			</div>

			{#if loading}
				<div class="flex items-center justify-center py-12">
					<div class="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
				</div>
			{:else if courses.length === 0}
				<div class="text-center py-12">
					<BookOpen class="mx-auto h-12 w-12 text-gray-400" />
					<h3 class="mt-2 text-sm font-medium text-gray-900">No courses available</h3>
					<p class="mt-1 text-sm text-gray-500">Check back later for new courses.</p>
				</div>
			{:else}
				<div class="mt-12 grid grid-cols-1 gap-8 sm:grid-cols-2 lg:grid-cols-3">
					{#each courses as course}
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
								<p class="text-sm text-gray-600 mb-4 line-clamp-2">
									{course.description || 'No description available.'}
								</p>
								<div class="flex items-center justify-between">
									<span class="text-sm text-gray-500">
										By {course.profiles.first_name} {course.profiles.last_name}
									</span>
									<span class="text-lg font-semibold text-gray-900">
										${course.price}
									</span>
								</div>
							</div>
						</div>
					{/each}
				</div>

				<div class="mt-8 text-center">
					<a
						href="/courses"
						class="inline-flex items-center px-6 py-3 border border-transparent text-base font-medium rounded-md text-indigo-600 bg-indigo-100 hover:bg-indigo-200"
					>
						View All Courses
						<ArrowRight class="ml-2 h-4 w-4" />
					</a>
				</div>
			{/if}
		</div>
	</div>

	<!-- CTA Section -->
	<div class="bg-indigo-700">
		<div class="max-w-2xl mx-auto text-center py-16 px-4 sm:py-20 sm:px-6 lg:px-8">
			<h2 class="text-3xl font-extrabold text-white sm:text-4xl">
				<span class="block">Ready to get started?</span>
				<span class="block">Join thousands of teachers and students.</span>
			</h2>
			<p class="mt-4 text-lg leading-6 text-indigo-200">
				Start teaching or learning today with our comprehensive platform.
			</p>
			<a
				href="/auth/register"
				class="mt-8 w-full inline-flex items-center justify-center px-5 py-3 border border-transparent text-base font-medium rounded-md text-indigo-600 bg-white hover:bg-indigo-50 sm:w-auto"
			>
				Get Started
			</a>
		</div>
	</div>

	<!-- Database Test Section (temporary) -->
	<div class="py-12 bg-gray-100">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<DatabaseTest />
		</div>
	</div>
</div>