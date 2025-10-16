<script lang="ts">
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { AuthService } from '$lib/auth';
	import { slide } from 'svelte/transition';
	import { 
		LogOut, User, Settings, Bell, Home, Book, BookOpen, Users, 
		Mail, BarChart, User as UserIcon, Menu, X, FileText
	} from 'lucide-svelte';
	import type { LayoutData } from './$types';

	let { data, children }: { data: LayoutData; children: any } = $props();

	let mobileMenuOpen = $state(false);
	let expandedItems = $state(new Set());

	// Simple function to check if Students should be expanded
	function isStudentsExpanded() {
		return data.profile.role === 'teacher' && $page.url.pathname.startsWith('/dashboard/teacher/students');
	}

	async function handleLogout() {
		try {
			console.log('Starting sign out process...');
			
			// Sign out from Supabase
			const { error } = await AuthService.signOut();
			if (error) {
				console.error('Sign out error:', error);
			} else {
				console.log('Sign out successful');
			}
			
			// Clear any local storage
			localStorage.clear();
			sessionStorage.clear();
			
			// Redirect to logout endpoint which will handle server-side cleanup
			window.location.href = '/auth/logout';
		} catch (error) {
			console.error('Sign out error:', error);
			// Force redirect even if there's an error
			window.location.href = '/auth/logout';
		}
	}

	function getNavigationItems(role: string) {
		switch (role) {
			case 'student':
				return [
					{ name: 'My Courses', href: '/dashboard/student', icon: Book },
					{ name: 'Messages', href: '/dashboard/student/messages', icon: Mail },
					{ name: 'Settings', href: '/dashboard/student/settings', icon: Settings }
				];
			case 'teacher':
				return [
					{ name: 'Dashboard', href: '/dashboard/teacher', icon: Home },
					{ name: 'Courses', href: '/dashboard/teacher/courses', icon: Book },
					{ name: 'Lessons', href: '/dashboard/teacher/lessons', icon: BookOpen },
					{ 
						name: 'Students', 
						href: '/dashboard/teacher/students', 
						icon: Users,
						subItems: [
							{ name: 'Custom Fields', href: '/dashboard/teacher/students/fields', icon: FileText }
						]
					},
					{ name: 'Messages', href: '/dashboard/teacher/messages', icon: Mail },
					{ name: 'Analytics', href: '/dashboard/teacher/analytics', icon: BarChart },
					{ name: 'Settings', href: '/dashboard/teacher/settings', icon: Settings }
				];
			case 'super_admin':
				return [
					{ name: 'Overview', href: '/dashboard/admin', icon: Home },
					{ name: 'Teachers', href: '/dashboard/admin/teachers', icon: Users },
					{ name: 'Students', href: '/dashboard/admin/students', icon: UserIcon },
					{ name: 'Analytics', href: '/dashboard/admin/analytics', icon: BarChart },
					{ name: 'Settings', href: '/dashboard/admin/settings', icon: Settings }
				];
			default:
				return [];
		}
	}

	function toggleMobileMenu() {
		mobileMenuOpen = !mobileMenuOpen;
	}

	function closeMobileMenu() {
		mobileMenuOpen = false;
	}

	function toggleExpanded(itemName: string) {
		if (expandedItems.has(itemName)) {
			expandedItems.delete(itemName);
		} else {
			expandedItems.add(itemName);
		}
		expandedItems = expandedItems; // trigger reactivity
	}

	function handleItemClick(item: any) {
		// Navigate to the main item's href
		goto(item.href);
		// Only toggle if not Students (Students auto-expands based on path)
		if (item.name !== 'Students') {
			toggleExpanded(item.name);
		}
	}

	function isItemActive(item: any): boolean {
		if ($page.url.pathname === item.href) return true;
		if (item.subItems) {
			return item.subItems.some((subItem: any) => $page.url.pathname === subItem.href);
		}
		return false;
	}

	const navigationItems = getNavigationItems(data.profile.role);
</script>

<div class="min-h-screen bg-gray-50">
	<!-- Mobile Header -->
	<div class="lg:hidden bg-white shadow-sm border-b border-gray-200 px-4 py-3 sticky top-0 z-40">
		<div class="flex items-center justify-between">
			<button
				onclick={toggleMobileMenu}
				class="p-2 rounded-md text-gray-400 hover:text-gray-500 hover:bg-gray-100"
				aria-label="Toggle mobile menu"
			>
				{#if mobileMenuOpen}
					<X class="h-6 w-6" />
				{:else}
					<Menu class="h-6 w-6" />
				{/if}
			</button>
			
			<div class="flex items-center space-x-2">
				<div class="h-8 w-8 rounded-full bg-indigo-500 flex items-center justify-center">
					<User class="h-5 w-5 text-white" />
				</div>
				<div class="text-sm">
					<p class="font-medium text-gray-700">
						{data.profile.first_name} {data.profile.last_name}
					</p>
					<p class="text-xs text-gray-500 capitalize">{data.profile.role.replace('_', ' ')}</p>
				</div>
			</div>
			
			<div class="flex items-center space-x-2">
				<!-- Notifications -->
				<button class="p-2 text-gray-400 hover:text-gray-500">
					<Bell class="h-5 w-5" />
				</button>
			</div>
		</div>
	</div>

	<div class="flex">
		<!-- Desktop Sidebar -->
		<div class="hidden lg:flex lg:flex-shrink-0">
			<div class="w-64 bg-white shadow-lg">
				<div class="flex flex-col h-screen">
					<!-- Header with user info -->
					<div class="flex items-center h-16 px-4 border-b border-gray-200 flex-shrink-0">
						<div class="flex items-center text-sm flex-1">
							<div class="h-8 w-8 rounded-full bg-indigo-500 flex items-center justify-center flex-shrink-0">
								<User class="h-5 w-5 text-white" />
							</div>
							<div class="ml-3">
								<p class="text-sm font-medium text-gray-700 truncate">
									{data.profile.first_name} {data.profile.last_name}
								</p>
								<p class="text-xs text-gray-500 capitalize">{data.profile.role.replace('_', ' ')}</p>
							</div>
						</div>
					</div>

					<!-- Navigation -->
					<nav class="px-4 py-4 space-y-2 overflow-hidden" style="height: calc(100vh - 8rem);">
						{#each navigationItems as item}
							{@const IconComponent = item.icon}
							{@const isActive = isItemActive(item)}
							{@const isExpanded = item.name === 'Students' ? isStudentsExpanded() : expandedItems.has(item.name)}
							{@const hasSubItems = item.subItems && item.subItems.length > 0}
							
							<div class="space-y-1">
								<!-- Main item -->
												{#if hasSubItems}
													<button
														onclick={() => handleItemClick(item)}
														class="flex items-center w-full px-3 py-2 text-sm font-medium rounded-md transition-colors duration-200 {isActive ? 'bg-indigo-100 text-indigo-700' : 'text-gray-600 hover:bg-gray-100 hover:text-gray-900'}"
													>
										<IconComponent class="h-5 w-5 mr-3" />
										<span class="flex-1 text-left">{item.name}</span>
										<span class="text-xs {isExpanded ? 'rotate-180' : ''} transition-transform duration-200">▼</span>
									</button>
								{:else}
									<a
										href={item.href}
										class="flex items-center px-3 py-2 text-sm font-medium rounded-md transition-colors duration-200 {isActive ? 'bg-indigo-100 text-indigo-700' : 'text-gray-600 hover:bg-gray-100 hover:text-gray-900'}"
									>
										<IconComponent class="h-5 w-5 mr-3" />
										<span>{item.name}</span>
									</a>
								{/if}
								
								<!-- Sub items -->
								{#if hasSubItems && isExpanded}
									<div class="ml-6 space-y-1">
										{#each item.subItems as subItem}
											{@const SubIconComponent = subItem.icon}
											<a
												href={subItem.href}
												class="flex items-center px-3 py-2 text-sm font-medium rounded-md transition-colors duration-200 {$page.url.pathname === subItem.href ? 'bg-indigo-50 text-indigo-600' : 'text-gray-500 hover:bg-gray-50 hover:text-gray-700'}"
											>
												<SubIconComponent class="h-4 w-4 mr-3" />
												<span>{subItem.name}</span>
											</a>
										{/each}
									</div>
								{/if}
							</div>
						{/each}
					</nav>
					
					<!-- Logout section - fixed at bottom -->
					<div class="px-4 pb-4" style="height: 4rem;">
						<!-- Divider line -->
						<div class="border-t border-gray-200 mb-2"></div>
						
						<!-- Logout button -->
						<button
							onclick={handleLogout}
							class="flex items-center w-full px-3 py-2 text-sm font-medium text-gray-600 hover:bg-gray-100 hover:text-gray-900 rounded-md transition-colors duration-200"
						>
							<LogOut class="h-5 w-5 mr-3" />
							<span>Sign out</span>
						</button>
					</div>
				</div>
			</div>
		</div>

		<!-- Mobile Sidebar Overlay -->
		{#if mobileMenuOpen}
			<div class="fixed inset-0 z-50 lg:hidden">
				<!-- Backdrop -->
				<div 
					class="fixed inset-0 bg-gray-600 bg-opacity-75 transition-opacity duration-300 ease-in-out"
					onclick={closeMobileMenu}
				></div>
				
				<!-- Sidebar -->
				<div 
					class="relative flex-1 flex flex-col max-w-xs w-full bg-white"
					in:slide={{ duration: 300, axis: 'x' }}
					out:slide={{ duration: 300, axis: 'x' }}
				>
					<div class="flex flex-col h-full">
					<!-- Header -->
					<div class="flex items-center justify-between h-16 px-4 border-b border-gray-200 flex-shrink-0">
						<div class="flex items-center text-sm flex-1">
							<div class="h-8 w-8 rounded-full bg-indigo-500 flex items-center justify-center flex-shrink-0">
								<User class="h-5 w-5 text-white" />
							</div>
							<div class="ml-3">
								<p class="text-sm font-medium text-gray-700 truncate">
									{data.profile.first_name} {data.profile.last_name}
								</p>
								<p class="text-xs text-gray-500 capitalize">{data.profile.role.replace('_', ' ')}</p>
							</div>
						</div>
						<button
							onclick={closeMobileMenu}
							class="p-2 rounded-md text-gray-400 hover:text-gray-500 hover:bg-gray-100"
						>
							<X class="h-5 w-5" />
						</button>
					</div>

					<!-- Navigation -->
					<nav class="px-4 py-4 space-y-2 overflow-hidden" style="height: calc(100vh - 8rem);">
						{#each navigationItems as item}
							{@const IconComponent = item.icon}
							{@const isActive = isItemActive(item)}
							{@const isExpanded = item.name === 'Students' ? isStudentsExpanded() : expandedItems.has(item.name)}
							{@const hasSubItems = item.subItems && item.subItems.length > 0}
							
							<div class="space-y-1">
								<!-- Main item -->
												{#if hasSubItems}
													<button
														onclick={() => handleItemClick(item)}
														class="flex items-center w-full px-3 py-2 text-sm font-medium rounded-md transition-colors duration-200 {isActive ? 'bg-indigo-100 text-indigo-700' : 'text-gray-600 hover:bg-gray-100 hover:text-gray-900'}"
													>
										<IconComponent class="h-5 w-5 mr-3" />
										<span class="flex-1 text-left">{item.name}</span>
										<span class="text-xs {isExpanded ? 'rotate-180' : ''} transition-transform duration-200">▼</span>
									</button>
								{:else}
									<a
										href={item.href}
										onclick={closeMobileMenu}
										class="flex items-center px-3 py-2 text-sm font-medium rounded-md transition-colors duration-200 {isActive ? 'bg-indigo-100 text-indigo-700' : 'text-gray-600 hover:bg-gray-100 hover:text-gray-900'}"
									>
										<IconComponent class="h-5 w-5 mr-3" />
										<span>{item.name}</span>
									</a>
								{/if}
								
								<!-- Sub items -->
								{#if hasSubItems && isExpanded}
									<div class="ml-6 space-y-1">
										{#each item.subItems as subItem}
											{@const SubIconComponent = subItem.icon}
											<a
												href={subItem.href}
												onclick={closeMobileMenu}
												class="flex items-center px-3 py-2 text-sm font-medium rounded-md transition-colors duration-200 {$page.url.pathname === subItem.href ? 'bg-indigo-50 text-indigo-600' : 'text-gray-500 hover:bg-gray-50 hover:text-gray-700'}"
											>
												<SubIconComponent class="h-4 w-4 mr-3" />
												<span>{subItem.name}</span>
											</a>
										{/each}
									</div>
								{/if}
							</div>
						{/each}
					</nav>
					
					<!-- Logout section - fixed at bottom -->
					<div class="px-4 pb-4" style="height: 4rem;">
						<!-- Divider line -->
						<div class="border-t border-gray-200 mb-2"></div>
						
						<!-- Logout button -->
						<button
							onclick={handleLogout}
							class="flex items-center w-full px-3 py-2 text-sm font-medium text-gray-600 hover:bg-gray-100 hover:text-gray-900 rounded-md transition-colors duration-200"
						>
							<LogOut class="h-5 w-5 mr-3" />
							<span>Sign out</span>
						</button>
					</div>
				</div>
				</div>
			</div>
		{/if}

		<!-- Main content area -->
		<div class="flex-1 flex flex-col lg:ml-0">
			<!-- Page content -->
			<main class="flex-1 px-4 sm:px-6 lg:px-8 py-6">
				{@render children()}
			</main>
		</div>
	</div>
</div>

