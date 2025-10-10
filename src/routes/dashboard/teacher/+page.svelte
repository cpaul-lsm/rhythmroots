<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { BookOpen, Users, DollarSign, TrendingUp, Plus } from 'lucide-svelte';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();

	let courses = $state<any[]>([]);
	let students = $state<any[]>([]);
	let loading = $state(true);
	let stats = $state({
		totalCourses: 0,
		totalStudents: 0,
		monthlyRevenue: 0,
		activeLessons: 0
	});

	onMount(async () => {
		await loadTeacherData();
	});

	async function loadTeacherData() {
		try {
			// Load teacher's courses
			const { data: teacherCourses, error: coursesError } = await supabase
				.from('courses')
				.select('*')
				.eq('teacher_id', data.profile.id)
				.order('created_at', { ascending: false });

			if (coursesError) {
				console.error('Error loading courses:', coursesError);
			} else {
				courses = teacherCourses || [];
			}

			// Load enrolled students
			const { data: enrolledStudents, error: studentsError } = await supabase
				.from('student_courses')
				.select(`
					*,
					profiles!student_courses_student_id_fkey (
						id,
						first_name,
						last_name,
						email
					)
				`)
				.in('course_id', courses.map(c => c.id))
				.eq('payment_status', 'paid');

			if (studentsError) {
				console.error('Error loading students:', studentsError);
			} else {
				students = enrolledStudents || [];
			}

			// Load monthly revenue
			const { data: payments, error: paymentsError } = await supabase
				.from('payments')
				.select('amount, teacher_earnings')
				.eq('teacher_id', data.profile.id)
				.eq('status', 'succeeded')
				.gte('created_at', new Date(new Date().getFullYear(), new Date().getMonth(), 1).toISOString());

			const monthlyRevenue = payments?.reduce((sum: number, payment: any) => sum + (payment.teacher_earnings || 0), 0) || 0;

			// Load active lessons count
			const { count: activeLessonsCount } = await supabase
				.from('course_lessons')
				.select('*', { count: 'exact', head: true })
				.in('course_id', courses.map(c => c.id))
				.eq('status', 'active');

			stats = {
				totalCourses: courses.length,
				totalStudents: students.length,
				monthlyRevenue,
				activeLessons: activeLessonsCount || 0
			};
		} catch (error) {
			console.error('Error loading teacher data:', error);
		} finally {
			loading = false;
		}
	}
</script>

<div class="px-4 py-6 sm:px-0">
	<div class="mb-8">
		<h1 class="text-2xl font-bold text-gray-900">Welcome back, {data.profile.first_name}!</h1>
		<p class="mt-1 text-sm text-gray-600">Here's an overview of your teaching dashboard.</p>
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
							<Users class="h-6 w-6 text-green-600" />
						</div>
						<div class="ml-5 w-0 flex-1">
							<dl>
								<dt class="text-sm font-medium text-gray-500 truncate">Total Students</dt>
								<dd class="text-lg font-medium text-gray-900">{stats.totalStudents}</dd>
							</dl>
						</div>
					</div>
				</div>
			</div>

			<div class="bg-white overflow-hidden shadow rounded-lg">
				<div class="p-5">
					<div class="flex items-center">
						<div class="flex-shrink-0">
							<DollarSign class="h-6 w-6 text-yellow-600" />
						</div>
						<div class="ml-5 w-0 flex-1">
							<dl>
								<dt class="text-sm font-medium text-gray-500 truncate">Monthly Revenue</dt>
								<dd class="text-lg font-medium text-gray-900">${stats.monthlyRevenue.toFixed(2)}</dd>
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
								<dt class="text-sm font-medium text-gray-500 truncate">Active Lessons</dt>
								<dd class="text-lg font-medium text-gray-900">{stats.activeLessons}</dd>
							</dl>
						</div>
					</div>
				</div>
			</div>
		</div>

		<!-- Quick Actions -->
		<div class="bg-white shadow rounded-lg mb-8">
			<div class="px-4 py-5 sm:p-6">
				<h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">Quick Actions</h3>
				<div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
					<a
						href="/dashboard/teacher/courses/new"
						class="relative group bg-white p-6 focus-within:ring-2 focus-within:ring-inset focus-within:ring-indigo-500 rounded-lg border border-gray-300 hover:border-gray-400"
					>
						<div>
							<span class="rounded-lg inline-flex p-3 bg-indigo-50 text-indigo-700 ring-4 ring-white">
								<Plus class="h-6 w-6" />
							</span>
						</div>
						<div class="mt-8">
							<h3 class="text-lg font-medium">
								<span class="absolute inset-0" aria-hidden="true"></span>
								Create Course
							</h3>
							<p class="mt-2 text-sm text-gray-500">Start a new course for your students.</p>
						</div>
					</a>

					<a
						href="/dashboard/teacher/lessons/new"
						class="relative group bg-white p-6 focus-within:ring-2 focus-within:ring-inset focus-within:ring-indigo-500 rounded-lg border border-gray-300 hover:border-gray-400"
					>
						<div>
							<span class="rounded-lg inline-flex p-3 bg-green-50 text-green-700 ring-4 ring-white">
								<BookOpen class="h-6 w-6" />
							</span>
						</div>
						<div class="mt-8">
							<h3 class="text-lg font-medium">
								<span class="absolute inset-0" aria-hidden="true"></span>
								Create Lesson
							</h3>
							<p class="mt-2 text-sm text-gray-500">Add new content to your courses.</p>
						</div>
					</a>

					<a
						href="/dashboard/teacher/students"
						class="relative group bg-white p-6 focus-within:ring-2 focus-within:ring-inset focus-within:ring-indigo-500 rounded-lg border border-gray-300 hover:border-gray-400"
					>
						<div>
							<span class="rounded-lg inline-flex p-3 bg-yellow-50 text-yellow-700 ring-4 ring-white">
								<Users class="h-6 w-6" />
							</span>
						</div>
						<div class="mt-8">
							<h3 class="text-lg font-medium">
								<span class="absolute inset-0" aria-hidden="true"></span>
								Manage Students
							</h3>
							<p class="mt-2 text-sm text-gray-500">View and manage your students.</p>
						</div>
					</a>

					<a
						href="/dashboard/teacher/analytics"
						class="relative group bg-white p-6 focus-within:ring-2 focus-within:ring-inset focus-within:ring-indigo-500 rounded-lg border border-gray-300 hover:border-gray-400"
					>
						<div>
							<span class="rounded-lg inline-flex p-3 bg-purple-50 text-purple-700 ring-4 ring-white">
								<TrendingUp class="h-6 w-6" />
							</span>
						</div>
						<div class="mt-8">
							<h3 class="text-lg font-medium">
								<span class="absolute inset-0" aria-hidden="true"></span>
								View Analytics
							</h3>
							<p class="mt-2 text-sm text-gray-500">Track your course performance.</p>
						</div>
					</a>
				</div>
			</div>
		</div>

		<!-- Recent Courses -->
		<div class="bg-white shadow rounded-lg">
			<div class="px-4 py-5 sm:p-6">
				<div class="flex items-center justify-between mb-4">
					<h3 class="text-lg leading-6 font-medium text-gray-900">Recent Courses</h3>
					<a
						href="/dashboard/teacher/courses"
						class="text-sm font-medium text-indigo-600 hover:text-indigo-500"
					>
						View all
					</a>
				</div>
				
				{#if courses.length === 0}
					<div class="text-center py-12">
						<BookOpen class="mx-auto h-12 w-12 text-gray-400" />
						<h3 class="mt-2 text-sm font-medium text-gray-900">No courses yet</h3>
						<p class="mt-1 text-sm text-gray-500">Get started by creating your first course.</p>
						<div class="mt-6">
							<a
								href="/dashboard/teacher/courses/new"
								class="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
							>
								<Plus class="h-4 w-4 mr-2" />
								Create Course
							</a>
						</div>
					</div>
				{:else}
					<div class="space-y-4">
						{#each courses.slice(0, 5) as course}
							<div class="flex items-center justify-between p-4 border border-gray-200 rounded-lg">
								<div class="flex items-center">
									{#if course.image_url}
										<img
											src={course.image_url}
											alt={course.title}
											class="h-12 w-12 rounded-lg object-cover"
										/>
									{:else}
										<div class="h-12 w-12 bg-gray-200 rounded-lg flex items-center justify-center">
											<BookOpen class="h-6 w-6 text-gray-400" />
										</div>
									{/if}
									<div class="ml-4">
										<h4 class="text-sm font-medium text-gray-900">{course.title}</h4>
										<p class="text-sm text-gray-500">
											{course.is_published ? 'Published' : 'Draft'} • ${course.price}
										</p>
									</div>
								</div>
								<a
									href="/dashboard/teacher/courses/{course.id}"
									class="text-indigo-600 hover:text-indigo-500 text-sm font-medium"
								>
									Manage →
								</a>
							</div>
						{/each}
					</div>
				{/if}
			</div>
		</div>
	{/if}
</div>
