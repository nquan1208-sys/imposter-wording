/// <reference types="vite/client" />
import 'vue-router'
declare module 'vue-router' {
  interface RouteMeta { titleKey?: string; descriptionKey?: string; adminShell?: boolean }
}
declare global {
  interface ImportMetaEnv { readonly VITE_SUPABASE_URL: string; readonly VITE_SUPABASE_PUBLISHABLE_KEY: string }
}
