import type { SupabaseClient } from '@supabase/supabase-js'
import type { Database } from './database.ts'
import type { z } from 'zod'
import type { wordPromptSchema } from '../utils/wordPrompts.ts'
import type { questionPromptSchema } from '../utils/questionPrompts.ts'
// PostgreSQL accepts explicit null for these default-null RPC arguments; CLI types omit that nullability.
export type AdminDatabase = Omit<Database, 'public'> & { public: Omit<Database['public'], 'Functions'> & { Functions: Omit<Database['public']['Functions'], 'delete_category'> & {
  delete_category: { Args: { p_id: string; p_mode: string; p_target_id?: string | null; p_expected_version?: string | null }; Returns: undefined }
} } }
export type AdminClient = SupabaseClient<AdminDatabase>
export type Category = Database['public']['Tables']['game_categories']['Row']
export type CategoryRow = Category & { word_prompts: { count: number }[]; question_prompts: { count: number }[] }
export type CategoryOption = Pick<Category, 'id' | 'name' | 'locale' | 'is_active'>
export type CategoryTarget = Pick<Category, 'id' | 'name' | 'slug'>
export type CategoryForm = Pick<Category, 'name' | 'slug' | 'game_type' | 'locale' | 'is_active'> & { description: string; sort_order: string | number }
export type PromptStatus = Database['public']['Enums']['content_status']
export type WordForm = z.input<typeof wordPromptSchema>
export type QuestionForm = z.input<typeof questionPromptSchema>
export type PromptCategory = Omit<CategoryOption, 'locale'> & { locale?: string }
export type WordRow = Database['public']['Tables']['word_prompts']['Row'] & { game_categories?: PromptCategory | null }
export type QuestionRow = Database['public']['Tables']['question_prompts']['Row'] & { game_categories?: PromptCategory | null }
export type DeletePrompt = { id: string; updatedAt: string }
export type SavePrompt = { id: string; status: PromptStatus; updatedAt?: string }
export type SaveWord = SavePrompt & { file?: File | null; onUpload?: (state: 'uploading' | 'uploaded' | 'failed') => void }
export type CategoryPreview = { category: Category; counts: Record<PromptStatus, number>; version: string }
export type DeleteCategory = { id: string; mode: string; targetId?: string; version?: string }
export function errorFields(error: unknown): { message: string; code: string } {
  if (!error || typeof error !== 'object') return { message: '', code: '' }
  return { message: 'message' in error && typeof error.message === 'string' ? error.message : '', code: 'code' in error && typeof error.code === 'string' ? error.code : '' }
}
