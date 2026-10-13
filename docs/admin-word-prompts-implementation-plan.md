# Kế hoạch hoàn thiện quản lý nội dung từ ngữ

Ngày: 2026-10-13

Trạng thái: Đã chốt kế hoạch; chưa triển khai code hoặc setup bucket.

## 1. Mục tiêu và lựa chọn đã chốt

Hoàn thành luồng **danh sách → tạo nháp → sửa → gắn danh mục → quản lý ảnh → preview → publish/archive** trước khi triển khai nội dung câu hỏi.

- Nháp bắt buộc có từ civilian và danh mục; ảnh, từ imposter và hint tùy chọn.
- Civilian preview thấy từ và ảnh; imposter chỉ thấy từ riêng/hint.
- Sửa nội dung published cập nhật trực tiếp sau xác nhận.
- Dùng bucket **private**, cấu hình giống nhau ở Local và Dev.
- Tận dụng Nuxt UI, Vue Query, Zod, i18n và cảnh báo thay đổi chưa lưu hiện có; không thêm dependency.

### Hiện trạng

- Màn quản lý từ ngữ mới là placeholder.
- Bảng `word_prompts` đã có các trường nội dung, `image_path` và trạng thái `draft`, `published`, `archived`.
- Database đã có RLS cho phép admin quản lý content và người chơi đọc content published.
- Repo chưa cấu hình bucket ảnh hoặc policy Storage.
- Màn danh mục đã có các mẫu API, form, bộ lọc, phân trang và xử lý thay đổi chưa lưu để tái sử dụng.

## 2. Danh sách, form và trạng thái

### Danh sách

- Thay placeholder bằng danh sách có thumbnail, hai từ, danh mục, độ khó, Family Mode, trạng thái và ngày cập nhật.
- Tìm kiếm hai trường từ; lọc danh mục, độ khó, Family Mode, locale và trạng thái.
- Phân trang 20 dòng; mặc định cập nhật mới nhất, thêm `id` để thứ tự ổn định. Cho phép sắp xếp theo từ civilian hoặc ngày cập nhật.
- Giữ bộ lọc trong URL khi đi vào form và quay lại.
- Có trạng thái loading, danh sách rỗng, lỗi và thử lại.

### Form tạo/sửa

- Thêm routes `/word-prompts/new` và `/word-prompts/:id/edit`.
- Form sử dụng các trường hiện có: `civilian_text`, `imposter_text`, `imposter_hint`, `category_id`, `difficulty`, `is_family_friendly`, `locale`, `image_path`.
- Tạo mới mặc định `locale=vi`, độ khó `medium`, Family Mode tắt.
- Chọn danh mục `word` đang hoạt động, cùng locale.
- Đề cũ thuộc danh mục đã tắt vẫn hiển thị danh mục hiện tại để sửa/lưu; muốn publish phải chọn danh mục hoạt động.
- Locale mặc định `vi`; khi thay locale phải chọn lại danh mục tương ứng. Không tự đổi locale của danh mục.
- Preview cập nhật theo dữ liệu chưa lưu, tách civilian và imposter; hiển thị rõ khi imposter không có từ/hint.

### Hành động theo trạng thái

| Trạng thái hiện tại | Hành động |
|---|---|
| Tạo mới / draft | Lưu nháp; Publish |
| Published | Lưu cập nhật có xác nhận; Đưa về nháp có xác nhận; Archive có xác nhận |
| Archived | Lưu chỉnh sửa; Đưa về nháp; Publish lại |

Mỗi hành động lưu dữ liệu form cùng trạng thái trong một lần ghi database. Chặn bấm lặp, cảnh báo khi rời form/đăng xuất và giữ dữ liệu nhập nếu lưu lỗi.

### API và database

- Bổ sung API danh sách, chi tiết, lưu đề theo trạng thái đích, upload ảnh và tạo URL preview; theo cách truyền Supabase client đang dùng ở API danh mục.
- Bổ sung migration chuẩn hóa text, chuyển trường tùy chọn rỗng thành `null`, cập nhật `updated_at`, kiểm tra danh mục đúng loại/locale và điều kiện publish.
- Kiểm tra civilian text sau trim không rỗng ở mọi trạng thái; ảnh và dữ liệu imposter vẫn tùy chọn khi publish.
- Kiểm tra ảnh được tham chiếu thuộc bucket/path của đề và tồn tại trước khi ghi `image_path`.
- Khi sửa, kiểm tra `updated_at` đã tải để tránh ghi đè thay đổi từ tab khác; báo xung đột và yêu cầu tải lại.
- Làm mới query danh sách/chi tiết từ ngữ và thống kê danh mục sau khi lưu thành công.
- Giữ tương thích với luồng chuyển content rồi xóa danh mục hiện có; không đổi schema hoặc hành vi của nội dung câu hỏi.

## 3. Bucket và vòng đời ảnh

Bucket cố định tên `word-prompt-images`:

| Thuộc tính | Giá trị |
|---|---|
| Public | Tắt |
| Giới hạn file | 5 MiB, tương đương 5.242.880 byte |
| MIME cho phép | `image/jpeg`, `image/png`, `image/webp` |
| Đường dẫn | `<prompt-id>/<file-uuid>.<extension>` |
| Database lưu | `image_path`, không lưu signed URL |

Supabase hỗ trợ giới hạn kích thước và MIME ngay tại bucket. Xem [tài liệu tạo bucket](https://supabase.com/docs/guides/storage/buckets/creating-buckets).

### Upload, thay và bỏ ảnh

- Chọn file tạo preview local ngay; kiểm tra dung lượng, định dạng và khả năng đọc ảnh trước upload.
- Tạo UUID ổn định cho đề mới trước upload và dùng UUID đó khi insert đề.
- Khi lưu, upload file mới với `upsert: false`, rồi ghi `image_path` vào đề.
- Upload lỗi thì không ghi thay đổi. Ghi database lỗi thì giữ ảnh cũ và thử dọn file mới; lỗi dọn ảnh không được che lỗi lưu chính.
- Thay ảnh luôn dùng đường dẫn mới. Xóa ảnh trên form chỉ bỏ liên kết khi lưu thành công; không xóa file cũ trong lần ghi đó.
- Giữ ảnh cũ và ảnh của content bị purge để tránh xóa nhầm; chưa làm job dọn ảnh tự động.
- Hiển thị trạng thái đang upload, thành công và lỗi; không hiển thị phần trăm giả.
- Thu hồi object URL dùng cho preview local khi thay file hoặc rời form.

### Quyền đọc và ghi

Policy trên `storage.objects`, tất cả đều giới hạn đúng bucket:

- Admin đang hoạt động: `SELECT`, `INSERT`; `DELETE` chỉ cho file không còn được đề nào tham chiếu, phục vụ dọn upload lỗi.
- `anon` và người đăng nhập thường: `SELECT` khi tồn tại `word_prompts` có `image_path = storage.objects.name` và `status = 'published'`.
- Không cấp `UPDATE`, vì không ghi đè file.
- Tái sử dụng `private.is_admin()` cho quyền admin; không chỉ kiểm tra role `authenticated`.
- Tách policy đọc admin khỏi policy đọc published để role `anon` không cần quyền gọi `private.is_admin()`.

Xem [tài liệu Storage RLS](https://supabase.com/docs/guides/storage/security/access-control).

Admin dùng signed URL 5 phút cho thumbnail/preview, làm mới khi hết hạn. Người chơi chỉ được tải hoặc xin URL cho ảnh published. Xem [tài liệu signed URL](https://supabase.com/docs/reference/javascript/storage-from-createsignedurl).

## 4. Hướng dẫn setup Local + Dev

### Local

1. Chạy Supabase local, mở Studio tại `http://127.0.0.1:54323`.
2. Vào **Storage → New bucket**, nhập `word-prompt-images`, tắt Public.
3. Đặt giới hạn 5 MiB và ba MIME: `image/jpeg`, `image/png`, `image/webp`.
4. Áp dụng migration chứa các policy ảnh sau khi migration được triển khai. Tạo bucket riêng chưa đủ quyền upload từ admin.
5. Khi triển khai, ghi cấu hình tương ứng vào `supabase/config.toml` để local có thể tái tạo:

```toml
[storage.buckets.word-prompt-images]
public = false
file_size_limit = "5MiB"
allowed_mime_types = ["image/jpeg", "image/png", "image/webp"]
```

Không cần `objects_path` vì không seed ảnh mẫu trong bước này. Không chạy reset database chỉ để thêm bucket vào môi trường đang có dữ liệu.

### Dev cloud

1. Mở project Dev `imposter-word`, ref `pxycsjwjakzehcuygngv`.
2. Vào **Storage → New bucket** và tạo cùng tên, quyền, dung lượng, MIME như Local.
3. Áp dụng migration policy đã kiểm tra ở local. Không tạo thêm policy “mọi authenticated user được upload”.
4. Chạy admin bằng môi trường Development, đăng nhập admin và thử upload từ form.
5. Kiểm tra ảnh nháp không đọc được bằng client anon; publish thì đọc được; archive thì không cấp được URL mới.

### Đưa cấu hình vào repository

- Khi triển khai, tạo migration bằng Supabase CLI, chứa cấu hình bucket và các policy Storage để áp dụng giống nhau giữa môi trường.
- Migration phải xử lý được bucket đã tạo thủ công: cập nhật cấu hình theo tên thay vì tạo bucket trùng.
- Kiểm tra local trước; xem dry-run các migration đang chờ trước khi áp dụng lên Dev.
- Kiểm tra policy có sẵn để tránh một policy rộng hơn vô tình cấp quyền ngoài yêu cầu.
- Không đưa `service_role`, secret key hoặc database password vào biến `VITE_*`.

Tài liệu môi trường hiện có: [admin-supabase-environment-guide.md](admin-supabase-environment-guide.md) và [supabase-local-manual-setup.md](supabase-local-manual-setup.md).

## 5. Thứ tự triển khai và kiểm thử

### Thứ tự

1. Migration validation/timestamp và cấu hình bucket/policy; kiểm tra quyền bằng SQL và Storage API.
2. API, validation và danh sách từ ngữ.
3. Form tạo/sửa, gắn danh mục và cảnh báo chưa lưu.
4. Upload/thay/bỏ ảnh và preview hai vai trò.
5. Publish, đưa về nháp, archive và xử lý xung đột.
6. Kiểm tra luồng đầy đủ Local, sau đó Dev; cập nhật tài liệu tiến độ.

### Kiểm thử

- Test validation và API: trim text, trường tùy chọn, tìm kiếm ký tự đặc biệt, bộ lọc, phân trang, trạng thái và xung đột chỉnh sửa.
- Test SQL: admin/non-admin, danh mục sai loại/locale, publish với danh mục đã tắt, timestamp, ảnh không tồn tại/path sai và khả năng chuyển content khi xóa danh mục.
- Test Storage bằng API thật ở local: admin upload được; user thường không ghi được; ảnh nháp/archived không được cấp quyền đọc; ảnh published đọc được; file sai MIME/quá lớn bị từ chối.
- Test cả role anon lẫn authenticated không phải admin; admin bị vô hiệu hóa phải mất quyền quản lý ảnh/content.
- Test thủ công cả luồng: tạo nháp có ảnh → tải lại → sửa/thay ảnh → preview → publish → archive → publish lại.
- Test thêm: bỏ ảnh rồi hủy form, mất mạng khi upload/lưu, hai tab cùng sửa, không còn danh mục hợp lệ và signed URL hết hạn.
- Chạy test admin, build Local/Development và kiểm tra bố cục desktop/tablet, nhãn accessibility, i18n.

### Tiêu chí hoàn thành

- Dữ liệu và liên kết ảnh được giữ đúng sau tải lại.
- Lỗi upload/lưu không làm mất ảnh cũ hoặc dữ liệu đang nhập.
- Người chơi không lấy được dữ liệu nháp/archived hoặc xin URL mới cho ảnh của chúng.
- Preview civilian/imposter đúng lựa chọn đã chốt.
- Luồng quản trị chạy trọn vẹn trên Local và Dev; chỉ sau đó chuyển sang nội dung câu hỏi.

## Giới hạn và rủi ro đã biết

- Chưa triển khai code, tạo bucket hay kiểm tra trạng thái project cloud thực tế ở bước lập tài liệu này.
- Chưa làm màn câu hỏi, tích hợp gameplay Flutter, thư viện ảnh, crop ảnh hoặc dọn ảnh tự động.
- Signed URL đã cấp có thể dùng đến khi hết hạn sau archive; ảnh đã tải về không thể thu hồi.
- File ảnh không còn liên kết vẫn chiếm Storage, gồm ảnh cũ, ảnh của content bị purge và upload không dọn được sau lỗi.
