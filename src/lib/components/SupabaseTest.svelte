<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase, AuthUtils } from '../index';

	let user: any = null;
	let loading = true;
	let error: string | null = null;

	onMount(async () => {
		try {
			// Get current user
			const { user: currentUser, error: userError } = await AuthUtils.getCurrentUser();
			
			if (userError) {
				error = userError.message;
			} else {
				user = currentUser;
			}
		} catch (err) {
			error = 'Failed to connect to Supabase';
			console.error('Supabase connection error:', err);
		} finally {
			loading = false;
		}
	});

	async function testConnection() {
		loading = true;
		error = null;
		
		try {
			// Test the connection by getting the current user
			const { user: currentUser, error: userError } = await AuthUtils.getCurrentUser();
			
			if (userError) {
				error = userError.message;
			} else {
				user = currentUser;
				console.log('Supabase connection successful!', currentUser);
			}
		} catch (err) {
			error = 'Connection test failed';
			console.error('Connection test error:', err);
		} finally {
			loading = false;
		}
	}
</script>

<div class="p-6 max-w-md mx-auto bg-white rounded-xl shadow-lg space-y-4">
	<h2 class="text-2xl font-bold text-gray-900">Supabase Connection Test</h2>
	
	{#if loading}
		<div class="flex items-center justify-center">
			<div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
			<span class="ml-2">Testing connection...</span>
		</div>
	{:else if error}
		<div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded">
			<strong>Error:</strong> {error}
		</div>
		<button 
			onclick={testConnection}
			class="w-full bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
		>
			Retry Connection
		</button>
	{:else if user}
		<div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded">
			<strong>Success!</strong> Connected to Supabase
		</div>
		<div class="text-sm text-gray-600">
			<p><strong>User ID:</strong> {user.id}</p>
			<p><strong>Email:</strong> {user.email}</p>
		</div>
	{:else}
		<div class="bg-yellow-100 border border-yellow-400 text-yellow-700 px-4 py-3 rounded">
			<strong>Connected</strong> but no user is signed in
		</div>
		<button 
			onclick={testConnection}
			class="w-full bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
		>
			Test Connection Again
		</button>
	{/if}
</div>
