import { asClient } from './helpers.ts'
import type { MockResult } from './helpers.ts'
import test from "node:test";
import assert from "node:assert/strict";
import { getAdminSession, signInAdmin, signOutAdmin } from "../src/utils/adminAuth.ts"
import { QueryClient, MutationObserver } from "@tanstack/vue-query"

function clientFor(session: { user: { id: string } } | null, adminRow: unknown, queryError: unknown = null) {
  return {
    auth: { getSession: async () => ({ data: { session } }), signInWithPassword: async (_input: { email: string; password: string }): Promise<MockResult> => ({}), signOut: async (): Promise<MockResult> => ({}) },
    from(table: string) {
      assert.equal(table, "admin_users");
      return {
        select(columns: string) {
          assert.equal(columns, "user_id");
          return {
            eq(column: string, userId: string) {
              assert.equal(column, "user_id");
              assert.equal(userId, session?.user.id);
              return {
                maybeSingle: async () => ({ data: adminRow, error: queryError }),
              };
            },
          };
        },
      };
    },
  };
}

test("returns null when no session exists", async () => {
  const client = clientFor(null, null);
  assert.equal(await getAdminSession(asClient(client)), null);
});

test("returns null when the user is not an admin", async () => {
  const session = { user: { id: "user-1" } };
  assert.equal(await getAdminSession(asClient(clientFor(session, null))), null);
});

test("fails closed when the admin check errors", async () => {
  const session = { user: { id: "user-1" } };
  assert.equal(
    await getAdminSession(asClient(clientFor(session, null, new Error("query failed")))),
    null,
  );
});

test("returns session for an authorized admin", async () => {
  const session = { user: { id: "admin-1" } };
  assert.equal(
    await getAdminSession(asClient(clientFor(session, { user_id: "admin-1" }))),
    session,
  );
});

test("login mutation exposes pending/error and can retry successfully", async () => {
  const session = { user: { id: "admin-1" } };
  const client = clientFor(session, { user_id: "admin-1" });
  const credentials = { email: "admin@example.com", password: "secret" };
  const authError = new Error("Invalid credentials");
  let fail = true;
  client.auth.signInWithPassword = async (input) => {
    assert.deepEqual(input, credentials);
    return { error: fail ? authError : null };
  };
  const queryClient = new QueryClient();
  const mutation = new MutationObserver(queryClient, {
    mutationFn: (input: { email: string; password: string }) => signInAdmin(asClient(client), input),
    retry: false,
    gcTime: 0,
  });
  const unsubscribe = mutation.subscribe(() => {});
  try {
    const failedLogin = mutation.mutate(credentials);
    assert.equal(mutation.getCurrentResult().isPending, true);
    await assert.rejects(failedLogin, authError);
    assert.equal(mutation.getCurrentResult().isPending, false);
    assert.equal(mutation.getCurrentResult().error, authError);
    fail = false;
    assert.equal(await mutation.mutate(credentials), session);
    assert.equal(mutation.getCurrentResult().error, null);
  } finally {
    unsubscribe();
    queryClient.clear();
  }
});

test("login rejects non-admin users and signs them out", async () => {
  const client = clientFor({ user: { id: "user-1" } }, null);
  let signedOut = false;
  client.auth.signInWithPassword = async () => ({ error: null });
  client.auth.signOut = async () => {
    signedOut = true;
    return { error: null };
  };
  await assert.rejects(signInAdmin(asClient(client), { email: '', password: '' }), { message: 'auth.errors.adminRequired' });
  assert.equal(signedOut, true);
});

test("logout propagates API failures and succeeds on retry", async () => {
  const error = new Error("Network failure");
  const client = { auth: { signOut: async (): Promise<MockResult> => ({ error }) } };
  await assert.rejects(signOutAdmin(asClient(client)), error);
  client.auth.signOut = async () => ({ error: null });
  await signOutAdmin(asClient(client));
});
