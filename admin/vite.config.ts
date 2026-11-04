import vue from '@vitejs/plugin-vue'
import { defineConfig } from 'vite'
import ui from '@nuxt/ui/vite'

// https://vite.dev/config/
export default defineConfig({
  plugins: [vue(), ui({
    theme: { prefix: 'tw', defaultVariants: { size: 'lg' } },
    ui: {
      colors: { primary: 'yellow', neutral: 'zinc' },
      button: { compoundVariants: [{
        color: 'primary', variant: 'solid',
        class: 'tw:text-(--color-charcoal) tw:hover:bg-(--color-primary-hover) tw:active:bg-(--color-primary-active)',
      }, {
        color: 'neutral', variant: 'outline',
        class: 'tw:bg-(--color-white) tw:text-(--color-charcoal) tw:ring-(--color-gray-400) tw:hover:bg-(--color-gray-100)',
      }, {
        color: 'error', variant: 'outline',
        class: 'tw:bg-(--color-white) tw:text-(--color-error) tw:ring-(--color-error) tw:hover:bg-(--color-error-surface)',
      }, {
        color: 'error', variant: 'solid',
        class: 'tw:bg-(--color-error) tw:text-white tw:hover:bg-(--color-coral-active)',
      }] },
      checkbox: { slots: { icon: 'tw:text-(--color-charcoal)' } },
      breadcrumb: { compoundVariants: [{ color: 'primary', active: true, class: { link: 'tw:text-(--color-charcoal)' } }] },
    },
    experimental: { componentDetection: true },
  })],
})
