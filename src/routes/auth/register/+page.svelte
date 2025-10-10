<script lang="ts">
	import { goto } from '$app/navigation';
	import { AuthService } from '$lib/auth';
	import { Eye, EyeOff, Mail, Lock, User, Loader2 } from 'lucide-svelte';

	let firstName = $state('');
	let lastName = $state('');
	let email = $state('');
	let password = $state('');
	let confirmPassword = $state('');
	let role = $state<'student' | 'teacher'>('student');
	let showPassword = $state(false);
	let showConfirmPassword = $state(false);
	let loading = $state(false);
	let error = $state('');

	async function handleRegister() {
		if (!firstName || !lastName || !email || !password || !confirmPassword) {
			error = 'Please fill in all fields';
			return;
		}

		if (password !== confirmPassword) {
			error = 'Passwords do not match';
			return;
		}

		if (password.length < 6) {
			error = 'Password must be at least 6 characters';
			return;
		}

		loading = true;
		error = '';

		try {
			const { data, error: authError } = await AuthService.signUp(
				email, 
				password, 
				firstName, 
				lastName, 
				role
			);
			
			if (authError) {
				console.error('Registration error:', authError);
				error = authError.message || 'Registration failed. Please try again.';
			} else if (data.user) {
				// Redirect to login with success message
				goto('/auth/login?message=Registration successful! Please check your email to verify your account.');
			}
		} catch (err) {
			console.error('Registration error:', err);
			error = err instanceof Error ? err.message : 'An unexpected error occurred';
		} finally {
			loading = false;
		}
	}

	function togglePasswordVisibility() {
		showPassword = !showPassword;
	}

	function toggleConfirmPasswordVisibility() {
		showConfirmPassword = !showConfirmPassword;
	}
</script>

<div class="min-h-screen flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
	<div class="max-w-md w-full space-y-8">
		<div>
			<h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">
				Create your account
			</h2>
			<p class="mt-2 text-center text-sm text-gray-600">
				Or
				<a href="/auth/login" class="font-medium text-indigo-600 hover:text-indigo-500">
					sign in to your existing account
				</a>
			</p>
		</div>
		
		<form class="mt-8 space-y-6" onsubmit={handleRegister}>
			<div class="space-y-4">
				<div class="grid grid-cols-2 gap-4">
					<div>
						<label for="firstName" class="block text-sm font-medium text-gray-700">
							First Name
						</label>
						<div class="mt-1 relative">
							<div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
								<User class="h-5 w-5 text-gray-400" />
							</div>
							<input
								id="firstName"
								name="firstName"
								type="text"
								autocomplete="given-name"
								required
								bind:value={firstName}
								class="appearance-none rounded-md relative block w-full pl-10 pr-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm"
								placeholder="First name"
							/>
						</div>
					</div>

					<div>
						<label for="lastName" class="block text-sm font-medium text-gray-700">
							Last Name
						</label>
						<div class="mt-1 relative">
							<div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
								<User class="h-5 w-5 text-gray-400" />
							</div>
							<input
								id="lastName"
								name="lastName"
								type="text"
								autocomplete="family-name"
								required
								bind:value={lastName}
								class="appearance-none rounded-md relative block w-full pl-10 pr-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm"
								placeholder="Last name"
							/>
						</div>
					</div>
				</div>

				<div>
					<label for="email" class="block text-sm font-medium text-gray-700">
						Email address
					</label>
					<div class="mt-1 relative">
						<div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
							<Mail class="h-5 w-5 text-gray-400" />
						</div>
						<input
							id="email"
							name="email"
							type="email"
							autocomplete="email"
							required
							bind:value={email}
							class="appearance-none rounded-md relative block w-full pl-10 pr-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm"
							placeholder="Enter your email"
						/>
					</div>
				</div>

				<div>
					<label for="role" class="block text-sm font-medium text-gray-700">
						Account Type
					</label>
					<select
						id="role"
						name="role"
						bind:value={role}
						class="mt-1 block w-full pl-3 pr-10 py-2 text-base border border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
					>
						<option value="student">Student</option>
						<option value="teacher">Teacher</option>
					</select>
				</div>

				<div>
					<label for="password" class="block text-sm font-medium text-gray-700">
						Password
					</label>
					<div class="mt-1 relative">
						<div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
							<Lock class="h-5 w-5 text-gray-400" />
						</div>
						<input
							id="password"
							name="password"
							type={showPassword ? 'text' : 'password'}
							autocomplete="new-password"
							required
							bind:value={password}
							class="appearance-none rounded-md relative block w-full pl-10 pr-10 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm"
							placeholder="Create a password"
						/>
						<div class="absolute inset-y-0 right-0 pr-3 flex items-center">
							<button
								type="button"
								onclick={togglePasswordVisibility}
								class="text-gray-400 hover:text-gray-500 focus:outline-none focus:text-gray-500"
							>
								{#if showPassword}
									<EyeOff class="h-5 w-5" />
								{:else}
									<Eye class="h-5 w-5" />
								{/if}
							</button>
						</div>
					</div>
				</div>

				<div>
					<label for="confirmPassword" class="block text-sm font-medium text-gray-700">
						Confirm Password
					</label>
					<div class="mt-1 relative">
						<div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
							<Lock class="h-5 w-5 text-gray-400" />
						</div>
						<input
							id="confirmPassword"
							name="confirmPassword"
							type={showConfirmPassword ? 'text' : 'password'}
							autocomplete="new-password"
							required
							bind:value={confirmPassword}
							class="appearance-none rounded-md relative block w-full pl-10 pr-10 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm"
							placeholder="Confirm your password"
						/>
						<div class="absolute inset-y-0 right-0 pr-3 flex items-center">
							<button
								type="button"
								onclick={toggleConfirmPasswordVisibility}
								class="text-gray-400 hover:text-gray-500 focus:outline-none focus:text-gray-500"
							>
								{#if showConfirmPassword}
									<EyeOff class="h-5 w-5" />
								{:else}
									<Eye class="h-5 w-5" />
								{/if}
							</button>
						</div>
					</div>
				</div>
			</div>

			{#if error}
				<div class="rounded-md bg-red-50 p-4">
					<div class="text-sm text-red-700">{error}</div>
				</div>
			{/if}

			<div>
				<button
					type="submit"
					disabled={loading}
					class="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50 disabled:cursor-not-allowed"
				>
					{#if loading}
						<Loader2 class="h-4 w-4 animate-spin mr-2" />
					{/if}
					{loading ? 'Creating account...' : 'Create account'}
				</button>
			</div>
		</form>
	</div>
</div>
