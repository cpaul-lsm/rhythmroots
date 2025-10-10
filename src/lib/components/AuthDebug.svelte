<script lang="ts">
	import { onMount } from 'svelte';
	import { AuthService } from '../auth';

	let user = $state(null);
	let profile = $state(null);
	let loading = $state(true);

	onMount(async () => {
		const { user: currentUser, profile: currentProfile } = await AuthService.getCurrentUser();
		user = currentUser;
		profile = currentProfile;
		loading = false;
	});
</script>

{#if !loading}
	<div class="fixed top-4 right-4 bg-white p-4 border rounded-lg shadow-lg text-xs max-w-sm">
		<h3 class="font-bold mb-2">Auth Debug</h3>
		<div class="space-y-1">
			<div><strong>User:</strong> {user ? 'Logged in' : 'Not logged in'}</div>
			<div><strong>Profile:</strong> {profile ? 'Found' : 'Not found'}</div>
			{#if profile}
				<div><strong>Role:</strong> {profile.role}</div>
				<div><strong>Name:</strong> {profile.first_name} {profile.last_name}</div>
			{/if}
		</div>
	</div>
{/if}
