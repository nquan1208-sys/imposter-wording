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

- [x] Tạo Supabase project.
- [x] Lưu Project URL.
- [x] Lấy Publishable key.
- [x] Không sử dụng `service_role` hoặc Secret key trong frontend.
- [x] Vào `Authentication → Providers` và bật Email/Password.
- [x] Quyết định có bật email confirmation hay không.

### Kết quả cần có

```text
SUPABASE_URL
SUPABASE_PUBLISHABLE_KEY
```

Project Development hiện tại là `imposter-word`, ref
`pxycsjwjakzehcuygngv`. Credential được lưu trong
`admin/.env.development.local` và không commit vào Git.

---

## Phase 2 — Khởi tạo Supabase trong repository

### Thực hiện trong code

- [x] Cài Supabase CLI nếu máy chưa có.
- [x] Chạy `supabase init` tại thư mục gốc repository.
- [x] Chạy `supabase migration new initial_schema`.
- [x] Kiểm tra thư mục `supabase/migrations/`.

Expected structure:

```text
supabase/
├── config.toml
└── migrations/
    ├── 20261003072606_initial_schema.sql
    └── 20261003072909_rls_and_policies.sql
```

Hai migration được tạo bằng Supabase CLI: migration đầu tiên chứa schema,
migration thứ hai chứa RLS và policies.

### Lưu ý

- DBML chỉ để vẽ sơ đồ, không chạy trực tiếp.
- Không tạo bảng `auth_users` thật.
- Supabase đã quản lý sẵn bảng `auth.users`.

---

## Phase 3 — Viết database schema migration

### Các enum cần tạo

- [x] `game_type`: `word`, `question`.
- [x] `content_status`: `draft`, `published`, `archived`.
- [x] `difficulty_level`: `easy`, `medium`, `hard`.

### Các bảng cần tạo

- [x] `public.admin_users`.
- [x] `public.game_categories`.
- [x] `public.word_prompts`.
- [x] `public.question_prompts`.

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

Schema đã có trong `20261003072606_initial_schema.sql`. Ngoài các enum
trên, migration tạo `admin_role`, index cho các query chính và trigger kiểm
tra category của prompt phải khớp `game_type`.

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

- [x] Tạo `private.is_admin()`.
- [x] Function kiểm tra `auth.uid()` với `public.admin_users`.
- [x] Function dùng `SECURITY DEFINER` an toàn và `search_path = ''`.
- [x] Không expose function này như public API.

### Bật RLS

- [x] Bật RLS cho `admin_users`.
- [x] Bật RLS cho `game_categories`.
- [x] Bật RLS cho `word_prompts`.
- [x] Bật RLS cho `question_prompts`.

### Public app policies

- [x] `anon` được đọc category đang active.
- [x] `anon` được đọc word prompt có `status = published`.
- [x] `anon` được đọc question prompt có `status = published`.
- [x] `anon` không được insert, update hoặc delete.

### Admin policies

- [x] Admin được đọc toàn bộ content.
- [x] Admin được tạo content.
- [x] Admin được cập nhật content.
- [x] Admin được archive content.
- [x] User đã login nhưng không có trong `admin_users` không được thao tác.

RLS và policies nằm trong `20261003072909_rls_and_policies.sql`. Function
`private.is_admin()` bị revoke khỏi `public`, chỉ được cấp execute cho role
`authenticated`; schema `private` cũng không nằm trong Data API schemas.

---

## Phase 5 — Test migration local

> Không dùng Phase 5 làm gate của workflow hiện tại. Migration local đã từng
> được reset/apply để kiểm tra SQL, nhưng các kiểm tra hành vi local được bỏ qua;
> workflow tiếp tục trực tiếp trên project Dev ở Phase 6.

```bash
supabase start
supabase db reset
```

- [x] Migration chạy thành công từ đầu bằng `supabase db reset --local`.
- [x] Tất cả bảng được tạo.
- [x] RLS được bật.
- [x] Không có lỗi foreign key.
- [x] Không có lỗi policy/function.

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
supabase link --project-ref pxycsjwjakzehcuygngv
supabase db push --linked
```

- [x] Link repository với project Dev `pxycsjwjakzehcuygngv`.
- [x] Kiểm tra dry-run trước khi push.
- [x] Push hai migration lên project Dev.
- [x] Kiểm tra migration đã applied trên project thật.
- [x] Kiểm tra bốn bảng trong database Dev.
- [x] Kiểm tra RLS policies bằng Supabase CLI.
- [ ] Bật Leaked Password Protection trong Auth settings của project Dev.

---

## Phase 7 — Tạo admin đầu tiên

### Tạo Auth user local để test trước (tạm bỏ qua)

Đang tạm bỏ qua bước local để test trực tiếp trên project Dev. User local nếu
tạo sau này chỉ tồn tại trong Supabase local và không dùng được để đăng nhập
project Dev.

```bash
supabase start
```

- [ ] Mở Supabase Studio local tại `http://127.0.0.1:54323`.
- [ ] Vào `Authentication → Users` → `Add user`.
- [ ] Tạo email/password test, ví dụ `admin.local@example.com`.
- [ ] Bật `Auto Confirm` để đăng nhập ngay.
- [ ] Copy UUID của user local.
- [ ] Trong SQL Editor local, chạy câu lệnh dưới đây để gán quyền admin:

```sql
insert into public.admin_users (user_id, role, is_active)
select id, 'admin', true
from auth.users
where email = 'admin.local@example.com'
on conflict (user_id) do update
set role = 'admin',
    is_active = true;
```

Chạy Admin bằng `yarn dev:local`, sau đó dùng email/password local để test
login, route guard và quyền RLS. Không dùng password test hoặc UUID local
trong migration/repository.

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

- [x] Tạo file script với email placeholder, không chứa password hoặc secret.

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
