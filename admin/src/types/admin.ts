import type { SupabaseClient } from '@supabase/supabase-js'
import type { Database } from './database.ts'
import type { z } from 'zod'
import type { wordPromptSchema } from '../utils/wordPrompts.ts'
import type { questionPromptSchema } from '../utils/questionPrompts.ts'
type Functions = Database['public']['Functions']
// PostgreSQL accepts explicit null; generated RPC types omit argument nullability.
export type AdminDatabase = Omit<Database, 'public'> & { public: Omit<Database['public'], 'Functions'> & { Functions: Omit<Functions, 'delete_category' | 'save_category' | 'admin_list_categories' | 'save_word_prompt' | 'save_question_prompt' | 'admin_list_word_prompts' | 'admin_list_question_prompts'> & {
  delete_category: { Args: { p_id: string; p_mode: string; p_target_id?: string | null; p_expected_version?: string | null }; Returns: undefined }
  save_category: { Args: Omit<Functions['save_category']['Args'], 'p_description' | 'p_expected_updated_at'> & { p_description: string | null; p_expected_updated_at: string | null }; Returns: Functions['save_category']['Returns'] }
  admin_list_categories: { Args: Omit<Functions['admin_list_categories']['Args'], 'p_game_type' | 'p_is_active'> & { p_game_type: Category['game_type'] | null; p_is_active: boolean | null }; Returns: Functions['admin_list_categories']['Returns'] }
  save_word_prompt: { Args: Omit<Functions['save_word_prompt']['Args'], 'p_expected_updated_at' | 'p_image_path'> & { p_expected_updated_at: string | null; p_image_path: string | null }; Returns: Functions['save_word_prompt']['Returns'] }
  admin_list_word_prompts: { Args: Omit<Functions['admin_list_word_prompts']['Args'], 'p_category_id' | 'p_difficulty' | 'p_is_family_friendly' | 'p_status'> & { p_category_id: string | null; p_difficulty: Database['public']['Enums']['difficulty_level'] | null; p_is_family_friendly: boolean | null; p_status: PromptStatus | null }; Returns: Functions['admin_list_word_prompts']['Returns'] }
  save_question_prompt: { Args: Omit<Functions['save_question_prompt']['Args'], 'p_expected_updated_at'> & { p_expected_updated_at: string | null }; Returns: Functions['save_question_prompt']['Returns'] }
  admin_list_question_prompts: { Args: Omit<Functions['admin_list_question_prompts']['Args'], 'p_category_id' | 'p_difficulty' | 'p_is_family_friendly' | 'p_status'> & { p_category_id: string | null; p_difficulty: Database['public']['Enums']['difficulty_level'] | null; p_is_family_friendly: boolean | null; p_status: PromptStatus | null }; Returns: Functions['admin_list_question_prompts']['Returns'] }
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
export type PromptCategory = Pick<Category, 'id' | 'slug' | 'is_active'> & { name: string | null; locale: string; translations?: CategoryTranslation[] }
export type WordOriginal = Database['public']['Tables']['word_prompts']['Row']
export type QuestionOriginal = Database['public']['Tables']['question_prompts']['Row']
export type WordTranslation = Database['public']['Tables']['word_prompt_translations']['Row']
export type QuestionTranslation = Database['public']['Tables']['question_prompt_translations']['Row']
export type WordRow = WordOriginal & { text: string | null; locale: string; status: PromptStatus | null; translations: WordTranslation[]; game_categories?: PromptCategory | null }
export type QuestionRow = QuestionOriginal & { civilian_question: string | null; imposter_question: string | null; locale: string; status: PromptStatus | null; translations: QuestionTranslation[]; game_categories?: PromptCategory | null }
export type WordDetail = WordOriginal & { translations: WordTranslation[]; game_categories: (Category & { translations: CategoryTranslation[] }) | null }
export type QuestionDetail = QuestionOriginal & { translations: QuestionTranslation[]; game_categories: (Category & { translations: CategoryTranslation[] }) | null }
export type SavedWord = { original: WordOriginal; translation: WordTranslation }
export type SavedQuestion = { original: QuestionOriginal; translation: QuestionTranslation }
export type DeletePrompt = { id: string; updatedAt: string }
export type SavePrompt = { id: string; status: PromptStatus; updatedAt?: string }
export type SaveWord = SavePrompt & { file?: File | null; onUpload?: (state: 'uploading' | 'uploaded' | 'failed') => void }
export type CategoryPreview = { category: Category; category_translations: CategoryTranslation[]; counts: { originals: { total: number; word: number; question: number }; translations: Record<PromptStatus, number> }; version: string }
export type DeleteCategory = { id: string; mode: string; targetId?: string; version?: string }
export function errorFields(error: unknown): { message: string; code: string } {
  if (!error || typeof error !== 'object') return { message: '', code: '' }
  return { message: 'message' in error && typeof error.message === 'string' ? error.message : '', code: 'code' in error && typeof error.code === 'string' ? error.code : '' }
}
