import test from 'node:test'
import assert from 'node:assert/strict'
import { asClient } from './helpers.ts'
import { getDashboardSummary } from '../src/api/dashboard.ts'

const summary = {
  stats: { published_word_prompts: 2, published_question_prompts: 3, active_categories: 4, drafts: 5 },
  recent: [], drafts: [],
  warnings: { empty_categories: 0, duplicate_questions: 1, non_family_easy_prompts: 2 },
}

test('dashboard summary calls the RPC and returns its payload unchanged', async () => {
  const calls: unknown[][] = []
  const client = asClient({ rpc: async (...args: unknown[]) => { calls.push(args); return { data: summary } } })
  assert.equal(await getDashboardSummary(client), summary)
  assert.deepEqual(calls, [['admin_dashboard_summary']])
})

test('dashboard summary propagates RPC errors unchanged', async () => {
  const error = { code: '42501', message: 'forbidden' }
  const client = asClient({ rpc: async () => ({ data: null, error }) })
  await assert.rejects(getDashboardSummary(client), caught => caught === error)
})
