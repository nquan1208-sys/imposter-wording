import { createRouter, createWebHistory } from "vue-router";
import AdminShell from "../components/admin/AdminShell.vue";
import LoginView from "../views/login/LoginView.vue";
import DashboardView from "../views/dashboard/DashboardView.vue";
import CategoriesView from "../views/categories/CategoriesView.vue";
import WordPromptsView from "../views/word-prompts/WordPromptsView.vue";
import QuestionPromptsView from "../views/question-prompts/QuestionPromptsView.vue";

const routes = [
  {
    path: "/login",
    name: "login",
    component: LoginView,
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
        component: DashboardView,
        meta: {
          title: "Tổng quan",
          description:
            "Theo dõi nhanh tình trạng nội dung và các việc cần xử lý.",
        },
      },
      {
        path: "categories",
        name: "categories",
        component: CategoriesView,
        meta: {
          title: "Danh mục",
          description: "Quản lý các danh mục cho trò chơi từ ngữ và câu hỏi.",
        },
      },
      {
        path: "word-prompts",
        name: "word-prompts",
        component: WordPromptsView,
        meta: {
          title: "Nội dung từ ngữ",
          description: "Quản lý các cặp từ bí mật cho trò chơi từ ngữ.",
        },
      },
      {
        path: "question-prompts",
        name: "question-prompts",
        component: QuestionPromptsView,
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

export default router;
