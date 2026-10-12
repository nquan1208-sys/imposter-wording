import { inject, provide, reactive } from 'vue'
const unsavedKey = Symbol('unsaved-category-changes')
export function provideUnsavedChanges() {
  const state = reactive({ dirty: false, busy: false })
  provide(unsavedKey, state)
  return state
}
export function useUnsavedChanges() { return inject(unsavedKey) }
export function confirmDiscard() { return window.confirm('Bạn có thay đổi chưa lưu. Bạn muốn bỏ các thay đổi này?') }
