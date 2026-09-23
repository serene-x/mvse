// Renderer-side Supabase client (anon key). Used for realtime + reads only.
// All writes go through window.admin.* IPC -> service_role in main process.
import { createClient } from '@supabase/supabase-js';

const { supabaseUrl, supabaseAnonKey } = window.admin?.env ?? {};

if (!supabaseUrl || !supabaseAnonKey) {
  console.warn('Supabase env not provided via preload — check .env');
}

export const supabase = createClient(supabaseUrl ?? '', supabaseAnonKey ?? '', {
  auth: { persistSession: false },
});
