import { createRouter, createWebHistory } from "vue-router";
import AdminShell from "../components/admin/AdminShell.vue";
import { supabase } from "../lib/supabase.js";
import { getAdminSession } from "../utils/adminAuth.js";

const routes = [
  {
    path: "/login",
    name: "login",
    component: () => import("../views/login/LoginView.vue"),
    meta: { title: "Đăng nhập" },
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
          title: "Tổng quan",
          description:
            "Theo dõi nhanh tình trạng nội dung và các việc cần xử lý.",
        },
      },
      {
        path: "categories",
        name: "categories",
        component: () => import("../views/categories/CategoriesView.vue"),
        meta: {
          title: "Danh mục",
          description: "Quản lý các danh mục cho trò chơi từ ngữ và câu hỏi.",
        },
      },
      { path: "categories/new", name: "category-new", component: () => import("../views/categories/CategoryFormView.vue"), meta: { title: "Thêm danh mục" } },
      { path: "categories/:id/edit", name: "category-edit", component: () => import("../views/categories/CategoryFormView.vue"), meta: { title: "Sửa danh mục" } },
      {
        path: "word-prompts",
        name: "word-prompts",
        component: () => import("../views/word-prompts/WordPromptsView.vue"),
        meta: {
          title: "Nội dung từ ngữ",
          description: "Quản lý các cặp từ bí mật cho trò chơi từ ngữ.",
        },
      },
      {
        path: "question-prompts",
        name: "question-prompts",
        component: () => import("../views/question-prompts/QuestionPromptsView.vue"),
        meta: {
          title: "Nội dung câu hỏi",
          description: "Quản lý các câu hỏi dành cho civilian và imposter.",
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
