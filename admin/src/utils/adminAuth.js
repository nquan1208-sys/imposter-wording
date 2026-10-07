export async function signInAdmin(supabase, credentials) {
  const { error } = await supabase.auth.signInWithPassword(credentials);
  if (error) throw error;

  const session = await getAdminSession(supabase);
  if (!session) {
    await signOutAdmin(supabase);
    throw new Error("Tài khoản này chưa được cấp quyền quản trị.");
  }
  return session;
}

export async function signOutAdmin(supabase) {
  const { error } = await supabase.auth.signOut();
  if (error) throw error;
}

export async function getAdminSession(supabase) {
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
