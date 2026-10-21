import assert from 'node:assert/strict'
import type { App, ComponentInternalInstance, SetupContext } from 'vue'
import type { AdminClient } from '../src/types/admin.ts'

export type MockResult = { data?: unknown; error?: unknown; count?: number }
export type Calls = unknown[][]
// Test doubles implement only the SDK methods exercised by each scenario.
export function asClient(value: object): AdminClient { return value as AdminClient }
export type QueryStub = Record<string, (...args: never[]) => unknown> & {
  then: (resolve: (value: MockResult) => unknown) => unknown
}
export type RpcStub = (name: string, input: Record<string, unknown>) => Promise<MockResult>
export type ClientStub = {
  from: (table: string) => QueryStub
  rpc: RpcStub
  auth: {
    getUser: () => Promise<{ data: { user: { id?: string; email?: string } | null }; error?: unknown }>
    getSession: () => Promise<unknown>
    signOut: () => Promise<MockResult>
    signInWithPassword: (credentials: { email: string; password: string }) => Promise<MockResult>
  }
}
export function testWindow(value: Pick<Window, 'confirm'> & Partial<Window>): Window & typeof globalThis {
  return value as Window & typeof globalThis
}
export type HostNode = { text: string; children: HostNode[]; parent: HostNode | null }
// Rendered Vue attributes contain event handlers and framework-specific values.
export type NavigationNode = { text: string; tag: string; props: Record<string, any>; children: NavigationNode[]; parent: NavigationNode | null }
// SSR-loaded SFCs do not expose their private script-setup type. Keep the cast at the inspection boundary.
export function setupState(instance: ComponentInternalInstance | null): Record<string, any> {
  assert.ok(instance)
  return (instance as ComponentInternalInstance & { setupState: Record<string, any> }).setupState
}
export type TestApp = App<HostNode>
export type StubContext = SetupContext
