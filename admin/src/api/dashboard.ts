import type { AdminClient } from '../types/admin.ts'

export type DashboardItem = {
  id: string
  game_type: 'word' | 'question'
  locale: string
  title: string
  category_name: string | null
  status: 'draft' | 'published' | 'archived'
  updated_at: string
}

export type DashboardSummary = {
  stats: {
    published_word_prompts: number
    published_question_prompts: number
    active_categories: number
    drafts: number
  }
  recent: DashboardItem[]
  drafts: DashboardItem[]
  warnings: {
    empty_categories: number
    duplicate_questions: number
  }
}

export async function getDashboardSummary(client: AdminClient, locale = 'vi'): Promise<DashboardSummary> {
  const { data, error } = await client.rpc('admin_dashboard_summary', { p_locale: locale })
  if (error) throw error
  return data as DashboardSummary
}
