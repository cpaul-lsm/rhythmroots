<script lang="ts">
    import { onMount } from 'svelte';
    import { Plus, Trash2, Edit, ArrowLeft } from 'lucide-svelte';
    import type { PageData } from './$types';

    let { data }: { data: PageData } = $props();
    let loading = $state(true);
    let fields = $state<any[]>([]);
    let fieldForm = $state({ 
        name: '', 
        type: 'text', 
        required: false, 
        options: '' 
    });
    let editingFieldId = $state<string | null>(null);
    let editForm = $state({ 
        name: '', 
        type: 'text', 
        required: false, 
        options: '' 
    });
    let showCreateModal = $state(false);

    onMount(async () => {
        // Use the fields already loaded from the server
        fields = data.fields || [];
        loading = false;
    });

    async function refreshFields() {
        try {
            loading = true;
            // Reload the page to get fresh data
            window.location.reload();
        } catch (error) {
            console.error('Refresh fields error:', error);
            loading = false;
        }
    }

    function startEdit(field: any) {
        editingFieldId = field.id;
        editForm = { 
            name: field.label, 
            type: field.type, 
            required: field.required, 
            options: field.options ? field.options.join('\n') : '' 
        };
    }

    async function saveEdit() {
        if (!editingFieldId) return;
        const fd = new FormData();
        fd.append('field_id', editingFieldId);
        fd.append('name', editForm.name.trim());
        fd.append('type', editForm.type);
        fd.append('required', editForm.required ? 'on' : '');
        fd.append('options', editForm.options.trim());
        
        const res = await fetch('?/update_field', { method: 'POST', body: fd });
        const json = await res.json().catch(() => null);
        if (json?.success) {
            editingFieldId = null;
            await refreshFields();
        } else {
            alert(json?.error || 'Update failed');
        }
    }

    async function deleteField(id: string) {
        if (!confirm('Delete this field?')) return;
        console.log('Attempting to delete field with ID:', id);
        const fd = new FormData();
        fd.append('field_id', id);
        const res = await fetch('?/delete_field', { method: 'POST', body: fd });
        const text = await res.text();
        console.log('Delete field response:', text);
        const json = JSON.parse(text);
        const actionResult = JSON.parse(json.data);
        console.log('Delete field result:', actionResult);
        if (actionResult[0]?.success) {
            await refreshFields();
        } else {
            alert(actionResult[0]?.error || 'Delete failed');
        }
    }

    function getFieldTypeLabel(type: string) {
        const labels = {
            text: 'Text',
            number: 'Number',
            boolean: 'Yes/No',
            date: 'Date',
            select: 'Single Select',
            multiselect: 'Multiple Select'
        };
        return labels[type] || type;
    }
</script>

<div class="px-4 sm:px-6 lg:px-8 py-8">
    <div class="mb-8">
        <div class="flex items-center justify-between">
            <div>
                <div class="flex items-center gap-3 mb-2">
                    <a href="/dashboard/teacher/students/fields" class="text-gray-500 hover:text-gray-700">
                        <ArrowLeft class="h-5 w-5" />
                    </a>
                    <h1 class="text-3xl font-bold text-gray-900">Fields for "{data.fieldSet.name}"</h1>
                </div>
                <p class="text-gray-600">{data.fieldSet.description || 'Manage custom fields for this field set.'}</p>
            </div>
            <button onclick={() => (showCreateModal = true)} class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700">
                <Plus class="h-4 w-4 mr-2" /> New Field
            </button>
        </div>
    </div>

    {#if loading}
        <div class="flex justify-center py-12">
            <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
        </div>
    {:else if fields.length === 0}
        <div class="text-center py-12">
            <p class="mt-2 text-sm text-gray-500">No fields yet. Create your first one above.</p>
        </div>
    {:else}
        <div class="bg-white shadow overflow-hidden sm:rounded-md">
            <ul class="divide-y divide-gray-200">
                {#each fields as field}
                    <li class="px-6 py-4">
                        {#if editingFieldId === field.id}
                            <div class="space-y-4">
                                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                                    <div>
                                        <label class="block text-sm font-medium text-gray-700">Field Name</label>
                                        <input bind:value={editForm.name} class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
                                    </div>
                                    <div>
                                        <label class="block text-sm font-medium text-gray-700">Field Type</label>
                                        <select bind:value={editForm.type} class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm">
                                            <option value="text">Text</option>
                                            <option value="number">Number</option>
                                            <option value="boolean">Yes/No</option>
                                            <option value="date">Date</option>
                                            <option value="select">Single Select</option>
                                            <option value="multiselect">Multiple Select</option>
                                        </select>
                                    </div>
                                </div>
                                
                                {#if editForm.type === 'select' || editForm.type === 'multiselect'}
                                    <div>
                                        <label class="block text-sm font-medium text-gray-700">Options (one per line)</label>
                                        <textarea bind:value={editForm.options} rows="3" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"></textarea>
                                    </div>
                                {/if}
                                
                                <div class="flex items-center">
                                    <input type="checkbox" bind:checked={editForm.required} class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded">
                                    <label class="ml-2 block text-sm text-gray-900">Required field</label>
                                </div>
                                
                                <div class="flex gap-2">
                                    <button onclick={saveEdit} class="px-3 py-2 bg-indigo-600 text-white rounded">Save</button>
                                    <button onclick={() => (editingFieldId = null)} class="px-3 py-2 border rounded">Cancel</button>
                                </div>
                            </div>
                        {:else}
                            <div class="flex items-center justify-between">
                                <div>
                                    <div class="text-sm font-medium text-gray-900">{field.label}</div>
                                    <div class="text-sm text-gray-500">
                                        {getFieldTypeLabel(field.type)}
                                        {#if field.required} • Required{/if}
                                        {#if field.options && field.options.length > 0}
                                            • {field.options.length} option{field.options.length === 1 ? '' : 's'}
                                        {/if}
                                    </div>
                                </div>
                                <div class="flex gap-3">
                                    <button class="text-indigo-600 hover:text-indigo-900" onclick={() => startEdit(field)}><Edit class="h-4 w-4" /></button>
                                    <button class="text-red-600 hover:text-red-900" onclick={() => deleteField(field.id)}><Trash2 class="h-4 w-4" /></button>
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
                <form method="POST" action="?/create_field" onsubmit={async (e) => { e.preventDefault(); const form = e.currentTarget as HTMLFormElement; const fd = new FormData(form); const res = await fetch(form.action, { method: 'POST', body: fd }); const text = await res.text(); console.log('Create field response:', text); const json = JSON.parse(text); const actionResult = JSON.parse(json.data); console.log('Create field result:', actionResult); if (actionResult[0]?.success) { fieldForm = { name: '', type: 'text', required: false, options: '' }; showCreateModal = false; await refreshFields(); } else { alert(actionResult[0]?.error || 'Create failed'); } }}>
                    <div class="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
                        <div class="sm:flex sm:items-start">
                            <div class="w-full">
                                <h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">Create Field</h3>
                                <div class="space-y-4">
                                    <div>
                                        <label for="modal_field_name" class="block text-sm font-medium text-gray-700">Field Name</label>
                                        <input id="modal_field_name" name="name" bind:value={fieldForm.name} required class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
                                    </div>
                                    <div>
                                        <label for="modal_field_type" class="block text-sm font-medium text-gray-700">Field Type</label>
                                        <select id="modal_field_type" name="type" bind:value={fieldForm.type} class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm">
                                            <option value="text">Text</option>
                                            <option value="number">Number</option>
                                            <option value="boolean">Yes/No</option>
                                            <option value="date">Date</option>
                                            <option value="select">Single Select</option>
                                            <option value="multiselect">Multiple Select</option>
                                        </select>
                                    </div>
                                    
                                    {#if fieldForm.type === 'select' || fieldForm.type === 'multiselect'}
                                        <div>
                                            <label for="modal_field_options" class="block text-sm font-medium text-gray-700">Options (one per line)</label>
                                            <textarea id="modal_field_options" name="options" bind:value={fieldForm.options} rows="3" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"></textarea>
                                        </div>
                                    {/if}
                                    
                                    <div class="flex items-center">
                                        <input type="checkbox" name="required" bind:checked={fieldForm.required} class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded">
                                        <label class="ml-2 block text-sm text-gray-900">Required field</label>
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
