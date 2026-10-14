import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || 'https://rbqjanevxnmllpvsssth.supabase.co';
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJicWphbmV2eG5tbGxwdnNzc3RoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE4Nzk0NTEsImV4cCI6MjEwNzQ1NTQ1MX0.8TNUWVK-FldUJGwIPCCmD9WwNd1LUo5-dw1zQU2Yg7M';

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Supabase environment variables are missing! Please create a .env file containing VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY.');
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    storage: sessionStorage,
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: true
  },
  realtime: {
    params: {
      eventsPerSecond: 10
    }
  }
});

/**
 * Safely broadcast a live notification across all connected clients
 */
export async function broadcastLiveNotification(payload: any) {
  try {
    const channel = supabase.channel('app-global-live-notifications');
    await channel.send({
      type: 'broadcast',
      event: 'new_notification',
      payload
    });
  } catch (e) {}
}
