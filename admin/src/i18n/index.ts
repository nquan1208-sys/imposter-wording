import { createI18n } from 'vue-i18n'
import vn from './locales/vn.json'
import en from './locales/en.json'

export function readUiLocale(): 'vi' | 'en' {
  try { return localStorage.getItem('admin-ui-locale') === 'en' ? 'en' : 'vi' }
  catch { return 'vi' }
}

export function persistUiLocale(locale: string) {
  if (locale !== 'vi' && locale !== 'en') return
  try { localStorage.setItem('admin-ui-locale', locale) }
  catch { /* Storage may be unavailable; the selected language still works for this session. */ }
}

export const i18n = createI18n({
  legacy: false,
  locale: readUiLocale(),
  fallbackLocale: 'vi',
  messages: { vi: vn, en },
})
