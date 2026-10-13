import { createI18n } from 'vue-i18n'
import vn from './locales/vn.json'
import en from './locales/en.json'

export const i18n = createI18n({
  legacy: false,
  locale: 'vi',
  fallbackLocale: 'vi',
  messages: { vi: vn, en },
})
