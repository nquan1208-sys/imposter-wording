# Hướng dẫn môi trường Admin và Supabase

Tài liệu này hướng dẫn chạy Admin Vue với ba môi trường:

- Local: Supabase chạy trên máy.
- Development: Supabase cloud project dùng chung cho Dev.
- Production: Supabase cloud project thật, chưa cấu hình.

## 1. Các file environment

Các file nằm trong thư mục `admin/`:

```text
admin/.env.local                  # Supabase local
admin/.env.development.local      # Supabase cloud Dev
admin/.env.production.local       # Supabase cloud Production
admin/.env.production             # file guard, đang để trống
admin/.env.example                # file mẫu
```

`*.local` là file riêng trên máy và đã được Git ignore. Hậu tố `.local`
không có nghĩa là Supabase local; ví dụ `.env.development.local` là file
credential Dev cloud trên máy cá nhân.

Mỗi file cần có:

```env
VITE_SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxx
```

Chỉ dùng `Project URL` và `Publishable key` lấy từ Supabase Dashboard →
Connect. Không dùng các giá trị sau trong Vue frontend:

```text
service_role key
secret key
database password
JWT secret
```

`VITE_*` được bundle vào browser, nên publishable key phải đi kèm RLS và
quyền Data API đúng.

### Giá trị hiện tại

- Local URL: `http://127.0.0.1:54321`.
- Dev project: `imposter-word`.
- Dev project ref: `pxycsjwjakzehcuygngv`.
- Production: chưa có project/credential.

## 2. Chạy Admin với Local Supabase

Mở terminal thứ nhất ở thư mục gốc repository:

```bash
cd /Users/nguyenhongquan/Documents/PERSONAL_PROJECT/imposter-wording
supabase start
```

Kiểm tra local stack có đang chạy không:

```bash
supabase status
```

Nếu thấy `API URL: http://127.0.0.1:54321` thì local stack đang chạy.

Mở terminal thứ hai:

```bash
cd /Users/nguyenhongquan/Documents/PERSONAL_PROJECT/imposter-wording/admin
yarn dev:local
```

Admin sẽ dùng `admin/.env.local`.

## 3. Dừng Local Supabase

Từ thư mục gốc repository:

```bash
supabase stop
```

Lệnh này dừng local stack nhưng giữ lại dữ liệu local. Khi cần chạy lại:

```bash
supabase start
```

## 4. Chạy Admin với Development cloud

Không cần chạy `supabase start`. Chỉ cần:

```bash
cd /Users/nguyenhongquan/Documents/PERSONAL_PROJECT/imposter-wording/admin
yarn dev:development
```

Admin sẽ dùng `admin/.env.development.local` và kết nối project cloud Dev.

## 5. Link Supabase CLI với project Dev

Chỉ cần làm một lần trên máy:

```bash
cd /Users/nguyenhongquan/Documents/PERSONAL_PROJECT/imposter-wording

supabase login
supabase link --project-ref pxycsjwjakzehcuygngv
```

`supabase link` có thể hỏi database password của project Dev. Đây là
database password, không phải publishable key và không được lưu vào Git.

## 6. Push migration lên Development cloud

`supabase db push` chỉ push database migrations; nó không deploy Vue app.

Sau khi có file migration trong `supabase/migrations/`, kiểm tra trước:

```bash
cd /Users/nguyenhongquan/Documents/PERSONAL_PROJECT/imposter-wording
supabase db push --linked --dry-run
```

Nếu danh sách migration đúng, push thật:

```bash
supabase db push --linked
```

Kiểm tra lịch sử migration trên cloud:

```bash
supabase migration list --linked
```

Có thể kiểm tra migration local trước khi push:

```bash
supabase db reset --local
```

`db reset --local` sẽ xóa và tạo lại database local, vì vậy không dùng nếu
cần giữ dữ liệu local.

Hiện repository mới có `supabase/config.toml`, chưa có migration schema nên
chưa có thay đổi database để push.

## 7. Phân biệt dev và build

### Chạy trong lúc lập trình

```bash
yarn dev:local
yarn dev:development
```

Các lệnh này chạy Vite development server và hỗ trợ hot reload.

### Build để deploy

```bash
yarn build:local
yarn build:development
yarn build:production
```

Các lệnh này tạo thư mục `admin/dist/`. Chúng chỉ đóng gói frontend, không
tự deploy lên hosting.

Kiểm tra bản build đã tạo:

```bash
yarn preview
```

## 8. Quy trình làm việc thường ngày

### Làm việc local

```bash
cd /Users/nguyenhongquan/Documents/PERSONAL_PROJECT/imposter-wording
supabase status
supabase start                 # chỉ cần nếu stack chưa chạy

cd admin
yarn dev:local
```

### Làm việc với Dev cloud

```bash
cd /Users/nguyenhongquan/Documents/PERSONAL_PROJECT/imposter-wording/admin
yarn dev:development
```

### Sau khi sửa database schema

```bash
cd /Users/nguyenhongquan/Documents/PERSONAL_PROJECT/imposter-wording
supabase db push --linked --dry-run
supabase db push --linked
```

## Tài liệu tham khảo

- [Vite env variables and modes](https://vite.dev/guide/env-and-mode)
- [Supabase Vue quickstart](https://supabase.com/docs/guides/getting-started/quickstarts/vue)
- [Supabase local development workflow](https://supabase.com/docs/guides/local-development/cli-workflows)
- [Supabase data security](https://supabase.com/docs/guides/database/secure-data)
