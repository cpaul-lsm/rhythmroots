<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { Users, User, DollarSign, TrendingUp, AlertTriangle } from 'lucide-svelte';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();

	let teachers = $state<any[]>([]);
	let students = $state<any[]>([]);
	let loading = $state(true);
	let stats = $state({
		totalTeachers: 0,
		totalStudents: 0,
		platformRevenue: 0,
		activeSubscriptions: 0
	});

	onMount(async () => {
		await loadAdminData();
	});

	async function loadAdminData() {
		try {
			// Load all teachers
			const { data: allTeachers, error: teachersError } = await supabase
				.from('profiles')
				.select('*')
				.eq('role', 'teacher')
				.order('created_at', { ascending: false });

			if (teachersError) {
				console.error('Error loading teachers:', teachersError);
			} else {
				teachers = allTeachers || [];
			}

			// Load all students
			const { data: allStudents, error: studentsError } = await supabase
				.from('profiles')
				.select('*')
				.eq('role', 'student')
				.order('created_at', { ascending: false });

			if (studentsError) {
				console.error('Error loading students:', studentsError);
			} else {
				students = allStudents || [];
			}

			// Load platform revenue
			const { data: payments, error: paymentsError } = await supabase
				.from('payments')
				.select('platform_fee')
				.eq('status', 'succeeded')
				.gte('created_at', new Date(new Date().getFullYear(), new Date().getMonth(), 1).toISOString());

			const platformRevenue = payments?.reduce((sum: number, payment: any) => sum + (payment.platform_fee || 0), 0) || 0;

			// Load active subscriptions
			const { count: activeSubscriptionsCount } = await supabase
				.from('profiles')
				.select('*', { count: 'exact', head: true })
				.eq('subscription_active', true);

			stats = {
				totalTeachers: teachers.length,
				totalStudents: students.length,
				platformRevenue,
				activeSubscriptions: activeSubscriptionsCount || 0
			};
		} catch (error) {
			console.error('Error loading admin data:', error);
		} finally {
			loading = false;
		}
	}
</script>

<div class="px-4 py-6 sm:px-0">
	<div class="mb-8">
		<h1 class="text-2xl font-bold text-gray-900">Admin Dashboard</h1>
		<p class="mt-1 text-sm text-gray-600">Platform overview and management.</p>
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
							<Users class="h-6 w-6 text-indigo-600" />
						</div>
						<div class="ml-5 w-0 flex-1">
							<dl>
								<dt class="text-sm font-medium text-gray-500 truncate">Total Teachers</dt>
								<dd class="text-lg font-medium text-gray-900">{stats.totalTeachers}</dd>
							</dl>
						</div>
					</div>
				</div>
			</div>

			<div class="bg-white overflow-hidden shadow rounded-lg">
				<div class="p-5">
					<div class="flex items-center">
						<div class="flex-shrink-0">
							<User class="h-6 w-6 text-green-600" />
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
								<dt class="text-sm font-medium text-gray-500 truncate">Platform Revenue</dt>
								<dd class="text-lg font-medium text-gray-900">${stats.platformRevenue.toFixed(2)}</dd>
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
								<dt class="text-sm font-medium text-gray-500 truncate">Active Subscriptions</dt>
								<dd class="text-lg font-medium text-gray-900">{stats.activeSubscriptions}</dd>
							</dl>
						</div>
					</div>
				</div>
			</div>
		</div>

		<!-- Recent Teachers -->
		<div class="bg-white shadow rounded-lg mb-8">
			<div class="px-4 py-5 sm:p-6">
				<div class="flex items-center justify-between mb-4">
					<h3 class="text-lg leading-6 font-medium text-gray-900">Recent Teachers</h3>
					<a
						href="/dashboard/admin/teachers"
						class="text-sm font-medium text-indigo-600 hover:text-indigo-500"
					>
						View all
					</a>
				</div>
				
				{#if teachers.length === 0}
					<div class="text-center py-12">
						<Users class="mx-auto h-12 w-12 text-gray-400" />
						<h3 class="mt-2 text-sm font-medium text-gray-900">No teachers yet</h3>
						<p class="mt-1 text-sm text-gray-500">Teachers will appear here once they register.</p>
					</div>
				{:else}
					<div class="space-y-4">
						{#each teachers.slice(0, 5) as teacher}
							<div class="flex items-center justify-between p-4 border border-gray-200 rounded-lg">
								<div class="flex items-center">
									<div class="h-10 w-10 rounded-full bg-indigo-500 flex items-center justify-center">
										<span class="text-sm font-medium text-white">
											{teacher.first_name[0]}{teacher.last_name[0]}
										</span>
									</div>
									<div class="ml-4">
										<h4 class="text-sm font-medium text-gray-900">
											{teacher.first_name} {teacher.last_name}
										</h4>
										<p class="text-sm text-gray-500">{teacher.email}</p>
									</div>
								</div>
								<div class="flex items-center space-x-2">
									<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
										{teacher.subscription_plan}
									</span>
									{#if teacher.is_suspended}
										<AlertTriangle class="h-4 w-4 text-red-500" />
									{/if}
								</div>
							</div>
						{/each}
					</div>
				{/if}
			</div>
		</div>

		<!-- Recent Students -->
		<div class="bg-white shadow rounded-lg">
			<div class="px-4 py-5 sm:p-6">
				<div class="flex items-center justify-between mb-4">
					<h3 class="text-lg leading-6 font-medium text-gray-900">Recent Students</h3>
					<a
						href="/dashboard/admin/students"
						class="text-sm font-medium text-indigo-600 hover:text-indigo-500"
					>
						View all
					</a>
				</div>
				
				{#if students.length === 0}
					<div class="text-center py-12">
						<User class="mx-auto h-12 w-12 text-gray-400" />
						<h3 class="mt-2 text-sm font-medium text-gray-900">No students yet</h3>
						<p class="mt-1 text-sm text-gray-500">Students will appear here once they register.</p>
					</div>
				{:else}
					<div class="space-y-4">
						{#each students.slice(0, 5) as student}
							<div class="flex items-center justify-between p-4 border border-gray-200 rounded-lg">
								<div class="flex items-center">
									<div class="h-10 w-10 rounded-full bg-green-500 flex items-center justify-center">
										<span class="text-sm font-medium text-white">
											{student.first_name[0]}{student.last_name[0]}
										</span>
									</div>
									<div class="ml-4">
										<h4 class="text-sm font-medium text-gray-900">
											{student.first_name} {student.last_name}
										</h4>
										<p class="text-sm text-gray-500">{student.email}</p>
									</div>
								</div>
								<div class="flex items-center space-x-2">
									<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
										Student
									</span>
									{#if student.is_suspended}
										<AlertTriangle class="h-4 w-4 text-red-500" />
									{/if}
								</div>
							</div>
						{/each}
					</div>
				{/if}
			</div>
		</div>
	{/if}
</div>
