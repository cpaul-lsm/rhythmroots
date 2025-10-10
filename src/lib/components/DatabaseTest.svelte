<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '../supabase';

	let connectionStatus = $state('Testing...');
	let error = $state('');
	let testResults = $state<any[]>([]);

	onMount(async () => {
		await testDatabaseConnection();
	});

	async function testDatabaseConnection() {
		try {
			// Test 1: Check if we can connect to Supabase
			const { data: { user }, error: authError } = await supabase.auth.getUser();
			connectionStatus = 'Connected to Supabase';
			
			// Test 2: Try a simple count query with timeout
			const timeoutPromise = new Promise((_, reject) => 
				setTimeout(() => reject(new Error('Query timeout after 5 seconds')), 5000)
			);
			
			const queryPromise = supabase
				.from('profiles')
				.select('count', { count: 'exact' });

			const { data: profiles, error: profilesError } = await Promise.race([
				queryPromise,
				timeoutPromise
			]) as any;

			if (profilesError) {
				error = `Profiles table error: ${profilesError.message}`;
				connectionStatus = 'Error accessing profiles table';
			} else {
				connectionStatus = `Database connection successful - Found ${profiles?.length || 0} profiles`;
				testResults = [];
			}

		} catch (err) {
			error = `Connection failed: ${err instanceof Error ? err.message : 'Unknown error'}`;
			connectionStatus = 'Connection failed';
		}
	}

	async function testUserRegistration() {
		try {
			const testEmail = `test-${Date.now()}@example.com`;
			const { data, error: signUpError } = await supabase.auth.signUp({
				email: testEmail,
				password: 'testpassword123',
				options: {
					data: {
						first_name: 'Test',
						last_name: 'User',
						role: 'teacher'
					}
				}
			});

			if (signUpError) {
				error = `Registration test failed: ${signUpError.message}`;
			} else {
				connectionStatus = 'Registration test successful! Check profiles table.';
				// Clean up test user
				if (data.user) {
					await supabase.auth.admin.deleteUser(data.user.id);
				}
			}
		} catch (err) {
			error = `Registration test error: ${err instanceof Error ? err.message : 'Unknown error'}`;
		}
	}
</script>

<div class="p-6 max-w-2xl mx-auto bg-white rounded-xl shadow-lg space-y-4">
	<h2 class="text-2xl font-bold text-gray-900">Database Connection Test</h2>
	
	<div class="space-y-4">
		<div class="p-4 border rounded-lg">
			<h3 class="font-semibold text-gray-900">Connection Status</h3>
			<p class="text-sm text-gray-600">{connectionStatus}</p>
		</div>

		{#if error}
			<div class="p-4 bg-red-100 border border-red-400 text-red-700 rounded">
				<strong>Error:</strong> {error}
			</div>
		{/if}

		{#if testResults.length > 0}
			<div class="p-4 border rounded-lg">
				<h3 class="font-semibold text-gray-900 mb-2">Sample Profiles (last 5)</h3>
				<div class="space-y-2">
					{#each testResults as profile}
						<div class="text-sm">
							<span class="font-medium">{profile.first_name} {profile.last_name}</span>
							<span class="text-gray-500">({profile.role})</span>
						</div>
					{/each}
				</div>
			</div>
		{/if}

		<div class="flex space-x-4">
			<button
				onclick={testDatabaseConnection}
				class="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
			>
				Test Connection
			</button>
			<button
				onclick={testUserRegistration}
				class="px-4 py-2 bg-green-500 text-white rounded hover:bg-green-600"
			>
				Test Registration
			</button>
		</div>
	</div>
</div>
