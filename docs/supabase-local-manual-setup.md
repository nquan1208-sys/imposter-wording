# Thiết lập Supabase local thủ công trên máy mới

Hướng dẫn cho macOS, chạy Supabase và Vue Admin của repository
`imposter-wording`. Mọi lệnh Supabase chạy tại **thư mục gốc repository**;
lệnh Yarn chạy trong **`admin/`**.

## 1. Chuẩn bị công cụ

Cần Git, Node.js 22.12 trở lên, Yarn 1.22.22, Supabase CLI và một Docker
runtime đang chạy. Các lệnh Homebrew dưới đây cần Homebrew đã được cài.

Kiểm tra trước:

```bash
git --version
node --version
yarn --version
supabase --version
docker --version
docker info
```

Chỉ cài những công cụ còn thiếu:

```bash
# Node.js, nếu chưa có phiên bản phù hợp
brew install node

# Yarn, nếu chưa có
npm install --global yarn@1.22.22

# Supabase CLI, nếu chưa có
brew install supabase/tap/supabase
```

Nếu chưa có Docker runtime, có thể cài OrbStack:

```bash
brew install --cask orbstack
open -a OrbStack
```

Nếu đã có Docker Desktop, mở Docker Desktop. Đợi runtime khởi động và kiểm
tra lại `docker info` trước khi tiếp tục.

## 2. Lấy repository

Nếu chưa clone, thay `<REPOSITORY_URL>` bằng URL Git của dự án:

```bash
git clone <REPOSITORY_URL>
cd imposter-wording
```

Nếu đã clone:

```bash
cd /path/to/imposter-wording
```

Repository đã có `supabase/config.toml` và migrations; không cần chạy
`supabase init`. Chạy local không cần `supabase login`, `supabase link` hoặc
push migration lên cloud.

## 3. Khởi động Supabase local

```bash
supabase start
supabase status
supabase migration list --local
```

Lần đầu cần tải Docker images nên có thể mất vài phút. Khi tạo database mới,
Supabase áp dụng migrations của repository. `supabase start` kết thúc khi
stack sẵn sàng; các container tiếp tục chạy nền.

Các địa chỉ mặc định:

| Dịch vụ | URL |
| --- | --- |
| API | http://127.0.0.1:54321 |
| Studio | http://127.0.0.1:54323 |
| Mailpit, xem email test | http://127.0.0.1:54324 |

## 4. Cài Admin và tạo environment

```bash
cd admin
yarn install --frozen-lockfile
```

Nếu chưa có `admin/.env.local`, tạo từ file mẫu:

```bash
cp .env.example .env.local
```

Mở để chỉnh sửa:

```bash
nano .env.local
```

Điền URL và **Publishable key** từ kết quả `supabase status`. Nếu CLI chỉ
hiển thị `anon key`, dùng key đó:

```env
VITE_SUPABASE_URL=http://127.0.0.1:54321
VITE_SUPABASE_PUBLISHABLE_KEY=<PUBLISHABLE_KEY_HOAC_ANON_KEY_LOCAL>
```

Thay toàn bộ placeholder bằng key thực tế. Không dùng `service_role`, Secret
key hoặc database password trong biến `VITE_*`. File `.env.local` đã được
Git ignore. Nếu chạy `supabase status` lại, quay về root bằng `cd ..`.

## 5. Tạo tài khoản admin local

Mở http://127.0.0.1:54323:

1. Vào **Authentication → Users → Add user**.
2. Tạo email `admin.local@example.com` và password test bạn chọn.
3. Bật **Auto Confirm** để đăng nhập ngay.
4. Mở **SQL Editor** và chạy câu lệnh sau.

```sql
insert into public.admin_users (user_id, role, is_active)
select id, 'admin', true
from auth.users
where email = 'admin.local@example.com'
on conflict (user_id) do update
set role = 'admin', is_active = true;

select u.email, au.role, au.is_active
from public.admin_users au
join auth.users u on u.id = au.user_id
where u.email = 'admin.local@example.com';
```

Nếu chọn email khác, thay email trong cả hai câu SQL. Kết quả phải có một
dòng với `role = admin` và `is_active = true`. Tài khoản này chỉ tồn tại trong
local stack của máy đang thiết lập.

## 6. Chạy và kiểm tra Admin

```bash
cd /path/to/imposter-wording/admin
yarn dev:local
```

Mở URL Vite in ra, thường là http://localhost:5173. Đăng nhập bằng tài khoản
vừa tạo và mở trang quản lý category để kiểm tra kết nối.

Có thể kiểm tra build và các test sẵn có trong terminal khác, sau khi đã tạo
`.env.local`:

```bash
cd /path/to/imposter-wording/admin
yarn build:local
yarn test
```

## 7. Lệnh dùng hằng ngày

Khởi động backend:

```bash
cd /path/to/imposter-wording
supabase start
```

Chạy frontend:

```bash
cd /path/to/imposter-wording/admin
yarn dev:local
```

Dừng frontend bằng `Ctrl+C`. Dừng backend nhưng giữ dữ liệu:

```bash
cd /path/to/imposter-wording
supabase stop
```

Không cần cài dependencies hoặc tạo lại tài khoản mỗi lần chạy.

## 8. Khi cần áp dụng migration mới hoặc dựng lại database

Nếu database đã tồn tại và có migration mới, kiểm tra rồi áp dụng trên local:

```bash
cd /path/to/imposter-wording
supabase migration list --local
supabase db push --local --dry-run
supabase db push --local
```

Chỉ khi muốn **xoá dữ liệu local và dựng lại từ migrations**, chạy:

```bash
supabase db reset --local
```

Sau reset, cần tạo lại tài khoản admin theo bước 5. Không dùng reset như một
bước bắt buộc khi mở dự án.

## 9. Lỗi thường gặp

- **Không kết nối Docker daemon:** mở Docker Desktop/OrbStack và chạy lại
  `docker info`.
- **Port đang được dùng:** kiểm tra `docker ps` và dừng stack đang chiếm các
  port `54321`–`54324`; tránh đổi port khi chưa cập nhật environment.
- **Thiếu `VITE_SUPABASE_*`:** kiểm tra `admin/.env.local`, dùng đúng
  `yarn dev:local` và khởi động lại Vite sau khi sửa env.
- **Đăng nhập được nhưng không có quyền admin:** kiểm tra kết quả SQL ở
  bước 5 và chắc chắn frontend đang trỏ đến API local.

Tham khảo: [Supabase CLI và local development](https://supabase.com/docs/guides/local-development/cli/getting-started),
[hướng dẫn đầy đủ của dự án](./admin-supabase-new-device-guide.md).
