import test from "node:test";
import assert from "node:assert/strict";
import { getAdminSession, signInAdmin, signOutAdmin } from "../src/utils/adminAuth.js";
import { QueryClient, MutationObserver } from "@tanstack/vue-query";

function clientFor(session, adminRow, queryError = null) {
  return {
    auth: { getSession: async () => ({ data: { session } }) },
    from(table) {
      assert.equal(table, "admin_users");
      return {
        select(columns) {
          assert.equal(columns, "user_id");
          return {
            eq(column, userId) {
              assert.equal(column, "user_id");
              assert.equal(userId, session.user.id);
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
  assert.equal(await getAdminSession(client), null);
});

test("returns null when the user is not an admin", async () => {
  const session = { user: { id: "user-1" } };
  assert.equal(await getAdminSession(clientFor(session, null)), null);
});

test("fails closed when the admin check errors", async () => {
  const session = { user: { id: "user-1" } };
  assert.equal(
    await getAdminSession(clientFor(session, null, new Error("query failed"))),
    null,
  );
});

test("returns session for an authorized admin", async () => {
  const session = { user: { id: "admin-1" } };
  assert.equal(
    await getAdminSession(clientFor(session, { user_id: "admin-1" })),
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
    mutationFn: (input) => signInAdmin(client, input),
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
  await assert.rejects(signInAdmin(client, {}), /chưa được cấp quyền quản trị/);
  assert.equal(signedOut, true);
});

test("logout propagates API failures and succeeds on retry", async () => {
  const error = new Error("Network failure");
  const client = { auth: { signOut: async () => ({ error }) } };
  await assert.rejects(signOutAdmin(client), error);
  client.auth.signOut = async () => ({ error: null });
  await signOutAdmin(client);
});
