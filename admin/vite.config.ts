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
      }] },
      checkbox: { slots: { icon: 'tw:text-(--color-charcoal)' } },
      breadcrumb: { compoundVariants: [{ color: 'primary', active: true, class: { link: 'tw:text-(--color-charcoal)' } }] },
    },
    experimental: { componentDetection: true },
  })],
})
