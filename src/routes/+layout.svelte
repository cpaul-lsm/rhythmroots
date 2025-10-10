<script lang="ts">
	import { page } from '$app/stores';
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { AuthService } from '$lib/auth';
	import type { LayoutData } from './$types';
	import '../app.css';

	let { data, children }: { data: LayoutData; children: any } = $props();

	let user = $state(data.user);
	let profile = $state(data.profile);
	let subscriptionStatus = $state(data.subscriptionStatus);

	onMount(() => {
		// Listen for auth state changes
		const { data: { subscription } } = AuthService.onAuthStateChange(async (event, session) => {
			if (event === 'SIGNED_IN' && session?.user) {
				const { user: newUser, profile: newProfile } = await AuthService.getCurrentUser();
				user = newUser;
				profile = newProfile;
				subscriptionStatus = newProfile ? AuthService.getSubscriptionStatus(newProfile) : null;
			} else if (event === 'SIGNED_OUT') {
				user = null;
				profile = null;
				subscriptionStatus = null;
			}
		});

		return () => subscription?.unsubscribe();
	});
</script>

<main class="min-h-screen bg-gray-50">
	{@render children()}
</main>
