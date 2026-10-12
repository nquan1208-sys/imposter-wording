import { createApp } from 'vue'
import { VueQueryPlugin } from '@tanstack/vue-query'
import ui from '@nuxt/ui/vue-plugin'
import './styles/index.css'
import App from './App.vue'
import router from './router'

createApp(App).use(VueQueryPlugin).use(router).use(ui).mount('#app')
