import { supabase } from './supabase';

// Simplified database utility functions
export class DatabaseUtils {
	/**
	 * Generic function to fetch all records from a table
	 */
	static async getAll(table: string): Promise<{ data: any[] | null; error: any }> {
		const { data, error } = await supabase.from(table).select('*');
		return { data, error };
	}

	/**
	 * Generic function to fetch a single record by ID
	 */
	static async getById(table: string, id: string): Promise<{ data: any | null; error: any }> {
		const { data, error } = await supabase.from(table).select('*').eq('id', id).single();
		return { data, error };
	}

	/**
	 * Generic function to insert a new record
	 */
	static async insert(table: string, record: any): Promise<{ data: any | null; error: any }> {
		const { data, error } = await supabase.from(table).insert(record).select().single();
		return { data, error };
	}

	/**
	 * Generic function to update a record by ID
	 */
	static async update(table: string, id: string, updates: any): Promise<{ data: any | null; error: any }> {
		const { data, error } = await supabase
			.from(table)
			.update(updates as any)
			.eq('id', id)
			.select()
			.single();
		return { data, error };
	}

	/**
	 * Generic function to delete a record by ID
	 */
	static async delete(table: string, id: string): Promise<{ error: any }> {
		const { error } = await supabase.from(table).delete().eq('id', id);
		return { error };
	}

	/**
	 * Generic function to fetch records with pagination
	 */
	static async getPaginated(
		table: string,
		page: number = 1,
		pageSize: number = 10
	): Promise<{ data: any[] | null; error: any; count: number | null }> {
		const from = (page - 1) * pageSize;
		const to = from + pageSize - 1;

		const { data, error, count } = await supabase
			.from(table)
			.select('*', { count: 'exact' })
			.range(from, to);
		
		return { data, error, count };
	}
}

// Auth utility functions
export class AuthUtils {
	/**
	 * Get current user session
	 */
	static async getCurrentUser() {
		const { data: { user }, error } = await supabase.auth.getUser();
		return { user, error };
	}

	/**
	 * Sign in with email and password
	 */
	static async signIn(email: string, password: string) {
		const { data, error } = await supabase.auth.signInWithPassword({
			email,
			password
		});
		return { data, error };
	}

	/**
	 * Sign up with email and password
	 */
	static async signUp(email: string, password: string) {
		const { data, error } = await supabase.auth.signUp({
			email,
			password
		});
		return { data, error };
	}

	/**
	 * Sign out current user
	 */
	static async signOut() {
		const { error } = await supabase.auth.signOut();
		return { error };
	}

	/**
	 * Listen to auth state changes
	 */
	static onAuthStateChange(callback: (event: string, session: any) => void) {
		return supabase.auth.onAuthStateChange(callback);
	}
}
