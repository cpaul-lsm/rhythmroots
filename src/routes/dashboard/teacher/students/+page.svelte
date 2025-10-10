<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { Users, Mail, Phone, Calendar, BookOpen, DollarSign, Search } from 'lucide-svelte';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();
	let students = $state<any[]>([]);
	let loading = $state(true);
	let searchTerm = $state('');
	let selectedCourse = $state('all');

	// Get unique courses for filtering
	let courses = $state<any[]>([]);

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
				enrollments?.forEach(enrollment => {
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

	// Filter students based on search term and course
	let filteredStudents = $derived(() => {
		return students.filter(student => {
			const matchesSearch = !searchTerm || 
				student.first_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
				student.last_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
				student.email.toLowerCase().includes(searchTerm.toLowerCase());
			
			const matchesCourse = selectedCourse === 'all' || 
				student.enrollments.some((enrollment: any) => enrollment.course_id === selectedCourse);
			
			return matchesSearch && matchesCourse;
		});
	});

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
		<h1 class="text-3xl font-bold text-gray-900">My Students</h1>
		<p class="mt-2 text-gray-600">View and manage your enrolled students</p>
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
