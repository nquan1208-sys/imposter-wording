import { inject, provide, reactive } from 'vue'
import type { InjectionKey } from 'vue'
type UnsavedState = { dirty: boolean; busy: boolean }
const unsavedKey: InjectionKey<UnsavedState> = Symbol('unsaved-category-changes')
export function provideUnsavedChanges() {
  const state = reactive({ dirty: false, busy: false })
  provide(unsavedKey, state)
  return state
}
export function useUnsavedChanges() { const state = inject(unsavedKey); if (!state) throw new Error('Missing unsaved changes provider'); return state }
export function confirmDiscard(message: string) { return window.confirm(message) }
