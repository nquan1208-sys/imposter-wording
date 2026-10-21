import {createApp} from 'vue'
import ui from '@nuxt/ui/vue-plugin'
import '../../../src/styles/index.css'
import {i18n} from '../../../src/i18n/index.js'
import Preview from './App.vue'
createApp(Preview).use(ui).use(i18n).mount('#app')
