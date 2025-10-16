<script lang="ts">
    import { onMount } from 'svelte';
    import { supabase } from '$lib/supabase';
    import type { PageData } from './$types';
    import { Plus, Trash2, Edit } from 'lucide-svelte';

    let { data }: { data: PageData } = $props();
    let loading = $state(true);
    let fieldSets = $state<any[]>([]);
    let setForm = $state({ name: '', description: '' });
    let editingSetId = $state<string | null>(null);
    let editForm = $state({ name: '', description: '' });
    let showCreateModal = $state(false);

    onMount(async () => {
        await refreshSets();
    });

    async function refreshSets() {
        try {
            loading = true;
            const fd = new FormData();
            const res = await fetch('?/list_sets', { 
                method: 'POST', 
                body: fd
            });
            
            const text = await res.text();
            const svelteResponse = JSON.parse(text);
            
            // SvelteKit action responses are wrapped in {type, status, data}
            if (svelteResponse.type === 'success' && svelteResponse.data) {
                const actionResult = JSON.parse(svelteResponse.data);
                
                // The result is an array, first element contains the actual response
                const result = actionResult[0];
                if (result && result.success) {
                    // The field sets data is in the array elements after the first one
                    // Skip the first 3 elements: [0] = result, [1] = true, [2] = count array
                    const fieldSetsData = actionResult.slice(3);
                    
                    // The schema is the first element of the field sets data
                    const schema = fieldSetsData[0];
                    const fieldSetsArray = [];
                    
                    // The actual data starts from index 1 (after the schema)
                    const actualData = fieldSetsData.slice(1);
                    
                    // The data comes in chunks of 6 values per field set (id, teacher_id, name, description, active, created_at)
                    const fieldsPerSet = Object.keys(schema).length;
                    
                    for (let i = 0; i < actualData.length; i += fieldsPerSet) {
                        const fieldSet = {};
                        Object.keys(schema).forEach((key, index) => {
                            fieldSet[key] = actualData[i + index];
                        });
                        fieldSetsArray.push(fieldSet);
                    }
                    
                    fieldSets = fieldSetsArray;
                } else {
                    console.error('Error loading field sets:', result?.error || 'Unknown error');
                }
            } else {
                console.error('SvelteKit action failed:', svelteResponse);
            }
        } catch (error) {
            console.error('Refresh sets error:', error);
        } finally {
            loading = false;
        }
    }

    async function createFieldSet() {}

    function startEdit(set: any) {
        editingSetId = set.id;
        editForm = { name: set.name, description: set.description || '' };
    }

    async function saveEdit() {
        if (!editingSetId) return;
        const fd = new FormData();
        fd.append('id', editingSetId);
        fd.append('name', editForm.name.trim());
        fd.append('description', editForm.description.trim());
        const res = await fetch('?/update_set', { method: 'POST', body: fd });
        const json = await res.json().catch(() => null);
        if (json?.success) {
            editingSetId = null;
            await refreshSets();
        } else {
            console.error('Update set error:', json?.error || 'Unknown error');
        }
    }

    async function deleteSet(id: string) {
        if (!confirm('Delete this field set?')) return;
        const fd = new FormData();
        fd.append('id', id);
        const res = await fetch('?/delete_set', { method: 'POST', body: fd });
        const json = await res.json().catch(() => null);
        if (json?.success) {
            await refreshSets();
        } else {
            console.error('Delete set error:', json?.error || 'Unknown error');
        }
    }
</script>

<div class="px-4 sm:px-6 lg:px-8 py-8">
    <div class="mb-8">
        <div class="flex items-center justify-between">
            <div>
                <h1 class="text-3xl font-bold text-gray-900">Student Field Sets</h1>
                <p class="mt-2 text-gray-600">Create and manage custom field sets for your courses.</p>
            </div>
            <button onclick={() => (showCreateModal = true)} class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700">
                <Plus class="h-4 w-4 mr-2" /> New set
            </button>
        </div>
    </div>

    {#if loading}
        <div class="flex justify-center py-12">
            <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
        </div>
    {:else if fieldSets.length === 0}
        <div class="text-center py-12">
            <p class="mt-2 text-sm text-gray-500">No field sets yet. Create your first one above.</p>
        </div>
    {:else}
        <div class="bg-white shadow overflow-hidden sm:rounded-md">
            <ul class="divide-y divide-gray-200">
                {#each fieldSets as set}
                    <li class="px-6 py-4">
                        {#if editingSetId === set.id}
                            <div class="grid grid-cols-1 md:grid-cols-3 gap-3 items-end">
                                <input bind:value={editForm.name} class="border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
                                <input bind:value={editForm.description} class="md:col-span-2 border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
                                <div class="md:col-span-3 flex gap-2">
                                    <form method="POST" action="?/update_set" onsubmit={async (e) => { e.preventDefault(); const form = e.currentTarget as HTMLFormElement; const fd = new FormData(form); fd.append('id', editingSetId as string); const res = await fetch(form.action, { method: 'POST', body: fd }); const json = await res.json().catch(() => null); if (json?.success) { editingSetId = null; await refreshSets(); } else { alert(json?.error || 'Update failed'); } }}>
                                        <input type="hidden" name="name" value={editForm.name} />
                                        <input type="hidden" name="description" value={editForm.description} />
                                        <button type="submit" class="px-3 py-2 bg-indigo-600 text-white rounded">Save</button>
                                    </form>
                                    <button class="px-3 py-2 border rounded" onclick={() => (editingSetId = null)}>Cancel</button>
                                </div>
                            </div>
                        {:else}
                            <div class="flex items-center justify-between">
                                <div>
                                    <div class="set-name text-sm font-medium text-gray-900">{set.name}</div>
                                </div>
                                <div class="flex gap-3">
                                    <a href="/dashboard/teacher/students/fields/{set.id}" class="text-blue-600 hover:text-blue-900 text-sm">Manage Fields</a>
                                    <button class="text-indigo-600 hover:text-indigo-900" onclick={() => startEdit(set)}><Edit class="h-4 w-4" /></button>
                                    <form method="POST" action="?/delete_set" onsubmit={async (e) => { e.preventDefault(); if (!confirm('Delete this field set?')) return; const form = e.currentTarget as HTMLFormElement; const fd = new FormData(form); fd.append('id', set.id); const res = await fetch(form.action, { method: 'POST', body: fd }); const json = await res.json().catch(() => null); if (json?.success) { await refreshSets(); } else { alert(json?.error || 'Delete failed'); } }}>
                                        <button type="submit" class="text-red-600 hover:text-red-900"><Trash2 class="h-4 w-4" /></button>
                                    </form>
                                </div>
                            </div>
                        {/if}
                    </li>
                {/each}
            </ul>
        </div>
    {/if}
</div>

{#if showCreateModal}
    <div class="fixed inset-0 z-50 overflow-y-auto">
        <div class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
            <button type="button" class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" aria-label="Close" onclick={() => (showCreateModal = false)}></button>

            <div class="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full">
                <form method="POST" action="?/create_set" onsubmit={async (e) => { e.preventDefault(); const form = e.currentTarget as HTMLFormElement; const fd = new FormData(form); const res = await fetch(form.action, { method: 'POST', body: fd }); const json = await res.json().catch(() => null); if (json?.success) { setForm = { name: '', description: '' }; showCreateModal = false; await refreshSets(); } else { alert(json?.error || 'Create failed'); } }}>
                    <div class="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
                        <div class="sm:flex sm:items-start">
                            <div class="w-full">
                                <h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">Create Field Set</h3>
                                <div class="space-y-4">
                                    <div>
                                        <label for="modal_name" class="block text-sm font-medium text-gray-700">Set name</label>
                                        <input id="modal_name" name="name" bind:value={setForm.name} required class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
                                    </div>
                                    <div>
                                        <label for="modal_description" class="block text-sm font-medium text-gray-700">Description</label>
                                        <input id="modal_description" name="description" bind:value={setForm.description} class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
                        <button type="submit" class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-indigo-600 text-base font-medium text-white hover:bg-indigo-700 focus:outline-none sm:ml-3 sm:w-auto sm:text-sm">Create</button>
                        <button type="button" onclick={() => (showCreateModal = false)} class="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm">Cancel</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
{/if}


