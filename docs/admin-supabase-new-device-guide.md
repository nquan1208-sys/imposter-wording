# Guide chạy dự án trên thiết bị mới

Hợp đồng Family Mode hiện hành và quy trình nâng cấp local: [Family Mode theo danh mục](family-mode.md).
Tài liệu này hướng dẫn thiết lập repository `imposter-wording` trên một máy
mới, bao gồm:

- Admin Vue/Vite trong thư mục `admin/`.
- Database, Auth, RLS và migration của Supabase trong thư mục `supabase/`.
- Hai cách kết nối Supabase: project Dev trên cloud hoặc Supabase local.

Guide này được viết dựa trên `docs/admin-supabase-setup-plan.md` và trạng thái
thực tế của repository.

> **Trạng thái 2026-10-24:** local đã có login, route guard, CRUD đa ngôn ngữ,
> dashboard và bucket private `word-prompt-images`. Dev cloud đang INACTIVE và
> chưa triển khai bộ migrations translations. Dùng local trước; không push cloud
> theo quickstart khi chưa làm [quy trình cutover](./plans/admin-content-translations/admin-content-translations-phase-6.md).

## 1. Chọn cách chạy

### Cách A — Dev cloud, sau khi hoàn tất cutover

Chọn cách này nếu mục tiêu là chạy code Admin trên máy mới và dùng chung
database Dev hiện tại.

- Không cần Docker.
- Không cần `supabase start`.
- Cần quyền truy cập Supabase project Dev và Publishable key.
- Dữ liệu thao tác trên cloud là dữ liệu dùng chung, nên không dùng để thử
  những migration hoặc dữ liệu có tính phá huỷ.

### Cách B — Supabase local, đầy đủ và an toàn hơn

Chọn cách này khi cần kiểm tra migration/RLS hoặc muốn thử dữ liệu riêng trên
máy.

- Cần Docker Desktop, OrbStack hoặc runtime tương thích Docker.
- Cần Supabase CLI.
- Dữ liệu local độc lập với project Dev cloud.

Hiện tại dùng **Cách B** để mở Admin. Cách A chỉ dùng sau khi Dev hoạt động và schema đã tương thích.

### Lộ trình Dev cloud — chỉ sau cutover

Sau khi cài Git, Node.js và Yarn, các lệnh chính là:

```bash
git clone <REPOSITORY_URL>
cd imposter-wording

cd admin
yarn install --frozen-lockfile
cp .env.example .env.development.local
# Mở .env.development.local và điền Project URL + Publishable key

cd ..
supabase login
supabase link --project-ref pxycsjwjakzehcuygngv
supabase migration list --linked
# Nếu còn migration pending: thực hiện quy trình cutover, không push trực tiếp.

cd admin
yarn dev:development
```

Chỉ chạy `yarn dev:development` khi Dev đã hoạt động và ledger khớp schema admin mới.

## 2. Những thứ cần chuẩn bị

### 2.1. Công cụ bắt buộc

Kiểm tra các công cụ đã có:

```bash
git --version
node --version
npm --version
yarn --version
```

Khuyến nghị:

- Node.js 20 trở lên.
- Yarn `1.22.22`, đúng với `packageManager` trong `admin/package.json`.
- Git.

Nếu máy chưa có Yarn 1.22.22, có thể cài bằng Corepack:

```bash
corepack enable
corepack prepare yarn@1.22.22 --activate
yarn --version
```

Nếu `corepack` không có trên máy, dùng npm:

```bash
npm install --global yarn@1.22.22
yarn --version
```

### 2.2. Công cụ chỉ cần cho Supabase local

`supabase start` chạy nhiều service bằng container. Cài và mở một trong các
lựa chọn sau:

- macOS: OrbStack hoặc Docker Desktop.
- Windows/Linux: Docker Desktop, Rancher Desktop hoặc Podman tương thích
  Docker API.

Kiểm tra Docker daemon:

```bash
docker --version
docker info
```

Nếu `docker info` báo không kết nối được daemon, hãy mở Docker Desktop hoặc
OrbStack rồi chạy lại lệnh.

Cài Supabase CLI trên macOS bằng Homebrew:

```bash
brew install supabase/tap/supabase
supabase --version
```

Nếu không muốn cài global, có thể dùng CLI qua `npx` với Node.js 20 trở lên:

```bash
npx supabase --version
```

Trong phần còn lại, các lệnh được viết bằng `supabase`. Nếu dùng cách `npx`,
đổi tương ứng, ví dụ:

```bash
npx supabase start
npx supabase db push
```

## 3. Clone repository trên máy mới

Thay `<REPOSITORY_URL>` bằng URL Git thật của repository:

```bash
git clone <REPOSITORY_URL>
cd imposter-wording
git status
```

Nếu repository yêu cầu SSH và máy mới chưa có SSH key, có thể kiểm tra remote:

```bash
git remote -v
```

Kiểm tra các file quan trọng đã có:

```bash
test -f admin/package.json && echo "admin/package.json: OK"
test -f supabase/config.toml && echo "supabase/config.toml: OK"
test -d supabase/migrations && echo "supabase/migrations: OK"
```

Không cần chạy `supabase init` trên máy mới. Thư mục `supabase/` và
`config.toml` đã được commit trong repository; chạy `supabase init` lần nữa có
thể làm thay đổi cấu hình hiện có.

## 4. Cài dependency cho Admin

Từ thư mục gốc repository:

```bash
cd admin
yarn install --frozen-lockfile
```

Lệnh này cài đúng các package theo `admin/yarn.lock`, gồm Vue, Vite và
`@supabase/supabase-js`.

Kiểm tra package đã được cài:

```bash
yarn --version
test -d node_modules && echo "node_modules: OK"
```

Quay lại thư mục gốc khi cần chạy lệnh Supabase:

```bash
cd ..
pwd
```

## 5. Tạo file environment cho Admin

Các file `*.local` không được commit. Mỗi mode của Vite dùng một file riêng:

| Mục đích | Vite mode | File | Supabase target |
| --- | --- | --- | --- |
| Local | `localdev` | `admin/.env.local` | Supabase local |
| Development | `development` | `admin/.env.development.local` | Project Dev cloud |
| Production | `production` | `admin/.env.production.local` | Chưa cấu hình |

Frontend chỉ được dùng hai biến sau:

```env
VITE_SUPABASE_URL=...
VITE_SUPABASE_PUBLISHABLE_KEY=...
```

Không đưa các giá trị sau vào file `VITE_*`:

- `service_role key`.
- Secret key.
- Database password.
- JWT secret.

Các biến `VITE_*` được bundle vào browser. RLS là lớp bảo vệ chính cho các
request từ frontend.

### 5.1. Cấu hình Dev cloud

Copy file mẫu:

```bash
cd admin
cp .env.example .env.development.local
```

Mở file bằng editor bất kỳ:

```bash
nano .env.development.local
```

Điền:

```env
VITE_SUPABASE_URL=https://pxycsjwjakzehcuygngv.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=<PUBLISHABLE_KEY_LẤY_TỪ_SUPABASE_DASHBOARD>
```

Lấy key tại Supabase Dashboard của project `imposter-word`:

1. Mở project `imposter-word`.
2. Vào **Project Settings → API** hoặc **Connect**.
3. Copy **Publishable key**.
4. Dán vào `VITE_SUPABASE_PUBLISHABLE_KEY`.

Không copy `service_role` hoặc Secret key.

Kiểm tra file tồn tại nhưng không in key ra terminal:

```bash
test -s .env.development.local && echo "Dev env file: OK"
```

### 5.2. Cấu hình Supabase local

Chưa cần tạo file này trước khi `supabase start`, vì local key được CLI in ra
sau khi stack khởi động. Trước hết quay về root và khởi động local stack theo
phần 6. Sau đó lấy `API URL` và `anon key` từ `supabase status`.

Tạo file:

```bash
cd admin
cp .env.example .env.local
nano .env.local
```

Điền URL local:

```env
VITE_SUPABASE_URL=http://127.0.0.1:54321
VITE_SUPABASE_PUBLISHABLE_KEY=<ANON_KEY_DO_SUPABASE_STATUS_IN_RA>
```

Với local stack, CLI thường gọi key dùng cho frontend là `anon key`. Dùng
key đó ở biến `VITE_SUPABASE_PUBLISHABLE_KEY`; không dùng `service_role key`.

## 6. Cách B — Dựng Supabase local

Thực hiện từ thư mục gốc `imposter-wording`.

### 6.1. Khởi động stack

```bash
cd /path/to/imposter-wording
supabase start
```

Lần đầu chạy có thể mất vài phút vì CLI tải các Docker image. Khi thành công,
kiểm tra trạng thái:

```bash
supabase status
```

Các giá trị quan trọng:

- API URL: thường là `http://127.0.0.1:54321`.
- Studio URL: thường là `http://127.0.0.1:54323`.
- Mailpit URL: thường là `http://127.0.0.1:54324`.
- `anon key`: dùng cho `admin/.env.local`.

Mở Supabase Studio local:

```text
http://127.0.0.1:54323
```

Nếu repository có migration, Supabase sẽ dùng các file trong
`supabase/migrations/`. Kiểm tra lịch sử migration local:

```bash
supabase migration list
```

### 6.2. Reset database local từ migration

Chỉ chạy lệnh này khi chấp nhận xoá toàn bộ database local:

```bash
supabase db reset --local
```

Lệnh sẽ xoá database local, chạy lại các migration theo thứ tự thời gian và
chạy seed nếu repository có seed file. Không chạy lệnh này trên project cloud.

Kiểm tra nhanh các bảng sau khi reset bằng Supabase Studio hoặc SQL Editor:

```sql
select table_name
from information_schema.tables
where table_schema = 'public'
  and table_name in (
    'admin_users',
    'game_categories',
    'word_prompts',
    'question_prompts',
    'content_languages',
    'game_category_translations',
    'word_prompt_translations',
    'question_prompt_translations'
  )
order by table_name;
```

Kiểm tra RLS:

```sql
select schemaname, tablename, rowsecurity
from pg_tables
where schemaname = 'public'
  and tablename in (
    'admin_users',
    'game_categories',
    'word_prompts',
    'question_prompts',
    'content_languages',
    'game_category_translations',
    'word_prompt_translations',
    'question_prompt_translations'
  )
order by tablename;
```

`rowsecurity` cần là `true` cho cả tám bảng.

### 6.3. Tạo admin user local để test

User local chỉ tồn tại trong Supabase local. User này không đăng nhập được vào
project Dev cloud.

Có thể mở Studio local:

```text
http://127.0.0.1:54323
```

Sau đó:

1. Vào **Authentication → Users**.
2. Chọn **Add user**.
3. Nhập email/password test.
4. Bật **Auto Confirm** nếu muốn đăng nhập ngay.
5. Ghi lại email của user.

Trong SQL Editor local, chạy:

```sql
insert into public.admin_users (user_id, role, is_active)
select id, 'admin', true
from auth.users
where email = 'admin.local@example.com'
on conflict (user_id) do update
set role = 'admin',
    is_active = true;
```

Thay `admin.local@example.com` bằng email vừa tạo. Kiểm tra:

```sql
select au.user_id, u.email, au.role, au.is_active
from public.admin_users au
join auth.users u on u.id = au.user_id;
```

### 6.4. Chạy Admin với local stack

Mở terminal thứ hai, để terminal chạy `supabase start` tiếp tục hoạt động:

```bash
cd /path/to/imposter-wording/admin
yarn dev:local
```

Mở URL Vite in ra terminal, thường là:

```text
http://localhost:5173
```

Nếu bị thiếu biến môi trường, kiểm tra đúng mode và đúng tên file:

- `yarn dev:local` đọc `.env.local`.
- `yarn dev:development` đọc `.env.development.local`.

### 6.5. Dừng và chạy lại local stack

Dừng stack nhưng giữ dữ liệu local:

```bash
cd /path/to/imposter-wording
supabase stop
```

Chạy lại:

```bash
supabase start
```

Muốn xoá dữ liệu local và dựng lại từ migration:

```bash
supabase db reset --local
```

## 7. Cách A — Kết nối project Dev cloud

### 7.1. Đăng nhập Supabase CLI

Từ thư mục gốc:

```bash
cd /path/to/imposter-wording
supabase login
```

CLI sẽ mở trình duyệt hoặc yêu cầu access token. Dùng tài khoản có quyền truy
cập project `imposter-word`.

Kiểm tra project có thể nhìn thấy:

```bash
supabase projects list
```

### 7.2. Link repository với project Dev

Project ref hiện tại là `pxycsjwjakzehcuygngv`:

```bash
supabase link --project-ref pxycsjwjakzehcuygngv
```

CLI có thể hỏi database password của project. Đây là database password của
Supabase project, không phải Publishable key. Không lưu password vào Git hoặc
file `VITE_*`.

Kiểm tra migration local và cloud:

```bash
supabase migration list --linked
```

### 7.3. Áp dụng migration lên Dev

Chỉ chạy bước này trong cửa sổ cutover sau backup và rehearsal theo [Phase 6](./plans/admin-content-translations/admin-content-translations-phase-6.md). Danh sách dry-run đúng chưa đủ để bỏ qua backup hoặc khóa ghi.

Trước tiên xem trước thay đổi:

```bash
supabase db push --linked --dry-run
```

Nếu danh sách migration đúng, áp dụng:

```bash
supabase db push --linked
```

Kiểm tra lại:

```bash
supabase migration list --linked
```

Có thể mở Supabase Dashboard → **Table Editor** để xác nhận tám bảng:

- `admin_users`
- `game_categories`
- `word_prompts`
- `question_prompts`
- `content_languages`
- `game_category_translations`
- `word_prompt_translations`
- `question_prompt_translations`

Không cần chạy `supabase start` khi làm việc với Dev cloud.

### 7.4. Tạo admin user trên Dev cloud

Thực hiện trong Supabase Dashboard của project Dev:

1. Vào **Authentication → Users**.
2. Chọn **Add user**.
3. Nhập email và password của admin.
4. Bật **Auto Confirm** nếu chưa cấu hình email confirmation.
5. Tạo user.

Tiếp theo vào **SQL Editor** và chạy câu lệnh sau. Thay email mẫu bằng email
admin thật:

```sql
insert into public.admin_users (user_id, role, is_active)
select id, 'admin', true
from auth.users
where email = 'admin@example.com'
on conflict (user_id) do update
set role = 'admin',
    is_active = true;
```

Kiểm tra bản ghi admin:

```sql
select au.user_id, u.email, au.role, au.is_active
from public.admin_users au
join auth.users u on u.id = au.user_id
where u.email = 'admin@example.com';
```

Có thể dùng file mẫu `supabase/scripts/grant_admin.sql`, nhưng file này chỉ
chứa email placeholder. Không ghi password hoặc secret vào file đó.

### 7.5. Chạy Admin với Dev cloud

Đảm bảo đã tạo `admin/.env.development.local`, sau đó:

```bash
cd /path/to/imposter-wording/admin
yarn dev:development
```

Mở URL Vite in ra terminal. Admin sẽ gọi API của:

```text
https://pxycsjwjakzehcuygngv.supabase.co
```

Nếu muốn build thử:

```bash
yarn build:development
```

Build được tạo trong `admin/dist/`. Đây chỉ là frontend bundle; lệnh build
không deploy website và cũng không push database.

## 8. Những gì migration hiện tại tạo ra

Migration trong repository tạo các enum:

- `game_type`: `word`, `question`.
- `content_status`: `draft`, `published`, `archived`.
- `difficulty_level`: `easy`, `medium`, `hard`.
- `admin_role`: `admin`.

Các bảng chính:

- `admin_users`: quyền admin của user Auth.
- `content_languages`: mã, tên và thứ tự ngôn ngữ; ban đầu `vi`, `en`.
- `game_categories`, `word_prompts`, `question_prompts`: thông tin chung của bản gốc.
- `game_category_translations`, `word_prompt_translations`, `question_prompt_translations`: nội dung và trạng thái riêng từng locale; khóa ghép ID gốc + locale.

Danh mục giữ slug duy nhất theo `game_type`; ảnh, độ khó và nhãn gia đình thuộc đề gốc.
Không fallback nội dung sang locale khác. Ngôn ngữ nội dung độc lập locale giao diện.
Thêm ngôn ngữ bằng dữ liệu `content_languages` qua quyền quản trị DB; chưa có UI quản lý ngôn ngữ.

RLS và quyền API:

- Public chỉ đọc bản dịch `published`; đề còn cần danh mục đang bật và bản dịch danh mục cùng locale đã xuất bản.
- Bản gốc chỉ public khi có ít nhất một bản dịch đủ điều kiện.
- Admin active đọc toàn bộ nội dung; ghi qua các RPC save/delete/toggle/transfer có kiểm tra quyền và phiên bản, không ghi bảng trực tiếp từ client.
- Lưu chỉ cập nhật phần chung và bản dịch đang chọn trong một transaction. Version cũ trả `PT409`; phải tải lại trước khi ghi tiếp.
- User đăng nhập không có quyền admin active không được ghi.

Migration không tạo `auth_users`; Supabase đã quản lý `auth.users`.

## 9. Quy trình hằng ngày

### 9.1. Làm việc với local

Terminal 1:

```bash
cd /path/to/imposter-wording
supabase start
```

Terminal 2:

```bash
cd /path/to/imposter-wording/admin
yarn dev:local
```

### 9.2. Làm việc với Dev cloud

Không chạy local stack:

```bash
cd /path/to/imposter-wording/admin
yarn dev:development
```

### 9.3. Khi thay đổi database

Tạo migration mới từ thư mục gốc:

```bash
cd /path/to/imposter-wording
supabase migration new ten_thay_doi
```

Sau khi viết SQL, kiểm tra bằng rehearsal trên bản sao dùng một lần; không reset DB đang giữ dữ liệu:

```bash
rtk proxy python3 supabase/tests/content_translations.py
```

Xem trước và push lên Dev:

```bash
supabase migration list --linked
# Nếu còn migration pending: thực hiện quy trình cutover, không push trực tiếp.
```

Sau khi migration đã push lên Dev, không sửa file migration cũ. Tạo migration
mới cho thay đổi tiếp theo, để lịch sử local và cloud không bị lệch.

### 9.4. Kiểm tra code trước khi bàn giao

```bash
cd /path/to/imposter-wording/admin
yarn build:development
```

Nếu chỉ sửa frontend thì không cần `supabase db push`. Chỉ push khi có thay
đổi migration, RLS, function, trigger hoặc cấu hình database cần triển khai.

## 10. Production

Production chưa được cấu hình trong kế hoạch hiện tại. Không tự ý dùng project
Dev làm production.

Khi có production project, tạo file local nhưng không commit:

```bash
cd /path/to/imposter-wording/admin
cp .env.example .env.production.local
nano .env.production.local
```

Điền URL và Publishable key của production project, sau đó build:

```bash
yarn build:production
```

Trước khi dùng production cần hoàn thành tối thiểu:

- Production Supabase project.
- Auth provider và policy phù hợp.
- Migration đã được kiểm tra và push đúng project.
- Admin user production.
- Storage bucket private `word-prompt-images` và các policies trong migrations.
- Hosting cho `admin/dist/`.

File `admin/.env.production` đang để trống có chủ ý, nhằm tránh build
production tự động dùng nhầm `.env.local`.

## 11. Storage ảnh từ ngữ

Bucket private `word-prompt-images` đã được tạo bằng migration. Ảnh dùng chung giữa các bản dịch;
đường dẫn là `<prompt-uuid>/<file-uuid>.jpg|png|webp`, tối đa 5 MiB.
Admin active upload và cleanup theo policy; không tạo bucket public thay thế.
Ảnh chỉ được cấp quyền đọc mới khi đề có ít nhất một bản dịch công khai hợp lệ.
Signed URL đã cấp còn hiệu lực tới hết hạn. Xóa đề giữ bytes và chặn truy cập mới;
upload/save thất bại dọn ảnh mới theo quy trình editor.

Chạy `cd admin && yarn test:storage` với local stack để kiểm tra Storage HTTP.
DB dump chứa metadata Storage, không chứa bytes ảnh; xem quy trình backup ở báo cáo Phase 6.

## 12. Chạy Flutter app (tuỳ chọn)

Phần Supabase Admin ở trên không thay thế việc cài Flutter. Nếu cần chạy app
mobile trong thư mục `app/`, kiểm tra Flutter/Dart:

```bash
flutter --version
dart --version
```

Sau đó:

```bash
cd /path/to/imposter-wording/app
flutter pub get
flutter test
flutter run
```

App Flutter hiện tại là phần riêng của repository và `pubspec.yaml` chưa có
`supabase_flutter`; setup plan Admin/Supabase chưa kết nối app này vào
Supabase.

## 13. Checklist hoàn tất trên máy mới

- [ ] `git clone` thành công.
- [ ] Node.js và Yarn hoạt động.
- [ ] `cd admin && yarn install --frozen-lockfile` thành công.
- [ ] Chọn đúng mode: `localdev` hoặc `development`.
- [ ] Tạo đúng file `.env.*.local`.
- [ ] Chỉ dùng Project URL và Publishable/anon key ở frontend.
- [ ] Nếu dùng local: Docker/OrbStack đang chạy và `supabase status` thành công.
- [ ] Nếu dùng cloud: `supabase login` và `supabase link` thành công.
- [ ] Migration đã được kiểm tra bằng `supabase migration list`.
- [ ] Nếu dùng Dev cloud: đã chạy `supabase db push --linked` khi cần.
- [ ] Admin Auth user đã được tạo.
- [ ] Admin user đã có bản ghi trong `public.admin_users`.
- [ ] `yarn dev:local` hoặc `yarn dev:development` mở được Vite.
- [ ] `yarn build:development` chạy thành công.
- [ ] Không có secret/password nào được commit.

## 14. Xử lý lỗi thường gặp

### `yarn: command not found`

Cài Yarn 1.22.22:

```bash
corepack enable
corepack prepare yarn@1.22.22 --activate
yarn --version
```

### `Missing VITE_SUPABASE_URL...`

Kiểm tra:

```bash
cd /path/to/imposter-wording/admin
ls -la .env*
```

Đảm bảo:

- `yarn dev:local` có `.env.local`.
- `yarn dev:development` có `.env.development.local`.
- Tên biến viết đúng chính tả.
- Sau khi sửa env, dừng và chạy lại Vite.

### `supabase start` không chạy được

Kiểm tra Docker daemon:

```bash
docker info
supabase status
```

Nếu Docker đang chạy nhưng bị xung đột port, kiểm tra các port trong
`supabase/config.toml`, đặc biệt `54320`, `54321`, `54322`, `54323` và `54324`.
Không đổi port tuỳ tiện nếu chưa cập nhật URL trong `admin/.env.local`.

### `supabase link` yêu cầu database password

Dùng database password của project Dev. Không dùng Publishable key, anon key
hoặc service key. Nếu không có password, người có quyền quản trị project cần
đặt lại/lấy lại database password trong Supabase Dashboard.

### Đăng nhập được nhưng không có quyền admin

Kiểm tra user có tồn tại trong Auth và bản ghi ánh xạ:

```sql
select au.user_id, u.email, au.role, au.is_active
from public.admin_users au
join auth.users u on u.id = au.user_id
where u.email = 'admin@example.com';
```

Kết quả cần có:

- `role = 'admin'`.
- `is_active = true`.

Nếu chưa có, chạy lại câu lệnh `insert into public.admin_users` ở phần tạo
admin user. User local và user cloud là hai user khác nhau.

### `db push` báo không có migration pending

Đây thường là đúng: tất cả migration local đã có trên cloud. Kiểm tra:

```bash
supabase migration list --linked
```

Chỉ tạo migration mới khi thực sự có thay đổi database.

### Admin chạy được nhưng lỗi schema/RPC

Kiểm tra đúng environment và migration ledger. Admin mới cần toàn bộ migrations translations,
bao gồm migration conflict `20261024093556`; không chạy admin cũ với schema mới.
Không dùng reset để xử lý trên DB có dữ liệu cần giữ.

## 15. Tài liệu tham khảo

- [Supabase CLI: cài đặt và local development](https://supabase.com/docs/guides/local-development/cli/getting-started)
- [Supabase local development workflow](https://supabase.com/docs/guides/local-development/cli-workflows)
- [Supabase database migrations](https://supabase.com/docs/guides/local-development/database-migrations)
- [Vite env variables and modes](https://vite.dev/guide/env-and-mode)


