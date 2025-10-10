import { createClient } from '@supabase/supabase-js';
import { PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY } from '$env/static/public';

if (!PUBLIC_SUPABASE_URL) {
	throw new Error('Missing PUBLIC_SUPABASE_URL environment variable');
}

if (!PUBLIC_SUPABASE_ANON_KEY) {
	throw new Error('Missing PUBLIC_SUPABASE_ANON_KEY environment variable');
}

// Define your database schema types here
export interface Database {
	public: {
		Tables: {
			profiles: {
				Row: {
					id: string;
					role: 'student' | 'teacher' | 'super_admin';
					first_name: string;
					last_name: string;
					email: string;
					phone: string | null;
					address: any | null;
					custom_fields: any;
					account_slug: string | null;
					subscription_plan: 'starter' | 'freelance' | 'business';
					subscription_active: boolean;
					stripe_customer_id: string | null;
					stripe_account_id: string | null;
					media_storage_used: number;
					messages_sent_this_month: number;
					subscription_start_date: string | null;
					subscription_end_date: string | null;
					is_suspended: boolean;
					created_at: string;
					updated_at: string;
				};
				Insert: {
					id: string;
					role?: 'student' | 'teacher' | 'super_admin';
					first_name: string;
					last_name: string;
					email: string;
					phone?: string | null;
					address?: any | null;
					custom_fields?: any;
					account_slug?: string | null;
					subscription_plan?: 'starter' | 'freelance' | 'business';
					subscription_active?: boolean;
					stripe_customer_id?: string | null;
					stripe_account_id?: string | null;
					media_storage_used?: number;
					messages_sent_this_month?: number;
					subscription_start_date?: string | null;
					subscription_end_date?: string | null;
					is_suspended?: boolean;
					created_at?: string;
					updated_at?: string;
				};
				Update: {
					id?: string;
					role?: 'student' | 'teacher' | 'super_admin';
					first_name?: string;
					last_name?: string;
					email?: string;
					phone?: string | null;
					address?: any | null;
					custom_fields?: any;
					account_slug?: string | null;
					subscription_plan?: 'starter' | 'freelance' | 'business';
					subscription_active?: boolean;
					stripe_customer_id?: string | null;
					stripe_account_id?: string | null;
					media_storage_used?: number;
					messages_sent_this_month?: number;
					subscription_start_date?: string | null;
					subscription_end_date?: string | null;
					is_suspended?: boolean;
					created_at?: string;
					updated_at?: string;
				};
			};
			courses: {
				Row: {
					id: string;
					teacher_id: string;
					title: string;
					course_code: string;
					description: string | null;
					image_url: string | null;
					price: number;
					is_published: boolean;
					created_at: string;
					updated_at: string;
				};
				Insert: {
					id?: string;
					teacher_id: string;
					title: string;
					course_code: string;
					description?: string | null;
					image_url?: string | null;
					price?: number;
					is_published?: boolean;
					created_at?: string;
					updated_at?: string;
				};
				Update: {
					id?: string;
					teacher_id?: string;
					title?: string;
					course_code?: string;
					description?: string | null;
					image_url?: string | null;
					price?: number;
					is_published?: boolean;
					created_at?: string;
					updated_at?: string;
				};
			};
			lessons: {
				Row: {
					id: string;
					title: string;
					description: string | null;
					image_url: string | null;
					content_blocks: any;
					created_at: string;
					updated_at: string;
				};
				Insert: {
					id?: string;
					title: string;
					description?: string | null;
					image_url?: string | null;
					content_blocks?: any;
					created_at?: string;
					updated_at?: string;
				};
				Update: {
					id?: string;
					title?: string;
					description?: string | null;
					image_url?: string | null;
					content_blocks?: any;
					created_at?: string;
					updated_at?: string;
				};
			};
			course_lessons: {
				Row: {
					id: string;
					course_id: string;
					lesson_id: string;
					status: 'active' | 'inactive' | 'disabled';
					scheduled_date: string | null;
					order_index: number;
					created_at: string;
				};
				Insert: {
					id?: string;
					course_id: string;
					lesson_id: string;
					status?: 'active' | 'inactive' | 'disabled';
					scheduled_date?: string | null;
					order_index?: number;
					created_at?: string;
				};
				Update: {
					id?: string;
					course_id?: string;
					lesson_id?: string;
					status?: 'active' | 'inactive' | 'disabled';
					scheduled_date?: string | null;
					order_index?: number;
					created_at?: string;
				};
			};
			media: {
				Row: {
					id: string;
					teacher_id: string;
					title: string;
					description: string | null;
					file_url: string | null;
					video_url: string | null;
					media_type: 'image' | 'pdf' | 'video_url' | 'audio';
					file_size: number | null;
					mime_type: string | null;
					created_at: string;
				};
				Insert: {
					id?: string;
					teacher_id: string;
					title: string;
					description?: string | null;
					file_url?: string | null;
					video_url?: string | null;
					media_type: 'image' | 'pdf' | 'video_url' | 'audio';
					file_size?: number | null;
					mime_type?: string | null;
					created_at?: string;
				};
				Update: {
					id?: string;
					teacher_id?: string;
					title?: string;
					description?: string | null;
					file_url?: string | null;
					video_url?: string | null;
					media_type?: 'image' | 'pdf' | 'video_url' | 'audio';
					file_size?: number | null;
					mime_type?: string | null;
					created_at?: string;
				};
			};
			student_courses: {
				Row: {
					id: string;
					student_id: string;
					course_id: string;
					enrolled_at: string;
					payment_status: string;
					stripe_subscription_id: string | null;
					stripe_payment_intent_id: string | null;
					amount_paid: number | null;
					payment_date: string | null;
				};
				Insert: {
					id?: string;
					student_id: string;
					course_id: string;
					enrolled_at?: string;
					payment_status?: string;
					stripe_subscription_id?: string | null;
					stripe_payment_intent_id?: string | null;
					amount_paid?: number | null;
					payment_date?: string | null;
				};
				Update: {
					id?: string;
					student_id?: string;
					course_id?: string;
					enrolled_at?: string;
					payment_status?: string;
					stripe_subscription_id?: string | null;
					stripe_payment_intent_id?: string | null;
					amount_paid?: number | null;
					payment_date?: string | null;
				};
			};
			notes: {
				Row: {
					id: string;
					teacher_id: string;
					subject: string;
					message: string;
					scope: 'course' | 'lesson' | 'student';
					course_id: string | null;
					lesson_id: string | null;
					student_id: string | null;
					email_sent: boolean;
					email_sent_at: string | null;
					created_at: string;
				};
				Insert: {
					id?: string;
					teacher_id: string;
					subject: string;
					message: string;
					scope: 'course' | 'lesson' | 'student';
					course_id?: string | null;
					lesson_id?: string | null;
					student_id?: string | null;
					email_sent?: boolean;
					email_sent_at?: string | null;
					created_at?: string;
				};
				Update: {
					id?: string;
					teacher_id?: string;
					subject?: string;
					message?: string;
					scope?: 'course' | 'lesson' | 'student';
					course_id?: string | null;
					lesson_id?: string | null;
					student_id?: string | null;
					email_sent?: boolean;
					email_sent_at?: string | null;
					created_at?: string;
				};
			};
			note_replies: {
				Row: {
					id: string;
					note_id: string;
					student_id: string | null;
					teacher_id: string | null;
					message: string;
					is_from_email: boolean;
					created_at: string;
				};
				Insert: {
					id?: string;
					note_id: string;
					student_id?: string | null;
					teacher_id?: string | null;
					message: string;
					is_from_email?: boolean;
					created_at?: string;
				};
				Update: {
					id?: string;
					note_id?: string;
					student_id?: string | null;
					teacher_id?: string | null;
					message?: string;
					is_from_email?: boolean;
					created_at?: string;
				};
			};
			student_lesson_content: {
				Row: {
					id: string;
					student_id: string;
					lesson_id: string;
					course_id: string;
					media_id: string | null;
					content: string | null;
					created_at: string;
				};
				Insert: {
					id?: string;
					student_id: string;
					lesson_id: string;
					course_id: string;
					media_id?: string | null;
					content?: string | null;
					created_at?: string;
				};
				Update: {
					id?: string;
					student_id?: string;
					lesson_id?: string;
					course_id?: string;
					media_id?: string | null;
					content?: string | null;
					created_at?: string;
				};
			};
			platform_settings: {
				Row: {
					id: string;
					key: string;
					value: any;
					description: string | null;
					updated_at: string;
				};
				Insert: {
					id?: string;
					key: string;
					value: any;
					description?: string | null;
					updated_at?: string;
				};
				Update: {
					id?: string;
					key?: string;
					value?: any;
					description?: string | null;
					updated_at?: string;
				};
			};
			payments: {
				Row: {
					id: string;
					student_id: string;
					teacher_id: string;
					course_id: string;
					amount: number;
					currency: string;
					stripe_payment_intent_id: string | null;
					stripe_charge_id: string | null;
					platform_fee: number;
					teacher_earnings: number;
					status: string;
					created_at: string;
				};
				Insert: {
					id?: string;
					student_id: string;
					teacher_id: string;
					course_id: string;
					amount: number;
					currency?: string;
					stripe_payment_intent_id?: string | null;
					stripe_charge_id?: string | null;
					platform_fee?: number;
					teacher_earnings?: number;
					status: string;
					created_at?: string;
				};
				Update: {
					id?: string;
					student_id?: string;
					teacher_id?: string;
					course_id?: string;
					amount?: number;
					currency?: string;
					stripe_payment_intent_id?: string | null;
					stripe_charge_id?: string | null;
					platform_fee?: number;
					teacher_earnings?: number;
					status?: string;
					created_at?: string;
				};
			};
		};
		Views: {
			[_ in never]: never;
		};
		Functions: {
			[_ in never]: never;
		};
		Enums: {
			user_role: 'student' | 'teacher' | 'super_admin';
			subscription_plan: 'starter' | 'freelance' | 'business';
			lesson_status: 'active' | 'inactive' | 'disabled';
			media_type: 'image' | 'pdf' | 'video_url' | 'audio';
			note_scope: 'course' | 'lesson' | 'student';
		};
	};
}

export const supabase = createClient<Database>(PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY, {
	auth: {
		autoRefreshToken: true,
		persistSession: true,
		detectSessionInUrl: true
	}
});

// Export types for better TypeScript support
export type Tables<T extends keyof Database['public']['Tables']> = Database['public']['Tables'][T]['Row'];
export type TablesInsert<T extends keyof Database['public']['Tables']> = Database['public']['Tables'][T]['Insert'];
export type TablesUpdate<T extends keyof Database['public']['Tables']> = Database['public']['Tables'][T]['Update'];
export type Enums<T extends keyof Database['public']['Enums']> = Database['public']['Enums'][T];
