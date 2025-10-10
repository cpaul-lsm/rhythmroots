<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { User, Mail, Phone, MapPin, Shield, Settings, Save, Loader2, AlertTriangle } from 'lucide-svelte';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();

	let loading = $state(true);
	let saving = $state(false);
	let message = $state('');
	let error = $state('');

	// Profile form data
	let profileData = $state({
		first_name: '',
		last_name: '',
		email: '',
		phone: '',
		account_slug: '',
		address: {
			street: '',
			city: '',
			state: '',
			zip: '',
			country: ''
		},
		custom_fields: {}
	});

	// Admin-specific data
	let adminData = $state({
		total_teachers: 0,
		total_students: 0,
		total_courses: 0,
		platform_revenue: 0,
		last_login: null
	});

	// System settings
	let systemSettings = $state({
		platform_fee_percentage: 5.0,
		monthly_student_fee: 2.50,
		maintenance_mode: false,
		registration_enabled: true,
		email_notifications_enabled: true
	});

	onMount(async () => {
		await Promise.all([loadProfileData(), loadAdminData()]);
	});

	async function loadProfileData() {
		try {
			loading = true;
			
			// Load profile data
			if (data.profile) {
				profileData = {
					first_name: data.profile.first_name || '',
					last_name: data.profile.last_name || '',
					email: data.profile.email || '',
					phone: data.profile.phone || '',
					account_slug: data.profile.account_slug || '',
					address: data.profile.address || {
						street: '',
						city: '',
						state: '',
						zip: '',
						country: ''
					},
					custom_fields: data.profile.custom_fields || {}
				};

				// Load system settings from custom_fields
				if (data.profile.custom_fields?.system_settings) {
					systemSettings = {
						...systemSettings,
						...data.profile.custom_fields.system_settings
					};
				}
			}
		} catch (err) {
			console.error('Error loading profile data:', err);
			error = 'Failed to load profile data';
		} finally {
			loading = false;
		}
	}

	async function loadAdminData() {
		try {
			// Load platform statistics
			const [teachersResult, studentsResult, coursesResult] = await Promise.all([
				supabase
					.from('profiles')
					.select('*', { count: 'exact', head: true })
					.eq('role', 'teacher'),
				supabase
					.from('profiles')
					.select('*', { count: 'exact', head: true })
					.eq('role', 'student'),
				supabase
					.from('courses')
					.select('*', { count: 'exact', head: true })
			]);

			adminData = {
				total_teachers: teachersResult.count || 0,
				total_students: studentsResult.count || 0,
				total_courses: coursesResult.count || 0,
				platform_revenue: 0, // Would be calculated from payments
				last_login: new Date().toISOString()
			};
		} catch (err) {
			console.error('Error loading admin data:', err);
		}
	}

	async function saveProfile() {
		try {
			saving = true;
			error = '';
			message = '';

			const { error: updateError } = await supabase
				.from('profiles')
				.update({
					first_name: profileData.first_name,
					last_name: profileData.last_name,
					phone: profileData.phone,
					address: profileData.address,
					custom_fields: profileData.custom_fields
				})
				.eq('id', data.profile.id);

			if (updateError) {
				throw updateError;
			}

			message = 'Profile updated successfully!';
		} catch (err) {
			console.error('Error saving profile:', err);
			error = err instanceof Error ? err.message : 'Failed to save profile';
		} finally {
			saving = false;
		}
	}

	async function saveSystemSettings() {
		try {
			saving = true;
			error = '';
			message = '';

			// Update system settings in custom_fields
			const updatedCustomFields = {
				...profileData.custom_fields,
				system_settings: systemSettings
			};

			const { error: updateError } = await supabase
				.from('profiles')
				.update({
					custom_fields: updatedCustomFields
				})
				.eq('id', data.profile.id);

			if (updateError) {
				throw updateError;
			}

			profileData.custom_fields = updatedCustomFields;
			message = 'System settings saved!';
		} catch (err) {
			console.error('Error saving system settings:', err);
			error = err instanceof Error ? err.message : 'Failed to save system settings';
		} finally {
			saving = false;
		}
	}
</script>

<div class="px-4 sm:px-6 lg:px-8 py-8">
	<div class="mb-8">
		<h1 class="text-3xl font-bold text-gray-900">Admin Settings</h1>
		<p class="mt-2 text-gray-600">Manage platform settings and your admin profile</p>
	</div>

	{#if loading}
		<div class="flex justify-center py-12">
			<div class="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
		</div>
	{:else}
		<div class="space-y-8">
			<!-- Platform Overview -->
			<div class="bg-white shadow rounded-lg">
				<div class="px-6 py-4 border-b border-gray-200">
					<div class="flex items-center">
						<Settings class="h-5 w-5 text-gray-400 mr-2" />
						<h2 class="text-lg font-medium text-gray-900">Platform Overview</h2>
					</div>
				</div>
				<div class="px-6 py-4">
					<div class="grid grid-cols-1 gap-6 sm:grid-cols-4">
						<div class="text-center">
							<div class="text-2xl font-bold text-indigo-600">{adminData.total_teachers}</div>
							<div class="text-sm text-gray-500">Total Teachers</div>
						</div>
						<div class="text-center">
							<div class="text-2xl font-bold text-green-600">{adminData.total_students}</div>
							<div class="text-sm text-gray-500">Total Students</div>
						</div>
						<div class="text-center">
							<div class="text-2xl font-bold text-blue-600">{adminData.total_courses}</div>
							<div class="text-sm text-gray-500">Total Courses</div>
						</div>
						<div class="text-center">
							<div class="text-2xl font-bold text-yellow-600">${adminData.platform_revenue.toFixed(2)}</div>
							<div class="text-sm text-gray-500">Platform Revenue</div>
						</div>
					</div>
				</div>
			</div>

			<!-- Custom URL -->
			<div class="bg-white shadow rounded-lg">
				<div class="px-6 py-4 border-b border-gray-200">
					<div class="flex items-center">
						<Settings class="h-5 w-5 text-gray-400 mr-2" />
						<h2 class="text-lg font-medium text-gray-900">Custom URL</h2>
					</div>
				</div>
				<div class="px-6 py-4">
					<div>
						<h3 class="text-sm font-medium text-gray-900">Your Custom URL</h3>
						<p class="mt-1 text-sm text-gray-600">
							{#if profileData.account_slug}
								youusingit.live/{profileData.account_slug}
							{:else}
								No custom URL assigned
							{/if}
						</p>
					</div>
				</div>
			</div>

			<!-- System Settings -->
			<div class="bg-white shadow rounded-lg">
				<div class="px-6 py-4 border-b border-gray-200">
					<div class="flex items-center">
						<Settings class="h-5 w-5 text-gray-400 mr-2" />
						<h2 class="text-lg font-medium text-gray-900">System Settings</h2>
					</div>
				</div>
				<div class="px-6 py-4">
					<form onsubmit={(e) => { e.preventDefault(); saveSystemSettings(); }} class="space-y-6">
						<div class="grid grid-cols-1 gap-6 sm:grid-cols-2">
							<div>
								<label for="platform_fee" class="block text-sm font-medium text-gray-700">Platform Fee (%)</label>
								<input
									type="number"
									id="platform_fee"
									bind:value={systemSettings.platform_fee_percentage}
									min="0"
									max="100"
									step="0.1"
									class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
								/>
								<p class="mt-1 text-sm text-gray-500">Percentage taken from each transaction</p>
							</div>
							<div>
								<label for="monthly_fee" class="block text-sm font-medium text-gray-700">Monthly Student Fee ($)</label>
								<input
									type="number"
									id="monthly_fee"
									bind:value={systemSettings.monthly_student_fee}
									min="0"
									step="0.01"
									class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
								/>
								<p class="mt-1 text-sm text-gray-500">Monthly fee per enrolled student</p>
							</div>
						</div>

						<div class="space-y-4">
							<div class="flex items-center justify-between">
								<div>
									<h3 class="text-sm font-medium text-gray-900">Maintenance Mode</h3>
									<p class="text-sm text-gray-500">Temporarily disable platform access</p>
								</div>
								<input
									type="checkbox"
									bind:checked={systemSettings.maintenance_mode}
									class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
								/>
							</div>
							
							<div class="flex items-center justify-between">
								<div>
									<h3 class="text-sm font-medium text-gray-900">Registration Enabled</h3>
									<p class="text-sm text-gray-500">Allow new user registrations</p>
								</div>
								<input
									type="checkbox"
									bind:checked={systemSettings.registration_enabled}
									class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
								/>
							</div>
							
							<div class="flex items-center justify-between">
								<div>
									<h3 class="text-sm font-medium text-gray-900">Email Notifications</h3>
									<p class="text-sm text-gray-500">Enable system-wide email notifications</p>
								</div>
								<input
									type="checkbox"
									bind:checked={systemSettings.email_notifications_enabled}
									class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
								/>
							</div>
						</div>

						<div class="flex justify-end">
							<button
								type="submit"
								disabled={saving}
								class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50 disabled:cursor-not-allowed"
							>
								{#if saving}
									<Loader2 class="h-4 w-4 animate-spin mr-2" />
								{:else}
									<Save class="h-4 w-4 mr-2" />
								{/if}
								{saving ? 'Saving...' : 'Save Settings'}
							</button>
						</div>
					</form>
				</div>
			</div>

			<!-- Profile Information -->
			<div class="bg-white shadow rounded-lg">
				<div class="px-6 py-4 border-b border-gray-200">
					<div class="flex items-center">
						<User class="h-5 w-5 text-gray-400 mr-2" />
						<h2 class="text-lg font-medium text-gray-900">Admin Profile</h2>
					</div>
				</div>
				<div class="px-6 py-4">
					<form onsubmit={(e) => { e.preventDefault(); saveProfile(); }} class="space-y-6">
						<div class="grid grid-cols-1 gap-6 sm:grid-cols-2">
							<div>
								<label for="first_name" class="block text-sm font-medium text-gray-700">First Name</label>
								<input
									type="text"
									id="first_name"
									bind:value={profileData.first_name}
									required
									class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
								/>
							</div>
							<div>
								<label for="last_name" class="block text-sm font-medium text-gray-700">Last Name</label>
								<input
									type="text"
									id="last_name"
									bind:value={profileData.last_name}
									required
									class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
								/>
							</div>
						</div>

						<div>
							<label for="email" class="block text-sm font-medium text-gray-700">Email</label>
							<div class="mt-1 flex rounded-md shadow-sm">
								<span class="inline-flex items-center px-3 rounded-l-md border border-r-0 border-gray-300 bg-gray-50 text-gray-500 text-sm">
									<Mail class="h-4 w-4" />
								</span>
								<input
									type="email"
									id="email"
									bind:value={profileData.email}
									disabled
									class="flex-1 block w-full rounded-none rounded-r-md border-gray-300 sm:text-sm bg-gray-50"
								/>
							</div>
							<p class="mt-1 text-sm text-gray-500">Email cannot be changed. Contact support if needed.</p>
						</div>

						<div>
							<label for="phone" class="block text-sm font-medium text-gray-700">Phone</label>
							<div class="mt-1 flex rounded-md shadow-sm">
								<span class="inline-flex items-center px-3 rounded-l-md border border-r-0 border-gray-300 bg-gray-50 text-gray-500 text-sm">
									<Phone class="h-4 w-4" />
								</span>
								<input
									type="tel"
									id="phone"
									bind:value={profileData.phone}
									class="flex-1 block w-full rounded-none rounded-r-md border-gray-300 focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
								/>
							</div>
						</div>

						<div class="flex justify-end">
							<button
								type="submit"
								disabled={saving}
								class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50 disabled:cursor-not-allowed"
							>
								{#if saving}
									<Loader2 class="h-4 w-4 animate-spin mr-2" />
								{:else}
									<Save class="h-4 w-4 mr-2" />
								{/if}
								{saving ? 'Saving...' : 'Save Profile'}
							</button>
						</div>
					</form>
				</div>
			</div>

			<!-- Security Settings -->
			<div class="bg-white shadow rounded-lg">
				<div class="px-6 py-4 border-b border-gray-200">
					<div class="flex items-center">
						<Shield class="h-5 w-5 text-gray-400 mr-2" />
						<h2 class="text-lg font-medium text-gray-900">Security</h2>
					</div>
				</div>
				<div class="px-6 py-4">
					<div class="space-y-4">
						<div class="flex items-center justify-between">
							<div>
								<h3 class="text-sm font-medium text-gray-900">Change Password</h3>
								<p class="text-sm text-gray-500">Update your admin account password</p>
							</div>
							<button
								type="button"
								class="inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm leading-4 font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
							>
								Change Password
							</button>
						</div>
						
						<div class="flex items-center justify-between">
							<div>
								<h3 class="text-sm font-medium text-gray-900">Two-Factor Authentication</h3>
								<p class="text-sm text-gray-500">Add an extra layer of security to your admin account</p>
							</div>
							<button
								type="button"
								class="inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm leading-4 font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
							>
								Enable 2FA
							</button>
						</div>
					</div>
				</div>
			</div>

			<!-- Danger Zone -->
			<div class="bg-red-50 border border-red-200 rounded-lg">
				<div class="px-6 py-4 border-b border-red-200">
					<div class="flex items-center">
						<AlertTriangle class="h-5 w-5 text-red-400 mr-2" />
						<h2 class="text-lg font-medium text-red-900">Danger Zone</h2>
					</div>
				</div>
				<div class="px-6 py-4">
					<div class="space-y-4">
						<div class="flex items-center justify-between">
							<div>
								<h3 class="text-sm font-medium text-red-900">Reset Platform Data</h3>
								<p class="text-sm text-red-600">Permanently delete all courses, lessons, and user data</p>
							</div>
							<button
								type="button"
								class="inline-flex items-center px-3 py-2 border border-red-300 shadow-sm text-sm leading-4 font-medium rounded-md text-red-700 bg-white hover:bg-red-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
							>
								Reset Platform
							</button>
						</div>
					</div>
				</div>
			</div>
		</div>
	{/if}

	<!-- Messages -->
	{#if message}
		<div class="fixed bottom-4 right-4 bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded">
			{message}
		</div>
	{/if}

	{#if error}
		<div class="fixed bottom-4 right-4 bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded">
			{error}
		</div>
	{/if}
</div>
