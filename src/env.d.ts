/// <reference types="vite/client" />

declare module '$env/static/public' {
	export const PUBLIC_SUPABASE_URL: string;
	export const PUBLIC_SUPABASE_ANON_KEY: string;
}

declare module '$env/static/private' {
	export const ENCRYPTION_KEY: string;
}
