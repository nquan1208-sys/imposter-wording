<script setup lang="ts">
import type { Category, WordRow } from '../../../src/types/admin.ts'
import CategoryDeleteDialog from '../../../src/components/categories/CategoryDeleteDialog.vue'
import WordDeleteDialog from '../../../src/components/word-prompts/WordDeleteDialog.vue'
const params = new URLSearchParams(location.search)
const word = params.has('word')
const mobile = params.has('mobile')
const previewPath = location.pathname
const category: Category = { id: 'preview', name: 'Đồ ăn và thức uống', slug: 'do-an', game_type: 'word', locale: 'vi', is_active: true, description: null, sort_order: 0, created_by: null, created_at: '2026-10-21T00:00:00Z', updated_at: '2026-10-21T00:00:00Z' }
const prompt: WordRow = { id: 'preview', text: 'Quả táo', category_id: 'preview', game_categories: category, status: 'published', difficulty: 'medium', is_family_friendly: true, locale: 'vi', image_path: null, created_by: null, created_at: category.created_at, updated_at: category.updated_at }
</script>
<template>
<div v-if="mobile" style="padding:16px;background:#ddd;min-height:100vh"><iframe :src="`${previewPath}?${word ? 'word' : ''}`" style="width:390px;height:844px;border:0" /></div>
<UApp v-else>
<WordDeleteDialog v-if="word" :prompt="prompt" />
<CategoryDeleteDialog v-else :preview="{category,counts:{draft:12,published:24,archived:3},version:'snapshot'}" :targets="[{...category,id:'target',name:'Món ăn'}]" />
</UApp>
</template>
