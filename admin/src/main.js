import { createApp } from 'vue'
import { VueQueryPlugin } from '@tanstack/vue-query'
import ui from '@nuxt/ui/vue-plugin'
import './styles/index.css'
import App from './App.vue'
import router from './router'
import { i18n } from './i18n/index.js'

createApp(App).use(VueQueryPlugin).use(i18n).use(router).use(ui).mount('#app')
