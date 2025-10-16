<script lang="ts">
    import { onMount } from 'svelte';
    import { Plus, Trash2, Edit, ArrowLeft, GripVertical, Eye, EyeOff, Type, Hash, Calendar, CheckSquare, List, FileText, Heading, Copy, Mail, Phone } from 'lucide-svelte';
    import type { PageData } from './$types';

    let { data }: { data: PageData } = $props();
    let loading = $state(true);
    let fields = $state<any[]>([]);
    let fieldForm = $state({ 
        name: '', 
        type: 'text', 
        required: false, 
        options: '',
        half_width: false
    });
    let editingFieldId = $state<string | null>(null);
    let editForm = $state({ 
        name: '', 
        type: 'text', 
        required: false, 
        options: '',
        half_width: false
    });
    let showCreateModal = $state(false);
    let draggedFieldId = $state<string | null>(null);
    let draggedOverFieldId = $state<string | null>(null);
    let showPreview = $state(true);
    let previewData = $state<Record<string, any>>({});

    onMount(async () => {
        // Use the fields already loaded from the server
        fields = data.fields || [];
        loading = false;
        // Initialize preview data with default values
        initializePreviewData();
    });

    function initializePreviewData() {
        const data: Record<string, any> = {};
        fields.forEach(field => {
            switch (field.type) {
                case 'text':
                case 'textarea':
                    data[field.key] = '';
                    break;
                case 'number':
                    data[field.key] = 0;
                    break;
                case 'boolean':
                    data[field.key] = false;
                    break;
                case 'date':
                    data[field.key] = '';
                    break;
                case 'select':
                    data[field.key] = field.options?.[0] || '';
                    break;
                case 'multiselect':
                    data[field.key] = [];
                    break;
                case 'section_title':
                    data[field.key] = field.label;
                    break;
            }
        });
        previewData = data;
    }

    function renderFormField(field: any) {
        const fieldId = `preview-${field.id}`;
        
        switch (field.type) {
            case 'text':
                return `<input type="text" id="${fieldId}" name="${field.key}" placeholder="Enter ${field.label.toLowerCase()}" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" ${field.required ? 'required' : ''} />`;
            
            case 'textarea':
                return `<textarea id="${fieldId}" name="${field.key}" rows="3" placeholder="Enter ${field.label.toLowerCase()}" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" ${field.required ? 'required' : ''}></textarea>`;
            
            case 'number':
                return `<input type="number" id="${fieldId}" name="${field.key}" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" ${field.required ? 'required' : ''} />`;
            
            case 'boolean':
                return `<div class="mt-1">
                    <label class="inline-flex items-center">
                        <input type="checkbox" id="${fieldId}" name="${field.key}" class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded" ${field.required ? 'required' : ''} />
                        <span class="ml-2 text-sm text-gray-900">${field.label}</span>
                    </label>
                </div>`;
            
            case 'date':
                return `<input type="date" id="${fieldId}" name="${field.key}" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" ${field.required ? 'required' : ''} />`;
            
            case 'select':
                const selectOptions = field.options?.map((option: string) => 
                    `<option value="${option}">${option}</option>`
                ).join('') || '';
                return `<select id="${fieldId}" name="${field.key}" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" ${field.required ? 'required' : ''}>
                    <option value="">Select ${field.label.toLowerCase()}</option>
                    ${selectOptions}
                </select>`;
            
            case 'multiselect':
                const multiOptions = field.options?.map((option: string) => 
                    `<label class="inline-flex items-center">
                        <input type="checkbox" name="${field.key}[]" value="${option}" class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded" />
                        <span class="ml-2 text-sm text-gray-900">${option}</span>
                    </label>`
                ).join('<br>') || '';
                return `<div class="mt-1 space-y-2">${multiOptions}</div>`;
            
            case 'section_title':
                return `<div class="mt-4 mb-2">
                    <h3 class="text-lg font-medium text-gray-900 border-b border-gray-200 pb-2">${field.label}</h3>
                </div>`;
            
            default:
                return `<input type="text" id="${fieldId}" name="${field.key}" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />`;
        }
    }

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

    // Update preview data when fields change
    $effect(() => {
        if (fields.length > 0) {
            initializePreviewData();
        }
    });

    function startEdit(field: any) {
        editingFieldId = field.id;
        editForm = { 
            name: field.label, 
            type: field.type, 
            required: field.required, 
            options: field.options ? field.options.join('\n') : '',
            half_width: field.half_width || false
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
        fd.append('half_width', editForm.half_width ? 'on' : '');
        
        const res = await fetch('?/update_field', { method: 'POST', body: fd });
        const text = await res.text();
        console.log('Update field response:', text);
        const json = JSON.parse(text);
        const actionResult = JSON.parse(json.data);
        console.log('Update field result:', actionResult);
        if (actionResult[0]?.success) {
            editingFieldId = null;
            await refreshFields();
        } else {
            alert(actionResult[0]?.error || 'Update failed');
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

    async function duplicateField(field: any) {
        console.log('Duplicating field:', field);
        const fd = new FormData();
        fd.append('field_id', field.id);
        const res = await fetch('?/duplicate_field', { method: 'POST', body: fd });
        const text = await res.text();
        console.log('Duplicate field response:', text);
        const json = JSON.parse(text);
        const actionResult = JSON.parse(json.data);
        console.log('Duplicate field result:', actionResult);
        if (actionResult[0]?.success) {
            await refreshFields();
        } else {
            alert(actionResult[0]?.error || 'Duplicate failed');
        }
    }

    function getFieldTypeLabel(type: string) {
        const labels: Record<string, string> = {
            text: 'Text',
            textarea: 'Textarea',
            number: 'Number',
            boolean: 'Yes/No',
            date: 'Date',
            email: 'Email',
            phone: 'Phone',
            select: 'Single Select',
            multiselect: 'Multiple Select',
            section_title: 'Section Title'
        };
        return labels[type] || type;
    }

    function getFieldTypeIcon(type: string) {
        const icons: Record<string, any> = {
            text: Type,
            textarea: FileText,
            number: Hash,
            boolean: CheckSquare,
            date: Calendar,
            email: Mail,
            phone: Phone,
            select: List,
            multiselect: List,
            section_title: Heading
        };
        return icons[type] || Type;
    }

    // Group fields into rows for two-column layout
    function groupFieldsIntoRows(fields: any[]) {
        const rows: any[][] = [];
        let currentRow: any[] = [];
        
        for (const field of fields) {
            if (field.type === 'section_title') {
                // Section titles always start a new row
                if (currentRow.length > 0) {
                    rows.push(currentRow);
                    currentRow = [];
                }
                rows.push([field]);
            } else if (field.half_width) {
                // Half-width fields can share a row
                if (currentRow.length === 0) {
                    // Start a new row
                    currentRow = [field];
                } else if (currentRow.length === 1 && currentRow[0].half_width) {
                    // Add to existing half-width row
                    currentRow.push(field);
                    rows.push(currentRow);
                    currentRow = [];
                } else {
                    // Current row is full or has a full-width field, start new row
                    rows.push(currentRow);
                    currentRow = [field];
                }
            } else {
                // Full-width fields always start a new row
                if (currentRow.length > 0) {
                    rows.push(currentRow);
                    currentRow = [];
                }
                rows.push([field]);
            }
        }
        
        // Add any remaining fields
        if (currentRow.length > 0) {
            rows.push(currentRow);
        }
        
        return rows;
    }

    function handleDragStart(event: DragEvent, fieldId: string) {
        draggedFieldId = fieldId;
        if (event.dataTransfer) {
            event.dataTransfer.effectAllowed = 'move';
            event.dataTransfer.setData('text/plain', fieldId);
        }
    }

    function handleDragOver(event: DragEvent, fieldId: string) {
        event.preventDefault();
        if (event.dataTransfer) {
            event.dataTransfer.dropEffect = 'move';
        }
        draggedOverFieldId = fieldId;
    }

    function handleDragLeave(event: DragEvent) {
        // Only clear if we're leaving the entire field item, not just moving between child elements
        const currentTarget = event.currentTarget as HTMLElement;
        const relatedTarget = event.relatedTarget as Node;
        if (currentTarget && relatedTarget && !currentTarget.contains(relatedTarget)) {
            draggedOverFieldId = null;
        }
    }

    function handleDrop(event: DragEvent, targetFieldId: string) {
        event.preventDefault();
        
        if (!draggedFieldId || draggedFieldId === targetFieldId) {
            draggedFieldId = null;
            draggedOverFieldId = null;
            return;
        }

        // Reorder the fields array
        const draggedIndex = fields.findIndex(f => f.id === draggedFieldId);
        const targetIndex = fields.findIndex(f => f.id === targetFieldId);
        
        if (draggedIndex === -1 || targetIndex === -1) {
            draggedFieldId = null;
            draggedOverFieldId = null;
            return;
        }

        // Create new array with reordered fields
        const newFields = [...fields];
        const [draggedField] = newFields.splice(draggedIndex, 1);
        newFields.splice(targetIndex, 0, draggedField);
        
        fields = newFields;
        
        // Update order in database
        updateFieldOrder();
        
        draggedFieldId = null;
        draggedOverFieldId = null;
    }

    async function updateFieldOrder() {
        try {
            const fd = new FormData();
            fd.append('field_orders', JSON.stringify(fields.map((field, index) => ({
                id: field.id,
                order_index: index
            }))));
            
            const res = await fetch('?/update_field_order', { method: 'POST', body: fd });
            const text = await res.text();
            const json = JSON.parse(text);
            const actionResult = JSON.parse(json.data);
            
            if (!actionResult[0]?.success) {
                console.error('Failed to update field order:', actionResult[0]?.error);
                // Revert the order change
                await refreshFields();
            }
        } catch (error) {
            console.error('Error updating field order:', error);
            // Revert the order change
            await refreshFields();
        }
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
            <div class="flex gap-2">
                <button onclick={() => (showPreview = !showPreview)} class="inline-flex items-center px-3 py-2 border border-gray-300 text-sm font-medium rounded-md shadow-sm text-gray-700 bg-white hover:bg-gray-50">
                    {#if showPreview}
                        <EyeOff class="h-4 w-4 mr-2" /> Hide Preview
                    {:else}
                        <Eye class="h-4 w-4 mr-2" /> Show Preview
                    {/if}
                </button>
                <button onclick={() => (showCreateModal = true)} class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700">
                    <Plus class="h-4 w-4 mr-2" /> New Field
                </button>
            </div>
        </div>
    </div>

    {#if loading}
        <div class="flex justify-center py-12">
            <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
        </div>
    {:else}
        <div class="grid {showPreview ? 'grid-cols-1 lg:grid-cols-2' : 'grid-cols-1'} gap-6">
            <!-- Field Editor Panel -->
            <div class="space-y-4">
                <div class="bg-white shadow rounded-lg p-6">
                    <div class="flex items-center gap-2 mb-4">
                        <Edit class="h-5 w-5 text-indigo-600" />
                        <h2 class="text-lg font-medium text-gray-900">Field Editor</h2>
                    </div>
                    {#if fields.length === 0}
                        <div class="text-center py-8">
                            <p class="text-sm text-gray-500">No fields yet. Create your first one above.</p>
                        </div>
                    {:else}
                        <div class="space-y-3">
                            {#each fields as field}
                                {@const IconComponent = getFieldTypeIcon(field.type)}
                                <div 
                                    class="p-4 border border-gray-200 rounded-lg transition-colors duration-200 {draggedOverFieldId === field.id ? 'bg-blue-50 border-blue-500' : ''} {draggedFieldId === field.id ? 'opacity-50' : ''}"
                                    role="listitem"
                                    draggable={editingFieldId !== field.id}
                                    ondragstart={(e) => handleDragStart(e, field.id)}
                                    ondragover={(e) => handleDragOver(e, field.id)}
                                    ondragleave={handleDragLeave}
                                    ondrop={(e) => handleDrop(e, field.id)}
                                >
                                    {#if editingFieldId === field.id}
                                        <div class="space-y-4">
                                            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                                                <div>
                                                    <label for="edit-name-{field.id}" class="block text-sm font-medium text-gray-700">Field Name</label>
                                                    <input id="edit-name-{field.id}" bind:value={editForm.name} class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
                                                </div>
                                                <div>
                                                    <label for="edit-type-{field.id}" class="block text-sm font-medium text-gray-700">Field Type</label>
                                                    <select id="edit-type-{field.id}" bind:value={editForm.type} class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm">
                                                        <option value="text">Text</option>
                                                        <option value="textarea">Textarea</option>
                                                        <option value="number">Number</option>
                                                        <option value="boolean">Yes/No</option>
                                                        <option value="date">Date</option>
                                                        <option value="email">Email</option>
                                                        <option value="phone">Phone</option>
                                                        <option value="select">Single Select</option>
                                                        <option value="multiselect">Multiple Select</option>
                                                        <option value="section_title">Section Title</option>
                                                    </select>
                                                </div>
                                            </div>
                                            
                                            {#if editForm.type === 'select' || editForm.type === 'multiselect'}
                                                <div>
                                                    <label for="edit-options-{field.id}" class="block text-sm font-medium text-gray-700">Options (one per line)</label>
                                                    <textarea id="edit-options-{field.id}" bind:value={editForm.options} rows="3" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"></textarea>
                                                </div>
                                            {/if}
                                            
                                            {#if editForm.type !== 'section_title'}
                                                <div class="space-y-3">
                                                    <div class="flex items-center">
                                                        <input type="checkbox" id="edit-required-{field.id}" bind:checked={editForm.required} class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded">
                                                        <label for="edit-required-{field.id}" class="ml-2 block text-sm text-gray-900">Required field</label>
                                                    </div>
                                                    <div class="flex items-center">
                                                        <input type="checkbox" id="edit-half-width-{field.id}" bind:checked={editForm.half_width} class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded">
                                                        <label for="edit-half-width-{field.id}" class="ml-2 block text-sm text-gray-900">Half width (aligns with field above if also half width)</label>
                                                    </div>
                                                </div>
                                            {/if}
                                            
                                            <div class="flex gap-2">
                                                <button onclick={saveEdit} class="px-3 py-2 bg-indigo-600 text-white rounded">Save</button>
                                                <button onclick={() => (editingFieldId = null)} class="px-3 py-2 border rounded">Cancel</button>
                                            </div>
                                        </div>
                                    {:else}
                                        <div class="flex items-center justify-between">
                                            <div class="flex items-center gap-3">
                                                <div class="cursor-move text-gray-400 hover:text-gray-600">
                                                    <GripVertical class="h-5 w-5" />
                                                </div>
                                                <div class="flex items-center gap-2">
                                                    <div class="p-1 rounded bg-gray-100">
                                                        <IconComponent class="h-4 w-4 text-gray-600" />
                                                    </div>
                                                    <div>
                                                        <div class="flex items-center gap-2">
                                                            <span class="text-sm font-medium text-gray-900">{field.label}</span>
                                                            {#if field.half_width}
                                                                <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-blue-100 text-blue-800">
                                                                    ½ Width
                                                                </span>
                                                            {/if}
                                                        </div>
                                                        <div class="text-sm text-gray-500">
                                                            {getFieldTypeLabel(field.type)}
                                                            {#if field.required} • Required{/if}
                                                            {#if field.options && field.options.length > 0}
                                                                • {field.options.length} option{field.options.length === 1 ? '' : 's'}
                                                            {/if}
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="flex gap-3">
                                                <button class="text-indigo-600 hover:text-indigo-900" onclick={() => startEdit(field)}><Edit class="h-4 w-4" /></button>
                                                <button class="text-green-600 hover:text-green-900" onclick={() => duplicateField(field)} title="Duplicate field"><Copy class="h-4 w-4" /></button>
                                                <button class="text-red-600 hover:text-red-900" onclick={() => deleteField(field.id)}><Trash2 class="h-4 w-4" /></button>
                                            </div>
                                        </div>
                                    {/if}
                                </div>
                            {/each}
                        </div>
                    {/if}
                </div>
            </div>

            <!-- Form Preview Panel -->
            {#if showPreview}
                <div class="space-y-4">
                    <div class="bg-white shadow rounded-lg p-6">
                        <div class="flex items-center gap-2 mb-4">
                            <Eye class="h-5 w-5 text-indigo-600" />
                            <h2 class="text-lg font-medium text-gray-900">Form Preview</h2>
                        </div>
                        <p class="text-sm text-gray-500 mb-4">This is how your form will appear to students:</p>
                        
                        {#if fields.length === 0}
                            <div class="text-center py-8 border-2 border-dashed border-gray-300 rounded-lg">
                                <p class="text-sm text-gray-500">Add fields to see the preview</p>
                            </div>
                        {:else}
                            <div class="space-y-4">
                                {#each groupFieldsIntoRows(fields) as row}
                                    <div class="grid {row.length === 2 ? 'grid-cols-1 md:grid-cols-2' : 'grid-cols-1'} gap-4">
                                        {#each row as field}
                                            <div class="field-preview">
                                                {#if field.type === 'section_title'}
                                                    <div class="mt-4 mb-2 md:col-span-2">
                                                        <h3 class="text-lg font-medium text-gray-900 border-b border-gray-200 pb-2">{field.label}</h3>
                                                    </div>
                                                {:else}
                                                    <div>
                                                        <label for="preview-{field.id}" class="block text-sm font-medium text-gray-700">
                                                            {field.label}
                                                            {#if field.required}
                                                                <span class="text-red-500 ml-1">*</span>
                                                            {/if}
                                                        </label>
                                                        
                                                        {#if field.type === 'text'}
                                                            <input type="text" id="preview-{field.id}" placeholder="Enter {field.label.toLowerCase()}" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" disabled />
                                                        
                                                        {:else if field.type === 'textarea'}
                                                            <textarea id="preview-{field.id}" rows="3" placeholder="Enter {field.label.toLowerCase()}" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" disabled></textarea>
                                                        
                                                        {:else if field.type === 'number'}
                                                            <input type="number" id="preview-{field.id}" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" disabled />
                                                        
                                                        {:else if field.type === 'boolean'}
                                                            <div class="mt-1">
                                                                <label class="inline-flex items-center">
                                                                    <input type="checkbox" id="preview-{field.id}" class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded" disabled />
                                                                    <span class="ml-2 text-sm text-gray-900">{field.label}</span>
                                                                </label>
                                                            </div>
                                                        
                                                        {:else if field.type === 'date'}
                                                            <input type="date" id="preview-{field.id}" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" disabled />
                                                        
                                                        {:else if field.type === 'email'}
                                                            <input type="email" id="preview-{field.id}" placeholder="Enter email address" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" disabled />
                                                        
                                                        {:else if field.type === 'phone'}
                                                            <input type="tel" id="preview-{field.id}" placeholder="Enter phone number" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" disabled />
                                                        
                                                        {:else if field.type === 'select'}
                                                            <select id="preview-{field.id}" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" disabled>
                                                                <option value="">Select {field.label.toLowerCase()}</option>
                                                                {#each field.options || [] as option}
                                                                    <option value={option}>{option}</option>
                                                                {/each}
                                                            </select>
                                                        
                                                        {:else if field.type === 'multiselect'}
                                                            <div class="mt-1 space-y-2">
                                                                {#each field.options || [] as option}
                                                                    <label class="inline-flex items-center">
                                                                        <input type="checkbox" value={option} class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded" disabled />
                                                                        <span class="ml-2 text-sm text-gray-900">{option}</span>
                                                                    </label>
                                                                {/each}
                                                            </div>
                                                        
                                                        {:else}
                                                            <input type="text" id="preview-{field.id}" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" disabled />
                                                        {/if}
                                                    </div>
                                                {/if}
                                            </div>
                                        {/each}
                                    </div>
                                {/each}
                            </div>
                        {/if}
                    </div>
                </div>
            {/if}
        </div>
    {/if}
</div>

{#if showCreateModal}
    <div class="fixed inset-0 z-50 overflow-y-auto">
        <div class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
            <button type="button" class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" aria-label="Close" onclick={() => (showCreateModal = false)}></button>

            <div class="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full">
                <form method="POST" action="?/create_field" onsubmit={async (e) => { e.preventDefault(); const form = e.currentTarget as HTMLFormElement; const fd = new FormData(form); const res = await fetch(form.action, { method: 'POST', body: fd }); const text = await res.text(); console.log('Create field response:', text); const json = JSON.parse(text); const actionResult = JSON.parse(json.data); console.log('Create field result:', actionResult); if (actionResult[0]?.success) { fieldForm = { name: '', type: 'text', required: false, options: '', half_width: false }; showCreateModal = false; await refreshFields(); } else { alert(actionResult[0]?.error || 'Create failed'); } }}>
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
                                            <option value="textarea">Textarea</option>
                                            <option value="number">Number</option>
                                            <option value="boolean">Yes/No</option>
                                            <option value="date">Date</option>
                                            <option value="email">Email</option>
                                            <option value="phone">Phone</option>
                                            <option value="select">Single Select</option>
                                            <option value="multiselect">Multiple Select</option>
                                            <option value="section_title">Section Title</option>
                                        </select>
                                    </div>
                                    
                                    {#if fieldForm.type === 'select' || fieldForm.type === 'multiselect'}
                                        <div>
                                            <label for="modal_field_options" class="block text-sm font-medium text-gray-700">Options (one per line)</label>
                                            <textarea id="modal_field_options" name="options" bind:value={fieldForm.options} rows="3" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"></textarea>
                                        </div>
                                    {/if}
                                    
                                    {#if fieldForm.type !== 'section_title'}
                                        <div class="space-y-3">
                                            <div class="flex items-center">
                                                <input type="checkbox" id="modal_required" name="required" bind:checked={fieldForm.required} class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded">
                                                <label for="modal_required" class="ml-2 block text-sm text-gray-900">Required field</label>
                                            </div>
                                            <div class="flex items-center">
                                                <input type="checkbox" id="modal_half_width" name="half_width" bind:checked={fieldForm.half_width} class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded">
                                                <label for="modal_half_width" class="ml-2 block text-sm text-gray-900">Half width (aligns with field above if also half width)</label>
                                            </div>
                                        </div>
                                    {/if}
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
