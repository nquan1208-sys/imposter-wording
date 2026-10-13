import { inject, provide, reactive } from 'vue'
const unsavedKey = Symbol('unsaved-category-changes')
export function provideUnsavedChanges() {
  const state = reactive({ dirty: false, busy: false })
  provide(unsavedKey, state)
  return state
}
export function useUnsavedChanges() { return inject(unsavedKey) }
export function confirmDiscard(message) { return window.confirm(message) }
