<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { BookOpen, Calendar, MessageSquare, TrendingUp } from 'lucide-svelte';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();

	let courses = $state<any[]>([]);
	let loading = $state(true);
	let stats = $state({
		totalCourses: 0,
		activeLessons: 0,
		unreadMessages: 0
	});

	onMount(async () => {
		await loadStudentData();
	});

	async function loadStudentData() {
		try {
			// Load enrolled courses
			const { data: enrolledCourses, error: coursesError } = await supabase
				.from('student_courses')
				.select(`
					*,
					courses (
						id,
						title,
						description,
						image_url,
						price,
						teacher_id,
						profiles!courses_teacher_id_fkey (
							first_name,
							last_name
						)
					)
				`)
				.eq('student_id', data.profile.id)
				.eq('payment_status', 'paid');

			if (coursesError) {
				console.error('Error loading courses:', coursesError);
			} else {
				courses = enrolledCourses || [];
			}

			// Load active lessons count from enrolled courses
			const courseIds = courses.map(c => c.courses.id).filter(Boolean);
			let activeLessonsCount = 0;
			
			if (courseIds.length > 0) {
				const { count } = await supabase
					.from('course_lessons')
					.select('*', { count: 'exact', head: true })
					.in('course_id', courseIds)
					.eq('status', 'active');
				activeLessonsCount = count || 0;
			}

			// Load unread messages count
			let unreadMessagesCount = 0;
			if (courseIds.length > 0) {
				const { count } = await supabase
					.from('notes')
					.select('*', { count: 'exact', head: true })
					.or(`student_id.eq.${data.profile.id},course_id.in.(${courseIds.join(',')})`)
					.eq('email_sent', true);
				unreadMessagesCount = count || 0;
			}

			stats = {
				totalCourses: courses.length,
				activeLessons: activeLessonsCount || 0,
				unreadMessages: unreadMessagesCount || 0
			};
		} catch (error) {
			console.error('Error loading student data:', error);
		} finally {
			loading = false;
		}
	}
</script>

<div class="px-4 sm:px-6 lg:px-8 py-8">
	<div class="mb-8">
		<h1 class="text-2xl font-bold text-gray-900">Welcome back, {data.profile.first_name}!</h1>
		<p class="mt-1 text-sm text-gray-600">Here's what's happening with your courses.</p>
	</div>

	{#if loading}
		<div class="flex items-center justify-center py-12">
			<div class="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
		</div>
	{:else}
		<!-- Stats Overview -->
		<div class="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4 mb-8">
			<div class="bg-white overflow-hidden shadow rounded-lg">
				<div class="p-5">
					<div class="flex items-center">
						<div class="flex-shrink-0">
							<BookOpen class="h-6 w-6 text-indigo-600" />
						</div>
						<div class="ml-5 w-0 flex-1">
							<dl>
								<dt class="text-sm font-medium text-gray-500 truncate">Total Courses</dt>
								<dd class="text-lg font-medium text-gray-900">{stats.totalCourses}</dd>
							</dl>
						</div>
					</div>
				</div>
			</div>

			<div class="bg-white overflow-hidden shadow rounded-lg">
				<div class="p-5">
					<div class="flex items-center">
						<div class="flex-shrink-0">
							<Calendar class="h-6 w-6 text-green-600" />
						</div>
						<div class="ml-5 w-0 flex-1">
							<dl>
								<dt class="text-sm font-medium text-gray-500 truncate">Active Lessons</dt>
								<dd class="text-lg font-medium text-gray-900">{stats.activeLessons}</dd>
							</dl>
						</div>
					</div>
				</div>
			</div>

			<div class="bg-white overflow-hidden shadow rounded-lg">
				<div class="p-5">
					<div class="flex items-center">
						<div class="flex-shrink-0">
							<MessageSquare class="h-6 w-6 text-yellow-600" />
						</div>
						<div class="ml-5 w-0 flex-1">
							<dl>
								<dt class="text-sm font-medium text-gray-500 truncate">Unread Messages</dt>
								<dd class="text-lg font-medium text-gray-900">{stats.unreadMessages}</dd>
							</dl>
						</div>
					</div>
				</div>
			</div>

			<div class="bg-white overflow-hidden shadow rounded-lg">
				<div class="p-5">
					<div class="flex items-center">
						<div class="flex-shrink-0">
							<TrendingUp class="h-6 w-6 text-purple-600" />
						</div>
						<div class="ml-5 w-0 flex-1">
							<dl>
								<dt class="text-sm font-medium text-gray-500 truncate">Progress</dt>
								<dd class="text-lg font-medium text-gray-900">0%</dd>
							</dl>
						</div>
					</div>
				</div>
			</div>
		</div>

		<!-- My Courses -->
		<div class="bg-white shadow rounded-lg">
			<div class="px-4 py-5 sm:p-6">
				<h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">My Courses</h3>
				
				{#if courses.length === 0}
					<div class="text-center py-12">
						<BookOpen class="mx-auto h-12 w-12 text-gray-400" />
						<h3 class="mt-2 text-sm font-medium text-gray-900">No courses yet</h3>
						<p class="mt-1 text-sm text-gray-500">Get started by enrolling in a course.</p>
						<div class="mt-6">
							<a
								href="/courses"
								class="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
							>
								Browse Courses
							</a>
						</div>
					</div>
				{:else}
					<div class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
						{#each courses as course}
							<div class="bg-white border border-gray-200 rounded-lg shadow-sm hover:shadow-md transition-shadow">
								{#if course.courses.image_url}
									<img
										src={course.courses.image_url}
										alt={course.courses.title}
										class="w-full h-48 object-cover rounded-t-lg"
									/>
								{:else}
									<div class="w-full h-48 bg-gray-200 rounded-t-lg flex items-center justify-center">
										<BookOpen class="h-12 w-12 text-gray-400" />
									</div>
								{/if}
								
								<div class="p-6">
									<h4 class="text-lg font-medium text-gray-900 mb-2">
										{course.courses.title}
									</h4>
									<p class="text-sm text-gray-600 mb-4 line-clamp-2">
										{course.courses.description || 'No description available.'}
									</p>
									<div class="flex items-center justify-between">
										<span class="text-sm text-gray-500">
											By {course.courses.profiles.first_name} {course.courses.profiles.last_name}
										</span>
										<a
											href="/dashboard/student/courses/{course.course_id}"
											class="text-indigo-600 hover:text-indigo-500 text-sm font-medium"
										>
											View Course →
										</a>
									</div>
								</div>
							</div>
						{/each}
					</div>
				{/if}
			</div>
		</div>
	{/if}
</div>