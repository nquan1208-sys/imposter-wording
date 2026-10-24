import type { SupabaseClient } from '@supabase/supabase-js'
import type { Database } from './database.ts'
import type { z } from 'zod'
import type { wordPromptSchema } from '../utils/wordPrompts.ts'
import type { questionPromptSchema } from '../utils/questionPrompts.ts'
type Functions = Database['public']['Functions']
// PostgreSQL accepts explicit null; generated RPC types omit argument nullability.
export type AdminDatabase = Omit<Database, 'public'> & { public: Omit<Database['public'], 'Functions'> & { Functions: Omit<Functions, 'delete_category' | 'save_category' | 'admin_list_categories'> & {
  delete_category: { Args: { p_id: string; p_mode: string; p_target_id?: string | null; p_expected_version?: string | null }; Returns: undefined }
  save_category: { Args: Omit<Functions['save_category']['Args'], 'p_description' | 'p_expected_updated_at'> & { p_description: string | null; p_expected_updated_at: string | null }; Returns: Functions['save_category']['Returns'] }
  admin_list_categories: { Args: Omit<Functions['admin_list_categories']['Args'], 'p_game_type' | 'p_is_active'> & { p_game_type: Category['game_type'] | null; p_is_active: boolean | null }; Returns: Functions['admin_list_categories']['Returns'] }
} } }
export type AdminClient = SupabaseClient<AdminDatabase>
export type Category = Database['public']['Tables']['game_categories']['Row']
export type CategoryTranslation = Database['public']['Tables']['game_category_translations']['Row']
export type ContentLanguage = Database['public']['Tables']['content_languages']['Row']
export type CategoryDetail = Category & { translations: CategoryTranslation[] }
export type CategoryRow = CategoryDetail & { name: string | null; word_count: number; question_count: number }
export type CategoryOption = Pick<Category, 'id' | 'is_active'> & { name: string; locale: string }
export type CategoryTarget = Pick<Category, 'id' | 'slug'> & { name: string | null }
export type CategoryForm = Pick<Category, 'slug' | 'game_type' | 'is_active'> & { name: string; description: string; locale: string; status: Database['public']['Enums']['content_status']; sort_order: string | number }
export type SavedCategory = { original: Category; translation: CategoryTranslation }
export type PromptStatus = Database['public']['Enums']['content_status']
export type WordForm = z.input<typeof wordPromptSchema>
export type QuestionForm = z.input<typeof questionPromptSchema>
export type PromptCategory = Omit<CategoryOption, 'locale'> & { locale?: string }
export type WordRow = Database['public']['Tables']['word_prompts']['Row'] & { game_categories?: PromptCategory | null }
export type QuestionRow = Database['public']['Tables']['question_prompts']['Row'] & { game_categories?: PromptCategory | null }
export type DeletePrompt = { id: string; updatedAt: string }
export type SavePrompt = { id: string; status: PromptStatus; updatedAt?: string }
export type SaveWord = SavePrompt & { file?: File | null; onUpload?: (state: 'uploading' | 'uploaded' | 'failed') => void }
export type CategoryPreview = { category: Category; category_translations: CategoryTranslation[]; counts: { originals: { total: number; word: number; question: number }; translations: Record<PromptStatus, number> }; version: string }
export type DeleteCategory = { id: string; mode: string; targetId?: string; version?: string }
export function errorFields(error: unknown): { message: string; code: string } {
  if (!error || typeof error !== 'object') return { message: '', code: '' }
  return { message: 'message' in error && typeof error.message === 'string' ? error.message : '', code: 'code' in error && typeof error.code === 'string' ? error.code : '' }
}
