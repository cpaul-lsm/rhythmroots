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
    let courseAssignments = $state<Record<string, any[]>>({});
    let selectedCourseForAssignment = $state<string>('');
    let loadingAssignments = $state<Record<string, boolean>>({});
    let assignmentsVersion = $state(0); // Force reactivity
    
    // Initialize courseAssignments for all field sets
    function initializeCourseAssignments() {
        fieldSets.forEach(set => {
            if (!courseAssignments[set.id]) {
                courseAssignments[set.id] = [];
            }
        });
    }

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
                        const fieldSet: any = {};
                        Object.keys(schema).forEach((key, index) => {
                            fieldSet[key] = actualData[i + index];
                        });
                        fieldSetsArray.push(fieldSet);
                    }
                    
                    fieldSets = fieldSetsArray;
                    
                    // Initialize course assignments
                    initializeCourseAssignments();
                    
                    // Load course assignments for all field sets
                    for (const set of fieldSetsArray) {
                        await loadCourseAssignments((set as any).id);
                    }
                    
                    // Force reactivity update
                    courseAssignments = { ...courseAssignments };
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

    async function loadCourseAssignments(fieldSetId: string) {
        try {
            loadingAssignments[fieldSetId] = true;
            const fd = new FormData();
            fd.append('field_set_id', fieldSetId);
            const res = await fetch('?/get_course_assignments', { method: 'POST', body: fd });
            const text = await res.text();
            const json = JSON.parse(text);
            const actionResult = JSON.parse(json.data);
            
            if (actionResult[0]?.success) {
                // Handle both new and old data formats
                let assignments = actionResult[0].assignments || [];
                
                // If assignments is a number (count) and there are no assignments, set to empty array
                if (typeof assignments === 'number' && assignments === 0) {
                    assignments = [];
                }
                
                // If assignments is not an array, try to parse from the raw data format
                if (!Array.isArray(assignments) && actionResult.length > 3) {
                    const assignmentsData = actionResult.slice(3);
                    assignments = [];
                    
                    // Parse the data structure: [course_id_object, course_id_string, courses_object, title, course_code]
                    const courseIdString = assignmentsData[1];
                    const title = assignmentsData[3];
                    const courseCode = assignmentsData[4];
                    
                    // Use the string version of the course ID
                    if (courseIdString && typeof courseIdString === 'string') {
                        assignments.push({
                            course_id: courseIdString,
                            courses: {
                                title: title,
                                course_code: courseCode
                            }
                        });
                    }
                }
                
                // Remove duplicates based on course_id (only if assignments is an array)
                const uniqueAssignments = Array.isArray(assignments) 
                    ? assignments.filter((assignment: any, index: number, self: any[]) => 
                        index === self.findIndex((a: any) => a.course_id === assignment.course_id)
                      )
                    : [];
                
                // Update the assignments and force reactivity
                courseAssignments[fieldSetId] = uniqueAssignments;
                // Force reactivity by creating a new object reference and incrementing version
                courseAssignments = { ...courseAssignments };
                assignmentsVersion++;
                
            } else {
                console.error('Load course assignments error:', actionResult[0]?.error || 'Unknown error');
                courseAssignments[fieldSetId] = [];
            }
        } catch (error) {
            console.error('Load course assignments error:', error);
            courseAssignments[fieldSetId] = [];
        } finally {
            loadingAssignments[fieldSetId] = false;
        }
    }

    async function assignToCourse(fieldSetId: string, courseId: string) {
        try {
            const fd = new FormData();
            fd.append('field_set_id', fieldSetId);
            fd.append('course_id', courseId);
            const res = await fetch('?/assign_to_course', { method: 'POST', body: fd });
            const text = await res.text();
            const json = JSON.parse(text);
            const actionResult = JSON.parse(json.data);
            
            if (actionResult[0]?.success) {
                await loadCourseAssignments(fieldSetId);
            } else {
                console.error('Assign to course error:', actionResult[0]?.error || 'Unknown error');
                alert('Failed to assign field set to course: ' + (actionResult[0]?.error || 'Unknown error'));
            }
        } catch (error) {
            console.error('Assign to course error:', error);
            alert('Failed to assign field set to course: ' + error);
        }
    }

    async function unassignFromCourse(fieldSetId: string, courseId: string) {
        try {
            const fd = new FormData();
            fd.append('field_set_id', fieldSetId);
            fd.append('course_id', courseId);
            const res = await fetch('?/unassign_from_course', { method: 'POST', body: fd });
            const text = await res.text();
            const json = JSON.parse(text);
            const actionResult = JSON.parse(json.data);
            
            if (actionResult[0]?.success) {
                await loadCourseAssignments(fieldSetId);
            } else {
                console.error('Unassign from course error:', actionResult[0]?.error || 'Unknown error');
                alert('Failed to unassign field set from course: ' + (actionResult[0]?.error || 'Unknown error'));
            }
        } catch (error) {
            console.error('Unassign from course error:', error);
            alert('Failed to unassign field set from course: ' + error);
        }
    }

    function startEdit(set: any) {
        editingSetId = set.id;
        editForm = { name: set.name, description: set.description || '' };
        selectedCourseForAssignment = ''; // Clear any previously selected course
        // Load course assignments for this set
        loadCourseAssignments(set.id);
    }
</script>

<div class="px-4 sm:px-6 lg:px-8 py-8">
    <div class="mb-8">
        <div class="flex items-center justify-between">
            <div>
                <h1 class="text-3xl font-bold text-gray-900">Student Field Sets</h1>
                <p class="mt-2 text-gray-600">Create and manage custom field sets for your courses.</p>
            </div>
            <div class="flex gap-2">
                <button onclick={async () => { for (const set of fieldSets) { await loadCourseAssignments(set.id); } courseAssignments = { ...courseAssignments }; }} class="inline-flex items-center px-3 py-2 border border-gray-300 text-sm font-medium rounded-md shadow-sm text-gray-700 bg-white hover:bg-gray-50">
                    Refresh Assignments
                </button>
                <button onclick={() => (showCreateModal = true)} class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700">
                    <Plus class="h-4 w-4 mr-2" /> New set
                </button>
            </div>
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
                            <div class="space-y-4">
                                <div class="grid grid-cols-1 md:grid-cols-3 gap-3 items-end">
                                    <input bind:value={editForm.name} placeholder="Set name" class="border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
                                    <input bind:value={editForm.description} placeholder="Description" class="md:col-span-2 border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
                                </div>
                                
                                <!-- Course Assignment Section -->
                                <div class="border-t pt-4">
                                    <h4 class="text-sm font-medium text-gray-900 mb-3">Course Assignments</h4>
                                    
                                    <!-- Current Assignments -->
                                    {#if courseAssignments[set.id] && courseAssignments[set.id].length > 0}
                                        <div class="mb-3">
                                            <p class="text-sm text-gray-600 mb-2">Currently assigned to:</p>
                                            <div class="flex flex-wrap gap-2">
                                                {#each courseAssignments[set.id] as assignment}
                                                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-indigo-100 text-indigo-800">
                                                        {assignment.courses.title}
                                                        {#if assignment.courses.course_code}
                                                            ({assignment.courses.course_code})
                                                        {/if}
                                                        <button 
                                                            type="button"
                                                            onclick={() => unassignFromCourse(set.id, assignment.course_id)}
                                                            class="ml-1 inline-flex items-center justify-center w-4 h-4 rounded-full text-indigo-400 hover:text-indigo-600 hover:bg-indigo-200"
                                                        >
                                                            ×
                                                        </button>
                                                    </span>
                                                {/each}
                                            </div>
                                        </div>
                                    {/if}
                                    
                                    <!-- Add New Assignment -->
                                    <div>
                                        <select 
                                            bind:value={selectedCourseForAssignment}
                                            class="w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                                        >
                                            <option value="">Select a course to assign...</option>
                                            {#each data.courses as course}
                                                {#if !(courseAssignments[set.id] || []).some(a => a.course_id === course.id)}
                                                    <option value={course.id}>
                                                        {course.title}
                                                        {#if course.course_code}
                                                            ({course.course_code})
                                                        {/if}
                                                    </option>
                                                {/if}
                                            {/each}
                                        </select>
                                        <p class="mt-1 text-xs text-gray-500">Selected course will be assigned when you save</p>
                                    </div>
                                </div>
                                
                                <div class="flex gap-2">
                                    <form method="POST" action="?/update_set" onsubmit={async (e) => { e.preventDefault(); try { const form = e.currentTarget as HTMLFormElement; const fd = new FormData(form); fd.append('id', editingSetId as string);  const res = await fetch(form.action, { method: 'POST', body: fd }); const text = await res.text();  const json = JSON.parse(text); const actionResult = JSON.parse(json.data);  if (actionResult[0]?.success) { if (selectedCourseForAssignment) { await assignToCourse(editingSetId as string, selectedCourseForAssignment); selectedCourseForAssignment = ''; } editingSetId = null; await refreshSets(); } else { alert('Update failed: ' + (actionResult[0]?.error || 'Unknown error')); } } catch (error) { console.error('Save error:', error); alert('Update failed: ' + error); } }}>
                                        <input type="hidden" name="name" value={editForm.name} />
                                        <input type="hidden" name="description" value={editForm.description} />
                                        <button type="submit" class="px-3 py-2 bg-indigo-600 text-white rounded">Save</button>
                                    </form>
                                    <button class="px-3 py-2 border rounded" onclick={() => { editingSetId = null; selectedCourseForAssignment = ''; }}>Cancel</button>
                                </div>
                            </div>
                        {:else}
                            <div class="flex items-center justify-between">
                                <div class="flex-1">
                                    <div class="set-name text-sm font-medium text-gray-900">{set.name}</div>
                                    {#if set.description}
                                        <div class="text-sm text-gray-500 mt-1">{set.description}</div>
                                    {/if}
                                    <!-- Show course assignments if any -->
                                    {#if loadingAssignments[set.id]}
                                        <div class="mt-2 text-xs text-gray-400">Loading course assignments...</div>
                                    {:else if courseAssignments[set.id] && courseAssignments[set.id].length > 0}
                                        <div class="mt-2">
                                            <span class="text-xs text-gray-500">Assigned to: </span>
                                            <div class="inline-flex flex-wrap gap-1">
                                                {#each courseAssignments[set.id] as assignment}
                                                    <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-blue-100 text-blue-800">
                                                        {assignment.courses.title}
                                                        {#if assignment.courses.course_code}
                                                            ({assignment.courses.course_code})
                                                        {/if}
                                                    </span>
                                                {/each}
                                            </div>
                                        </div>
                                    {:else}
                                        <!-- Show when no assignments -->
                                        <div class="mt-2 text-xs text-gray-400">
                                            No course assignments
                                        </div>
                                    {/if}
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


