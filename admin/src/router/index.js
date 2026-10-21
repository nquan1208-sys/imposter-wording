import { createRouter, createWebHistory } from "vue-router";
import AdminShell from "../components/admin/AdminShell.vue";
import { supabase } from "../lib/supabase.js";
import { getAdminSession } from "../utils/adminAuth.js";

const routes = [
  {
    path: "/login",
    name: "login",
    component: () => import("../views/login/LoginView.vue"),
    meta: { titleKey: "auth.login.routeTitle" },
  },
  {
    path: "/",
    component: AdminShell,
    meta: { adminShell: true },
    children: [
      { path: "", redirect: { name: "dashboard" } },
      {
        path: "dashboard",
        name: "dashboard",
        component: () => import("../views/dashboard/DashboardView.vue"),
        meta: {
          titleKey: "dashboard.title",
          descriptionKey: "dashboard.description",
        },
      },
      {
        path: "categories",
        name: "categories",
        component: () => import("../views/categories/CategoriesView.vue"),
        meta: {
          titleKey: "categories.title",
          descriptionKey: "categories.description",
        },
      },
      { path: "categories/new", name: "category-new", component: () => import("../views/categories/CategoryFormView.vue"), meta: { titleKey: "categories.actions.create" } },
      { path: "categories/:id/edit", name: "category-edit", component: () => import("../views/categories/CategoryFormView.vue"), meta: { titleKey: "categories.form.editTitle" } },
      {
        path: "word-prompts",
        name: "word-prompts",
        component: () => import("../views/word-prompts/WordPromptsView.vue"),
        meta: {
          titleKey: "wordPrompts.title",
          descriptionKey: "wordPrompts.description",
        },
      },
      { path: "word-prompts/new", name: "word-prompt-new", component: () => import("../views/word-prompts/WordPromptFormView.vue"), meta: { titleKey: "wordPrompts.actions.create" } },
      { path: "word-prompts/:id/edit", name: "word-prompt-edit", component: () => import("../views/word-prompts/WordPromptFormView.vue"), meta: { titleKey: "wordPrompts.actions.edit" } },
      { path: "question-prompts/new", name: "question-prompt-new", component: () => import("../views/question-prompts/QuestionPromptFormView.vue"), meta: { titleKey: "questionPrompts.actions.create" } },
      { path: "question-prompts/:id/edit", name: "question-prompt-edit", component: () => import("../views/question-prompts/QuestionPromptFormView.vue"), meta: { titleKey: "questionPrompts.actions.edit" } },
      {
        path: "question-prompts",
        name: "question-prompts",
        component: () => import("../views/question-prompts/QuestionPromptsView.vue"),
        meta: {
          titleKey: "questionPrompts.title",
          descriptionKey: "questionPrompts.description",
        },
      },
    ],
  },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
  scrollBehavior: () => ({ top: 0 }),
});

router.beforeEach(async (to) => {
  if (!to.matched.some((record) => record.meta.adminShell)) return true;
  if (await getAdminSession(supabase)) return true;
  return { name: "login", query: { redirect: to.fullPath } };
});

export default router;
