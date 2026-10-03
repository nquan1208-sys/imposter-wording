# Plan: Setup Admin với Supabase

## Mục tiêu

Xây dựng Admin Vue để:

- Đăng nhập bằng Supabase Auth.
- Quản lý danh mục.
- Quản lý content trò chơi từ ngữ.
- Quản lý content trò chơi câu hỏi.
- Publish, archive và lọc content theo Family Mode.
- Upload ảnh cho content từ ngữ.
- Sử dụng Supabase Data REST API thông qua `@supabase/supabase-js`.

## Phạm vi hiện tại

- Người chơi không đăng nhập.
- Tên người chơi, câu trả lời, vote và game state lưu local trong app.
- Admin là nhóm user duy nhất sử dụng Supabase Auth.
- MVP không có sidebar `Admin users` hoặc `Cài đặt`.
- Sidebar Admin gồm:
  - Tổng quan.
  - Danh mục.
  - Nội dung từ ngữ.
  - Nội dung câu hỏi.
  - Đăng xuất.

## Tài liệu liên quan

- Database diagram: `docs/database-schema.dbml`
- Screen layout: `docs/app/screen-layout.md`
- Admin app: `admin/`
- Environment guide: `docs/admin-supabase-environment-guide.md`

---

## Phase 0 — Thiết lập environment cho Admin (local/dev/prod)

Admin là Vue 3 chạy bằng Vite, vì vậy app đọc biến môi trường qua
`import.meta.env`. Vite nạp file theo mode; `localdev` là mode tùy chỉnh, còn
`development` và `production` là mode chuẩn.

### Quy ước môi trường

| Môi trường | Vite mode | File local | Supabase target | Trạng thái |
| --- | --- | --- | --- | --- |
| Local | `localdev` | `admin/.env.local` | Supabase CLI local stack | Đã điền |
| Dev | `development` | `admin/.env.development.local` | Project `imposter-word`, ref `pxycsjwjakzehcuygngv` | Đã điền |
| Prod | `production` | `admin/.env.production.local` | Production project | Chưa cấu hình |

Các file `*.local` không commit vào Git. File mẫu được commit là
`admin/.env.example`. `admin/.env.production` là file guard rỗng được commit
để build production không fallback nhầm vào `.env.local` khi project prod chưa
có.

### Các biến được phép dùng trong frontend

```env
VITE_SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxx
```

`VITE_*` được Vite bundle vào browser. Publishable key được phép dùng ở
frontend khi RLS và quyền Data API được cấu hình đúng. Không đặt
`service_role`, Supabase secret key, database password hoặc JWT secret vào
bất kỳ file `VITE_*` nào.

### Lệnh chạy/build

```bash
cd admin
yarn dev:local           # local, mode localdev
yarn dev:development     # dev cloud, mode development
yarn build:production    # prod, mode production
```

- [x] Tạo `admin/.env.local` với local URL và local publishable key.
- [x] Tạo `admin/.env.development.local` với dev URL và publishable key.
- [x] Thêm script Vite cho ba mode.
- [x] Thêm `admin/.env.example`.
- [ ] Tạo và điền `admin/.env.production.local` sau khi có project prod.

---

## Phase 1 — Tạo Supabase project

### Thực hiện trên Supabase Dashboard

- [ ] Tạo Supabase project.
- [ ] Lưu Project URL.
- [ ] Lấy Publishable key.
- [ ] Không sử dụng `service_role` hoặc Secret key trong frontend.
- [ ] Vào `Authentication → Providers` và bật Email/Password.
- [ ] Quyết định có bật email confirmation hay không.

### Kết quả cần có

```text
SUPABASE_URL
SUPABASE_PUBLISHABLE_KEY
```

---

## Phase 2 — Khởi tạo Supabase trong repository

### Thực hiện trong code

- [ ] Cài Supabase CLI nếu máy chưa có.
- [x] Chạy `supabase init` tại thư mục gốc repository.
- [ ] Chạy `supabase migration new initial_schema`.
- [ ] Kiểm tra thư mục `supabase/migrations/`.

Expected structure:

```text
supabase/
├── config.toml
└── migrations/
    └── <timestamp>_initial_schema.sql
```

### Lưu ý

- DBML chỉ để vẽ sơ đồ, không chạy trực tiếp.
- Không tạo bảng `auth_users` thật.
- Supabase đã quản lý sẵn bảng `auth.users`.

---

## Phase 3 — Viết database schema migration

### Các enum cần tạo

- [ ] `game_type`: `word`, `question`.
- [ ] `content_status`: `draft`, `published`, `archived`.
- [ ] `difficulty_level`: `easy`, `medium`, `hard`.

### Các bảng cần tạo

- [ ] `public.admin_users`.
- [ ] `public.game_categories`.
- [ ] `public.word_prompts`.
- [ ] `public.question_prompts`.

### Field quan trọng

`admin_users`:

- `user_id` → foreign key đến `auth.users.id`.
- `role`.
- `is_active`.

`game_categories`:

- `game_type`.
- `slug`.
- `name`.
- `locale`.
- `is_active`.
- `sort_order`.

`word_prompts`:

- `category_id`.
- `civilian_text`.
- `imposter_text`.
- `imposter_hint`.
- `image_path`.
- `difficulty`.
- `is_family_friendly`.
- `status`.

`question_prompts`:

- `category_id`.
- `civilian_question`.
- `imposter_question`.
- `imposter_hint`.
- `difficulty`.
- `is_family_friendly`.
- `status`.

---

## Phase 4 — Thiết lập RLS và quyền truy cập

### Function kiểm tra admin

- [ ] Tạo `private.is_admin()`.
- [ ] Function kiểm tra `auth.uid()` với `public.admin_users`.
- [ ] Function dùng `SECURITY DEFINER` an toàn và `search_path = ''`.
- [ ] Không expose function này như public API.

### Bật RLS

- [ ] Bật RLS cho `admin_users`.
- [ ] Bật RLS cho `game_categories`.
- [ ] Bật RLS cho `word_prompts`.
- [ ] Bật RLS cho `question_prompts`.

### Public app policies

- [ ] `anon` được đọc category đang active.
- [ ] `anon` được đọc word prompt có `status = published`.
- [ ] `anon` được đọc question prompt có `status = published`.
- [ ] `anon` không được insert, update hoặc delete.

### Admin policies

- [ ] Admin được đọc toàn bộ content.
- [ ] Admin được tạo content.
- [ ] Admin được cập nhật content.
- [ ] Admin được archive content.
- [ ] User đã login nhưng không có trong `admin_users` không được thao tác.

---

## Phase 5 — Test migration local

```bash
supabase start
supabase db reset
```

- [ ] Migration chạy thành công từ đầu.
- [ ] Tất cả bảng được tạo.
- [ ] RLS được bật.
- [ ] Không có lỗi foreign key.
- [ ] Không có lỗi policy/function.

### Kiểm tra nhanh

- [ ] Anonymous chỉ đọc được content published.
- [ ] Anonymous không ghi được content.
- [ ] Admin đọc được draft.
- [ ] Admin tạo và sửa được content.
- [ ] Non-admin authenticated user bị từ chối.

---

## Phase 6 — Đẩy schema lên Supabase Cloud

```bash
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase db push
```

- [ ] Kiểm tra migration đã applied trên project thật.
- [ ] Kiểm tra các bảng trong Table Editor.
- [ ] Kiểm tra RLS trong Authentication/Data API.

---

## Phase 7 — Tạo admin đầu tiên

### Tạo Auth user trên Dashboard

- [ ] Vào `Authentication → Users`.
- [ ] Chọn `Add user`.
- [ ] Tạo email/password admin.
- [ ] Bật Auto Confirm nếu cần đăng nhập ngay.
- [ ] Copy email hoặc UUID của user.

### Gán quyền admin

Tạo file:

```text
supabase/scripts/grant_admin.sql
```

Nội dung:

```sql
-- Chạy sau khi Auth user đã tồn tại.
insert into public.admin_users (user_id, role, is_active)
select id, 'admin', true
from auth.users
where email = 'admin@example.com'
on conflict (user_id) do update
set role = 'admin',
    is_active = true;
```

- [ ] Thay email bằng email admin thật.
- [ ] Chạy script một lần trong Supabase SQL Editor.
- [ ] Kiểm tra user có role `admin` và `is_active = true`.

### Không làm

- [ ] Không lưu password trong repository.
- [ ] Không insert trực tiếp password vào `auth.users`.
- [ ] Không đưa service key vào script frontend.
- [ ] Không đặt thao tác gán admin vào migration schema.

---

## Phase 8 — Kết nối Vue Admin

### Cài package

```bash
cd admin
yarn add @supabase/supabase-js
```

### Tạo biến môi trường

Phần setup ba môi trường đã được thực hiện ở Phase 0. Khi viết Supabase
client, dùng các biến giống nhau ở cả ba mode:

```env
VITE_SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxx
```

- [x] Các file `*.local` đã được `admin/.gitignore` bỏ qua.
- [x] Không dùng secret/service key trong frontend.

### Tạo Supabase client

Tạo file:

```text
admin/src/lib/supabase.js
```

- [ ] Khởi tạo `createClient()`.
- [ ] Đọc URL và publishable key từ `import.meta.env`.

---

## Phase 9 — Authentication và route guard

### Login

- [ ] Tạo màn hình `/login`.
- [ ] Login bằng `supabase.auth.signInWithPassword()`.
- [ ] Hiển thị lỗi sai email/password.
- [ ] Sau khi login, query `admin_users`.
- [ ] Nếu không phải admin, sign out và hiển thị lỗi.

### Route guard

Bảo vệ các route:

```text
/dashboard
/categories
/word-prompts
/question-prompts
```

- [ ] Chưa login → chuyển về `/login`.
- [ ] Không phải admin → không được vào admin pages.
- [ ] Refresh trang vẫn giữ session hợp lệ.
- [ ] Nút Đăng xuất gọi `supabase.auth.signOut()`.

---

## Phase 10 — Xây các màn hình Admin

### Dashboard

- [ ] Tổng số word prompts published.
- [ ] Tổng số question prompts published.
- [ ] Tổng số category active.
- [ ] Tổng số content draft.

### Categories

- [ ] Danh sách category.
- [ ] Tạo category.
- [ ] Sửa category.
- [ ] Bật/tắt category.
- [ ] Hiển thị số content Classic và Family.

### Word prompts

- [ ] Danh sách word prompts.
- [ ] Lọc theo category, difficulty, status, Family Mode.
- [ ] Tạo/sửa prompt.
- [ ] Upload ảnh.
- [ ] Preview ảnh.
- [ ] Lưu draft.
- [ ] Publish.
- [ ] Archive.

### Question prompts

- [ ] Danh sách question prompts.
- [ ] Lọc theo category, difficulty, status, Family Mode.
- [ ] Nhập civilian question.
- [ ] Nhập imposter question.
- [ ] Validate hai câu hỏi không giống nhau.
- [ ] Lưu draft.
- [ ] Publish.
- [ ] Archive.

---

## Phase 11 — Storage cho ảnh từ ngữ

- [ ] Tạo bucket `game-content`.
- [ ] Quyết định bucket public hoặc signed URL.
- [ ] Tạo Storage policies cho admin upload/update/delete.
- [ ] Cho phép app người chơi đọc ảnh published.
- [ ] Lưu `image_path` vào `word_prompts`.
- [ ] Không lưu service key trong app.

---

## Phase 12 — Data API queries

Các query chính:

```js
supabase
  .from('game_categories')
  .select('*')
  .eq('is_active', true)
  .order('sort_order')
```

```js
supabase
  .from('word_prompts')
  .select('*')
  .eq('status', 'published')
```

Family Mode:

```js
query = query.eq('is_family_friendly', true)
```

Category filter:

```js
query = query.in('category_id', selectedCategoryIds)
```

- [ ] Không chọn category → random trong toàn bộ content hợp lệ.
- [ ] Có chọn category → chỉ random trong category đã chọn.
- [ ] Family Mode → thêm `is_family_friendly = true`.
- [ ] App chỉ nhận content published.

---

## Phase 13 — Verification checklist

- [ ] Admin login thành công.
- [ ] Non-admin bị chặn.
- [ ] Admin logout thành công.
- [ ] Anonymous không sửa được content.
- [ ] Anonymous chỉ đọc content published.
- [ ] Admin tạo category thành công.
- [ ] Admin tạo word prompt thành công.
- [ ] Admin upload ảnh thành công.
- [ ] Admin tạo question prompt thành công.
- [ ] Draft không xuất hiện trong app người chơi.
- [ ] Archive không xuất hiện trong app người chơi.
- [ ] Family Mode chỉ lấy content có `is_family_friendly = true`.
- [ ] Chọn nhiều category lọc đúng content.
- [ ] Không chọn category random đúng toàn bộ tập content.
- [ ] `service_role` không xuất hiện trong frontend hoặc Git.

## Definition of Done

- [ ] Migration nằm trong `supabase/migrations/` và chạy được từ đầu.
- [ ] Schema Cloud khớp với migration trong repository.
- [ ] RLS đã được bật và kiểm thử.
- [ ] Có admin Auth user và bản ghi tương ứng trong `admin_users`.
- [ ] Admin Vue login/logout hoạt động.
- [ ] Admin CRUD được categories và hai loại content.
- [ ] App người chơi chỉ đọc được content published.
- [ ] Family Mode và category filtering hoạt động đúng.
- [ ] Ảnh word prompt upload và hiển thị được.
