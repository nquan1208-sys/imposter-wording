<script setup lang="ts">
import type { Category } from '../../../src/types/admin.ts'
import CategoryDeleteDialog from '../../../src/components/categories/CategoryDeleteDialog.vue'
import WordDeleteDialog from '../../../src/components/word-prompts/WordDeleteDialog.vue'
const params = new URLSearchParams(location.search)
const word = params.has('word')
const mobile = params.has('mobile')
const previewPath = location.pathname
const category: Category = { id: 'preview', slug: 'do-an', game_type: 'word', is_active: true, sort_order: 0, created_by: null, created_at: '2026-10-21T00:00:00Z', updated_at: '2026-10-21T00:00:00Z' }
const prompt = { id: 'preview', text: 'Quả táo', category_id: 'preview', translations: [], game_categories: { slug: 'food', locale: 'vi', id: category.id, name: 'Đồ ăn và thức uống', is_active: true }, status: 'published' as const, difficulty: 'medium' as const, is_family_friendly: true, locale: 'vi', image_path: null, created_by: null, created_at: category.created_at, updated_at: category.updated_at }
</script>
<template>
<div v-if="mobile" style="padding:16px;background:#ddd;min-height:100vh"><iframe :src="`${previewPath}?${word ? 'word' : ''}`" style="width:390px;height:844px;border:0" /></div>
<UApp v-else>
<WordDeleteDialog v-if="word" :prompt="prompt" />
<CategoryDeleteDialog v-else :locale="'vi'" :preview="{category,category_translations:[],counts:{originals:{total:30,word:30,question:0},translations:{draft:12,published:24,archived:3}},version:'snapshot'}" :targets="[{...category,id:'target',name:'Món ăn'}]" />
</UApp>
</template>
