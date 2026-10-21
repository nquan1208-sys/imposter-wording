import type { AdminClient } from '../types/admin.ts'
import { errorFields } from '../types/admin.ts'
export async function signInAdmin(supabase: AdminClient, credentials: { email: string; password: string }) {
  const { error } = await supabase.auth.signInWithPassword(credentials);
  if (error) throw error;

  const session = await getAdminSession(supabase);
  if (!session) {
    await signOutAdmin(supabase);
    throw new Error("auth.errors.adminRequired");
  }
  return session;
}

export async function signOutAdmin(supabase: AdminClient) {
  const { error } = await supabase.auth.signOut();
  if (error) throw error;
}

export async function getAdminSession(supabase: AdminClient) {
  const { data, error } = await supabase.auth.getSession();
  const session = data?.session;
  if (error || !session?.user?.id) return null;

  const result = await supabase
    .from("admin_users")
    .select("user_id")
    .eq("user_id", session.user.id)
    .maybeSingle();

  return result.error || !result.data ? null : session;
}

const loginErrorKeys: Record<string, string> = {
  invalid_credentials: 'auth.errors.invalidCredentials',
  email_not_confirmed: 'auth.errors.emailNotConfirmed',
  over_request_rate_limit: 'auth.errors.rateLimited',
  over_email_send_rate_limit: 'auth.errors.rateLimited',
}
export function adminAuthError(cause: unknown) {
  const error = errorFields(cause)
  if (error?.message === 'auth.errors.adminRequired') return 'auth.errors.adminRequired'
  return loginErrorKeys[error?.code] || 'auth.errors.loginFailed'
}
