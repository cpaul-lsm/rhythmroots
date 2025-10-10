<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { User, Mail, Phone, MapPin, CreditCard, Bell, Shield, Save, Loader2, QrCode } from 'lucide-svelte';
	import QRCodeComponent from '$lib/components/QRCode.svelte';
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

	// Subscription data
	let subscriptionData = $state({
		plan: 'starter',
		active: false,
		storage_used: 0,
		messages_sent: 0,
		subscription_start: null as string | null,
		subscription_end: null as string | null
	});

	// Notification preferences
	let notificationPrefs = $state({
		email_notifications: true,
		course_updates: true,
		payment_reminders: true,
		marketing_emails: false
	});

	// Country and state/province data
	let countries = [
		{ code: 'US', name: 'United States' },
		{ code: 'CA', name: 'Canada' }
	];

	let usStates = [
		{ code: 'AL', name: 'Alabama' }, { code: 'AK', name: 'Alaska' }, { code: 'AZ', name: 'Arizona' },
		{ code: 'AR', name: 'Arkansas' }, { code: 'CA', name: 'California' }, { code: 'CO', name: 'Colorado' },
		{ code: 'CT', name: 'Connecticut' }, { code: 'DE', name: 'Delaware' }, { code: 'FL', name: 'Florida' },
		{ code: 'GA', name: 'Georgia' }, { code: 'HI', name: 'Hawaii' }, { code: 'ID', name: 'Idaho' },
		{ code: 'IL', name: 'Illinois' }, { code: 'IN', name: 'Indiana' }, { code: 'IA', name: 'Iowa' },
		{ code: 'KS', name: 'Kansas' }, { code: 'KY', name: 'Kentucky' }, { code: 'LA', name: 'Louisiana' },
		{ code: 'ME', name: 'Maine' }, { code: 'MD', name: 'Maryland' }, { code: 'MA', name: 'Massachusetts' },
		{ code: 'MI', name: 'Michigan' }, { code: 'MN', name: 'Minnesota' }, { code: 'MS', name: 'Mississippi' },
		{ code: 'MO', name: 'Missouri' }, { code: 'MT', name: 'Montana' }, { code: 'NE', name: 'Nebraska' },
		{ code: 'NV', name: 'Nevada' }, { code: 'NH', name: 'New Hampshire' }, { code: 'NJ', name: 'New Jersey' },
		{ code: 'NM', name: 'New Mexico' }, { code: 'NY', name: 'New York' }, { code: 'NC', name: 'North Carolina' },
		{ code: 'ND', name: 'North Dakota' }, { code: 'OH', name: 'Ohio' }, { code: 'OK', name: 'Oklahoma' },
		{ code: 'OR', name: 'Oregon' }, { code: 'PA', name: 'Pennsylvania' }, { code: 'RI', name: 'Rhode Island' },
		{ code: 'SC', name: 'South Carolina' }, { code: 'SD', name: 'South Dakota' }, { code: 'TN', name: 'Tennessee' },
		{ code: 'TX', name: 'Texas' }, { code: 'UT', name: 'Utah' }, { code: 'VT', name: 'Vermont' },
		{ code: 'VA', name: 'Virginia' }, { code: 'WA', name: 'Washington' }, { code: 'WV', name: 'West Virginia' },
		{ code: 'WI', name: 'Wisconsin' }, { code: 'WY', name: 'Wyoming' }
	];

	let canadianProvinces = [
		{ code: 'AB', name: 'Alberta' }, { code: 'BC', name: 'British Columbia' }, { code: 'MB', name: 'Manitoba' },
		{ code: 'NB', name: 'New Brunswick' }, { code: 'NL', name: 'Newfoundland and Labrador' },
		{ code: 'NS', name: 'Nova Scotia' }, { code: 'ON', name: 'Ontario' }, { code: 'PE', name: 'Prince Edward Island' },
		{ code: 'QC', name: 'Quebec' }, { code: 'SK', name: 'Saskatchewan' }, { code: 'NT', name: 'Northwest Territories' },
		{ code: 'NU', name: 'Nunavut' }, { code: 'YT', name: 'Yukon' }
	];

	let availableStates = $state<{code: string, name: string}[]>([]);
	let stateProvinceLabel = $state('State/Province');

	onMount(async () => {
		await loadProfileData();
		updateStatesForCountry();
	});

	function updateStatesForCountry(clearState = false) {
		if (profileData.address.country === 'US') {
			availableStates = usStates;
			stateProvinceLabel = 'State';
		} else if (profileData.address.country === 'CA') {
			availableStates = canadianProvinces;
			stateProvinceLabel = 'Province';
		} else {
			availableStates = [];
			stateProvinceLabel = 'State/Province';
		}
		// Only clear state selection when country actually changes (not when loading from DB)
		if (clearState) {
			profileData.address.state = '';
		}
	}

	function handleCountryChange() {
		updateStatesForCountry(true);
	}

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

				subscriptionData = {
					plan: data.profile.subscription_plan || 'starter',
					active: data.profile.subscription_active || false,
					storage_used: data.profile.media_storage_used || 0,
					messages_sent: data.profile.messages_sent_this_month || 0,
					subscription_start: data.profile.subscription_start_date,
					subscription_end: data.profile.subscription_end_date
				};

				// Update states/provinces based on loaded country
				updateStatesForCountry();
			}
		} catch (err) {
			console.error('Error loading profile data:', err);
			error = 'Failed to load profile data';
		} finally {
			loading = false;
		}
	}

	async function saveProfile() {
		try {
			saving = true;
			error = '';
			message = '';

			const { error: updateError } = await (supabase as any)
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

	async function saveNotifications() {
		try {
			saving = true;
			error = '';
			message = '';

			// Update notification preferences in custom_fields
			const updatedCustomFields = {
				...profileData.custom_fields,
				notifications: notificationPrefs
			};

			const { error: updateError } = await (supabase as any)
				.from('profiles')
				.update({ custom_fields: updatedCustomFields } as any)
				.eq('id', data.profile.id);

			if (updateError) {
				throw updateError;
			}

			profileData.custom_fields = updatedCustomFields;
			message = 'Notification preferences saved!';
		} catch (err) {
			console.error('Error saving notifications:', err);
			error = err instanceof Error ? err.message : 'Failed to save notification preferences';
		} finally {
			saving = false;
		}
	}

	function getStoragePercentage() {
		const limits = {
			starter: 500, // MB
			freelance: 1024, // MB
			business: 10240 // MB
		};
		const limit = limits[subscriptionData.plan as keyof typeof limits] || 500;
		return Math.round((subscriptionData.storage_used / limit) * 100);
	}

	function getPlanDisplayName(plan: string) {
		const names = {
			starter: 'Starter',
			freelance: 'Freelance',
			business: 'Business'
		};
		return names[plan as keyof typeof names] || plan;
	}

	// Computed property for the full URL
	let fullUrl = $derived(profileData.account_slug ? `https://yousingit.live/${profileData.account_slug}` : '');
</script>

<div class="px-4 sm:px-6 lg:px-8 py-8">
	<div class="mb-8">
		<h1 class="text-3xl font-bold text-gray-900">Settings</h1>
		<p class="mt-2 text-gray-600">Manage your account settings and preferences</p>
	</div>

	{#if loading}
		<div class="flex justify-center py-12">
			<div class="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
		</div>
	{:else}
		<div class="space-y-8">
			<!-- Profile Information -->
			<div class="bg-white shadow rounded-lg">
				<div class="px-6 py-4 border-b border-gray-200">
					<div class="flex items-center">
						<User class="h-5 w-5 text-gray-400 mr-2" />
						<h2 class="text-lg font-medium text-gray-900">Profile Information</h2>
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

						<div>
							<label class="block text-sm font-medium text-gray-700 mb-2">Address</label>
							<div class="space-y-4">
								<div>
									<input
										type="text"
										bind:value={profileData.address.street}
										placeholder="Street Address"
										class="block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
									/>
								</div>
								<div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
									<input
										type="text"
										bind:value={profileData.address.city}
										placeholder="City"
										class="block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
									/>
									<input
										type="text"
										bind:value={profileData.address.zip}
										placeholder="ZIP/Postal Code"
										class="block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
									/>
								</div>
								<div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
									<div>
										<label class="block text-sm font-medium text-gray-700 mb-1">Country</label>
										<select
											bind:value={profileData.address.country}
											onchange={handleCountryChange}
											class="block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
										>
											<option value="">Select Country</option>
											{#each countries as country}
												<option value={country.code}>{country.name}</option>
											{/each}
										</select>
									</div>
									<div>
										<label class="block text-sm font-medium text-gray-700 mb-1">{stateProvinceLabel}</label>
										<select
											bind:value={profileData.address.state}
											disabled={availableStates.length === 0}
											class="block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm disabled:bg-gray-100 disabled:cursor-not-allowed"
										>
											<option value="">Select {stateProvinceLabel}</option>
											{#each availableStates as state}
												<option value={state.code}>{state.name}</option>
											{/each}
										</select>
									</div>
								</div>
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

			<!-- Subscription Information -->
			<div class="bg-white shadow rounded-lg">
				<div class="px-6 py-4 border-b border-gray-200">
					<div class="flex items-center">
						<CreditCard class="h-5 w-5 text-gray-400 mr-2" />
						<h2 class="text-lg font-medium text-gray-900">Subscription</h2>
					</div>
				</div>
				<div class="px-6 py-4">
					<div class="grid grid-cols-1 gap-6 sm:grid-cols-2">
						<div>
							<h3 class="text-sm font-medium text-gray-900">Current Plan</h3>
							<p class="mt-1 text-sm text-gray-600">{getPlanDisplayName(subscriptionData.plan)}</p>
							<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium {subscriptionData.active ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'}">
								{subscriptionData.active ? 'Active' : 'Inactive'}
							</span>
						</div>
						<div>
							<h3 class="text-sm font-medium text-gray-900">Storage Usage</h3>
							<div class="mt-2">
								<div class="flex justify-between text-sm text-gray-600">
									<span>{subscriptionData.storage_used} MB used</span>
									<span>{getStoragePercentage()}%</span>
								</div>
								<div class="mt-1 w-full bg-gray-200 rounded-full h-2">
									<div class="bg-indigo-600 h-2 rounded-full" style="width: {getStoragePercentage()}%"></div>
								</div>
							</div>
						</div>
					</div>
					
					<!-- Custom URL Section -->
					<div class="mt-6 pt-6 border-t border-gray-200">
						<div class="flex flex-col lg:flex-row lg:items-start lg:space-x-8">
							<div class="flex-1">
								<h3 class="text-md font-medium text-gray-900">Your Custom URL</h3>
								<p class="mt-1 text-sm">Share this link with your students to access your courses.</p>
								<p class="my-2 text-sm text-gray-600 font-medium border border-gray-200 py-2 px-6 rounded-md w-fit bg-gray-50">
									{#if profileData.account_slug}
									<a href={fullUrl} target="_blank" class="text-indigo-600 hover:text-indigo-500 hover:underline">{fullUrl}</a>
									{:else}
										No custom URL assigned
									{/if}
								</p>
								<!-- if plan is starter then show -->
								{#if subscriptionData.plan === 'starter'}
									<p class="mt-3 text-sm text-red-600">** Upgrade to a paid plan to customimize the URL.**</p>
								{/if}
							</div>
							
							<!-- QR Code Section -->
							{#if profileData.account_slug}
								<div class="mt-6 lg:mt-0">
									<div class="flex items-center mb-3">
										<QrCode class="h-5 w-5 text-gray-400 mr-2" />
										<h4 class="text-sm font-medium text-gray-900">QR Code</h4>
									</div>
									<p class="text-xs text-gray-500 mb-3">Scan to quickly access your page</p>
									<QRCodeComponent url={fullUrl} size={150} />
								</div>
							{/if}
						</div>
					</div>
					
					{#if subscriptionData.subscription_start}
						<div class="mt-6 pt-6 border-t border-gray-200">
							<div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
								<div>
									<h3 class="text-sm font-medium text-gray-900">Subscription Start</h3>
									<p class="mt-1 text-sm text-gray-600">{new Date(subscriptionData.subscription_start).toLocaleDateString()}</p>
								</div>
								{#if subscriptionData.subscription_end}
									<div>
										<h3 class="text-sm font-medium text-gray-900">Next Billing</h3>
										<p class="mt-1 text-sm text-gray-600">{new Date(subscriptionData.subscription_end).toLocaleDateString()}</p>
									</div>
								{/if}
							</div>
						</div>
					{/if}
				</div>
			</div>

			<!-- Notification Preferences -->
			<div class="bg-white shadow rounded-lg">
				<div class="px-6 py-4 border-b border-gray-200">
					<div class="flex items-center">
						<Bell class="h-5 w-5 text-gray-400 mr-2" />
						<h2 class="text-lg font-medium text-gray-900">Notification Preferences</h2>
					</div>
				</div>
				<div class="px-6 py-4">
					<form onsubmit={(e) => { e.preventDefault(); saveNotifications(); }} class="space-y-4">
						<div class="flex items-center justify-between">
							<div>
								<h3 class="text-sm font-medium text-gray-900">Email Notifications</h3>
								<p class="text-sm text-gray-500">Receive important updates via email</p>
							</div>
							<input
								type="checkbox"
								bind:checked={notificationPrefs.email_notifications}
								class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
							/>
						</div>
						
						<div class="flex items-center justify-between">
							<div>
								<h3 class="text-sm font-medium text-gray-900">Course Updates</h3>
								<p class="text-sm text-gray-500">Get notified when courses are updated</p>
							</div>
							<input
								type="checkbox"
								bind:checked={notificationPrefs.course_updates}
								class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
							/>
						</div>
						
						<div class="flex items-center justify-between">
							<div>
								<h3 class="text-sm font-medium text-gray-900">Payment Reminders</h3>
								<p class="text-sm text-gray-500">Receive payment and billing reminders</p>
							</div>
							<input
								type="checkbox"
								bind:checked={notificationPrefs.payment_reminders}
								class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
							/>
						</div>
						
						<div class="flex items-center justify-between">
							<div>
								<h3 class="text-sm font-medium text-gray-900">Marketing Emails</h3>
								<p class="text-sm text-gray-500">Receive promotional content and updates</p>
							</div>
							<input
								type="checkbox"
								bind:checked={notificationPrefs.marketing_emails}
								class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
							/>
						</div>

						<div class="flex justify-end pt-4">
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
								{saving ? 'Saving...' : 'Save Preferences'}
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
								<p class="text-sm text-gray-500">Update your account password</p>
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
								<p class="text-sm text-gray-500">Add an extra layer of security to your account</p>
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
