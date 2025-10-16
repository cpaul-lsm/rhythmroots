import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { PUBLIC_SUPABASE_URL } from '$env/static/public';
import { SUPABASE_SERVICE_ROLE_KEY } from '$env/static/private';
import type { Database } from './supabase';

let cachedAdminClient: SupabaseClient<Database> | null = null;

export function getSupabaseAdmin(): SupabaseClient<Database> {
    if (cachedAdminClient) return cachedAdminClient;

    if (!PUBLIC_SUPABASE_URL) {
        throw new Error('Missing PUBLIC_SUPABASE_URL environment variable');
    }

    if (!SUPABASE_SERVICE_ROLE_KEY) {
        throw new Error('Missing SUPABASE_SERVICE_ROLE_KEY environment variable');
    }

    cachedAdminClient = createClient<Database>(PUBLIC_SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
        auth: {
            autoRefreshToken: false,
            persistSession: false
        }
    });
    return cachedAdminClient;
}
