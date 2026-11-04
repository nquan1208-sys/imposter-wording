import { testWindow } from './helpers.ts'

import test from 'node:test'
import assert from 'node:assert/strict'
import { readFile, readdir } from 'node:fs/promises'
import { createI18n } from 'vue-i18n'
import { categoryError, categoryPayload, gameTypeLabels } from '../src/utils/categories.ts'
import { adminAuthError } from '../src/utils/adminAuth.ts'
import { confirmDiscard } from '../src/utils/unsavedChanges.ts'

import vn from '../src/i18n/locales/vn.json'
import en from '../src/i18n/locales/en.json'
import { readUiLocale, persistUiLocale } from '../src/i18n/index.ts'
function flatten(messages: object, prefix = ''): Record<string, string> {
  return Object.fromEntries(Object.entries(messages).flatMap(([key, value]) => {
    assert.match(key, /^[a-z][a-zA-Z0-9]*$/)
    const path = prefix ? `${prefix}.${key}` : key
    if (typeof value === 'string') {
      assert.ok(value.trim(), path)
      return [[path, value]]
    }
    assert.ok(value && typeof value === 'object' && !Array.isArray(value), path)
    return Object.entries(flatten(value, path))
  }))
}
const viKeys = flatten(vn)
const enKeys = flatten(en)
const placeholders = (text: string) => [...text.matchAll(/\{([a-z][a-zA-Z0-9]*)\}/g)].map(match => match[1]).sort()

test('dictionary keys match, values are nonempty and placeholders agree', () => {
  assert.deepEqual(Object.keys(enKeys).sort(), Object.keys(viKeys).sort())
  for (const [key, value] of Object.entries(enKeys)) {
    assert.ok(Object.hasOwn(viKeys, key), key)
    assert.deepEqual(placeholders(value), placeholders(viKeys[key]), key)
  }
})

test('every message compiles in both locales without fallback', () => {
  const i18n = createI18n({ legacy: false, locale: 'en', fallbackLocale: 'vi', messages: { vi: vn, en }, missingWarn: false, fallbackWarn: false })
  assert.equal(i18n.global.t('categories.fields.name'), 'Category name')
  for (const locale of ['vi', 'en'] as const) {
    i18n.global.locale.value = locale
    for (const [key, value] of Object.entries(viKeys)) {
      const params = Object.fromEntries(placeholders(value).map(name => [name, 'test']))
      assert.notEqual(i18n.global.t(key, params), key)
    }
  }
  assert.equal(categoryPayload({ name: 'Food', slug: 'food', game_type: 'word', sort_order: 0, is_active: true, status: 'draft', locale: 'vi' }).locale, 'vi')
})

async function sources(directory: URL): Promise<[URL, string][]> {
  const entries = await readdir(directory, { withFileTypes: true })
  const groups = await Promise.all(entries.map(async (entry): Promise<[URL, string][]> => {
    const path = new URL(entry.name + (entry.isDirectory() ? '/' : ''), directory)
    if (entry.isDirectory()) return sources(path)
    return /\.(ts|vue)$/.test(entry.name) ? [[path, await readFile(path, 'utf8')]] : []
  }))
  return groups.flat()
}

test('literal translations, route metadata and dynamic key maps exist in Vietnamese', async () => {
  for (const [path, source] of await sources(new URL('../src/', import.meta.url))) {
    for (const match of source.matchAll(/\bt\(\s*['"]([^'"]+)['"]|(?:titleKey|descriptionKey):\s*['"]([^'"]+)['"]|['"]((?:common|auth|categories|navigation|dashboard|wordPrompts|questionPrompts|placeholder)\.[a-zA-Z0-9.]+)['"]/g)) {
      const key = match[1] || match[2] || match[3]
      if (key.endsWith('.')) { assert.ok(Object.keys(viKeys).some(value => value.startsWith(key)), key); continue }
      assert.ok(Object.hasOwn(viKeys, key), `${path.pathname}: ${key}`)
    }
  }
  for (const key of Object.values(gameTypeLabels)) assert.ok(Object.hasOwn(viKeys, key), key)
})

test('errors use stable keys and leave backend messages untouched', () => {
  for (const [code, key] of Object.entries({ '23505': 'categories.errors.slugExists', '42501': 'common.errors.forbidden', '23514': 'categories.errors.invalidData', '22023': 'categories.errors.invalidData', PGRST116: 'categories.errors.notFound' })) {
    const error = Object.freeze({ code, message: 'Backend diagnostic' })
    assert.equal(categoryError(error), key)
    assert.equal(error.message, 'Backend diagnostic')
  }
  assert.equal(categoryError({ message: 'unknown backend text' }), 'common.errors.operationFailed')
  assert.equal(categoryError(new Error('categories.errors.nameRequired')), 'categories.errors.nameRequired')
  assert.equal(categoryError(new Error('common.errors.sessionExpired')), 'common.errors.sessionExpired')
  assert.equal(adminAuthError(new Error('auth.errors.adminRequired')), 'auth.errors.adminRequired')
  for (const [code, key] of Object.entries({ invalid_credentials: 'auth.errors.invalidCredentials', email_not_confirmed: 'auth.errors.emailNotConfirmed', over_request_rate_limit: 'auth.errors.rateLimited', over_email_send_rate_limit: 'auth.errors.rateLimited' })) assert.equal(adminAuthError({ code }), key)
  assert.equal(adminAuthError({ message: 'auth.errors.invalidCredentials' }), 'auth.errors.loginFailed')
})

test('discard confirmation forwards the translated message and cancellation', () => {
  const original = globalThis.window
  try {
    globalThis.window = testWindow({ confirm: message => { assert.equal(message, vn.common.confirmations.discardChanges); return false } })
    assert.equal(confirmDiscard(vn.common.confirmations.discardChanges), false)
    globalThis.window.confirm = () => true
    assert.equal(confirmDiscard('Discard changes?'), true)
  } finally { globalThis.window = original }
})


test('UI language preference validates stored values and tolerates unavailable storage', () => {
  const previous = Object.getOwnPropertyDescriptor(globalThis, 'localStorage')
  let stored: string | null = null
  try {
    Object.defineProperty(globalThis, 'localStorage', { configurable: true, value: {
      getItem: (key: string) => { assert.equal(key, 'admin-ui-locale'); return stored },
      setItem: (key: string, value: string) => { assert.equal(key, 'admin-ui-locale'); stored = value },
    } })
    assert.equal(readUiLocale(), 'vi')
    persistUiLocale('en'); assert.equal(readUiLocale(), 'en')
    persistUiLocale('fr'); assert.equal(readUiLocale(), 'en')
    persistUiLocale('vi'); assert.equal(readUiLocale(), 'vi')
    stored = 'fr'; assert.equal(readUiLocale(), 'vi')
    Object.defineProperty(globalThis, 'localStorage', { configurable: true, get() { throw new Error('blocked') } })
    assert.equal(readUiLocale(), 'vi')
    assert.doesNotThrow(() => persistUiLocale('en'))
  } finally {
    if (previous) Object.defineProperty(globalThis, 'localStorage', previous)
    else Reflect.deleteProperty(globalThis, 'localStorage')
  }
})
