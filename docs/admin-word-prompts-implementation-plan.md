# Kế hoạch hoàn thiện quản lý nội dung từ ngữ

Ngày: 2026-10-13

Trạng thái: Đã triển khai trong workspace và kiểm tra tự động trên Local; chưa áp dụng hoặc xác minh Dev cloud.

Khi bắt đầu triển khai, workspace đã có một phần migration/API ảnh và lưu đề, còn màn từ ngữ là placeholder; chưa hoàn tất giao diện hoặc xác minh Local/Dev. Hiện đã có danh sách, form tạo/sửa, preview, upload, publish/archive và xóa vĩnh viễn. Migration ảnh, xóa đề và tinh gọn Wording được áp dụng vào Local mà không reset dữ liệu.

## 1. Mục tiêu và lựa chọn đã chốt

Hoàn thành luồng **danh sách → tạo nháp → sửa → gắn danh mục → quản lý ảnh → preview → publish/archive → xóa vĩnh viễn** trước khi triển khai nội dung câu hỏi.

- Nháp bắt buộc có từ civilian và danh mục; ảnh tùy chọn.
- Preview Dân thường thấy từ và ảnh; Imposter chỉ thấy tên danh mục khi bật gợi ý, hoặc chỉ “Bạn là imposter” khi tắt. Công tắc trên admin chỉ mô phỏng, không lưu vào đề.
- Sửa nội dung published cập nhật trực tiếp sau xác nhận.
- Dùng bucket **private**, cấu hình giống nhau ở Local và Dev.
- Tận dụng Nuxt UI, Vue Query, Zod, i18n và cảnh báo thay đổi chưa lưu hiện có; không thêm dependency.
- Admin là nguồn content duy nhất. App Flutter gọi API lúc chạy để lấy danh mục/đề published; không seed database và không đóng gói content hay ảnh vào bản build app.

### Hiện trạng

- Màn quản lý từ ngữ đã có danh sách và form tạo/sửa, giữ bộ lọc URL.
- Bảng `word_prompts` đã có các trường nội dung, `image_path` và trạng thái `draft`, `published`, `archived`.
- Database đã có RLS cho phép admin quản lý content và người chơi đọc content published.
- Repo đã cấu hình bucket private và policy Storage trong migration/config; Local đã có bucket.
- Màn danh mục đã có các mẫu API, form, bộ lọc, phân trang và xử lý thay đổi chưa lưu để tái sử dụng.

## 2. Danh sách, form và trạng thái

### Danh sách

- Thay placeholder bằng danh sách có thumbnail, từ civilian, danh mục, độ khó, Family Mode, trạng thái và ngày cập nhật.
- Tìm kiếm từ civilian; lọc danh mục, độ khó, Family Mode, locale và trạng thái.
- Phân trang 20 dòng; mặc định cập nhật mới nhất, thêm `id` để thứ tự ổn định. Cho phép sắp xếp theo từ civilian hoặc ngày cập nhật.
- Giữ bộ lọc trong URL khi đi vào form và quay lại.
- Có trạng thái loading, danh sách rỗng, lỗi và thử lại.

### Form tạo/sửa

- Thêm routes `/word-prompts/new` và `/word-prompts/:id/edit`.
- Form sử dụng các trường hiện có: `text`, `category_id`, `difficulty`, `is_family_friendly`, `locale`, `image_path`.
- Tạo mới mặc định `locale=vi`, độ khó `medium`, Family Mode tắt.
- Chọn danh mục `word` đang hoạt động, cùng locale.
- Đề cũ thuộc danh mục đã tắt vẫn hiển thị danh mục hiện tại để sửa/lưu; muốn publish phải chọn danh mục hoạt động.
- Locale mặc định `vi`; khi thay locale phải chọn lại danh mục tương ứng. Không tự đổi locale của danh mục.
- Preview cập nhật theo dữ liệu chưa lưu, gồm hai card Dân thường và Imposter. Công tắc Gợi ý danh mục mặc định tắt; bật chỉ hiện tên danh mục đang chọn, tắt chỉ hiện “Bạn là imposter”; không lưu cấu hình vào đề.

### Hành động theo trạng thái

| Trạng thái hiện tại | Hành động |
|---|---|
| Tạo mới chưa lưu | Lưu nháp; Publish; Hủy; không có xóa |
| Draft đã lưu | Lưu nháp; Publish; Archive; Xóa vĩnh viễn |
| Published | Lưu cập nhật có xác nhận; Đưa về nháp có xác nhận; Archive có xác nhận; Xóa vĩnh viễn |
| Archived | Lưu chỉnh sửa; Đưa về nháp; Publish lại; Xóa vĩnh viễn |

Mỗi hành động lưu dữ liệu form cùng trạng thái trong một lần ghi database. Chặn bấm lặp, cảnh báo khi rời form/đăng xuất và giữ dữ liệu nhập nếu lưu lỗi.

### Xóa vĩnh viễn

- Nút **Xóa vĩnh viễn** đặt tại từng dòng danh sách và form sửa, cạnh Archive khi hành động đó có sẵn.
- Dialog dùng từ civilian, danh mục và trạng thái của bản ghi đã lưu, hiển thị cảnh báo và nút xác nhận xóa; không yêu cầu nhập lại từ xác nhận.
- Cảnh báo đề không thể khôi phục, thay đổi chưa lưu sẽ bị bỏ, toàn bộ file ảnh vẫn được giữ.
- Xóa độc lập với lưu: không validation form, không lưu dữ liệu đang sửa và không upload file đang chọn.
- Trong lúc xóa: chặn bấm lặp, đóng dialog, điều hướng nội bộ và đăng xuất; cảnh báo trình duyệt khi reload/đóng tab. Trình duyệt vẫn có thể cho người dùng cưỡng chế rời trang.
- Thành công: đóng dialog, invalidate query danh sách/chi tiết từ ngữ và thống kê danh mục; form quay về danh sách với bộ lọc URL hiện tại. Danh sách tự điều chỉnh về trang cuối hợp lệ nếu vừa xóa dòng cuối.
- Thất bại: giữ form, file đang chọn và dữ liệu xác nhận; hiển thị lỗi, không tự thử lại xóa.
- Khi xung đột: phải tải lại trước khi xác nhận lần nữa. Form chỉ bỏ dữ liệu nhập sau khi người dùng chọn tải lại và đồng ý bỏ thay đổi. Dialog được đóng sau tải lại để yêu cầu mở và nhập xác nhận mới.

### API và database

- Bổ sung API danh sách, chi tiết, lưu đề theo trạng thái đích, upload ảnh và tạo URL preview; theo cách truyền Supabase client đang dùng ở API danh mục.
- `deleteWordPrompt(client, { id, updatedAt })` chỉ gọi RPC `delete_word_prompt(p_id uuid, p_expected_updated_at timestamptz)`.
- RPC xóa dùng `SECURITY DEFINER`, `search_path = ''`; thu hồi thực thi của `PUBLIC`/`anon`, chỉ cấp `authenticated`. Giữ quyền `DELETE` trực tiếp bị thu hồi.
- RPC khóa grant admin đang hoạt động bằng `FOR SHARE`, khóa đề bằng `FOR UPDATE`, kiểm tra `updated_at`, rồi xóa trong cùng transaction. Không có bản ghi: `P0002` (“Đề không còn tồn tại”); phiên bản khác: `40001`, yêu cầu tải lại. Không sửa danh mục/câu hỏi hoặc thay đổi RPC chuyển/purge danh mục.
- Bổ sung migration chuẩn hóa text, chuyển trường tùy chọn rỗng thành `null`, cập nhật `updated_at`, kiểm tra danh mục đúng loại/locale và điều kiện publish.
- Kiểm tra civilian text sau trim không rỗng ở mọi trạng thái; ảnh vẫn tùy chọn khi publish.
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
- Giữ toàn bộ ảnh cũ, ảnh của đề bị xóa vĩnh viễn và ảnh của content bị purge để tránh xóa nhầm; chưa làm job dọn ảnh tự động. RPC xóa đề không gọi Storage delete.
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

Sau xóa đề, không còn bản ghi published tham chiếu ảnh nên anon/user thường không tải trực tiếp hoặc xin signed URL mới. Signed URL đã cấp vẫn dùng được đến khi hết hạn; ảnh đã tải về không thể thu hồi. Object URL local được thu hồi khi thay file, tải lại form hoặc rời form.

## Hợp đồng dữ liệu cho app

App không có dữ liệu dự phòng trong bản build; mọi content đến từ API Supabase.

- App dùng role `anon` với publishable key; không đăng nhập admin, không nhúng `service_role`. Quyền đọc dựa trên RLS hiện có: `game_categories` đang hoạt động và `word_prompts` có `status = 'published'`. Không cần migration mới cho app.
- Chỉ select trường game cần: `id`, `category_id`, `text`, `image_path`, `difficulty`, `is_family_friendly`, `locale` và tên/locale/loại của danh mục.
- Ảnh: app xin signed URL hoặc tải qua policy đọc ảnh published, rồi lưu file trên máy theo `image_path` để dùng offline. Ảnh của đề draft/archived/đã xóa không lấy được mới; file đã tải trên máy chỉ bị xóa ở lần đồng bộ kế tiếp. Vì app dựa vào `image_path` làm khóa, thay ảnh phải luôn tạo path mới (giữ đúng quy tắc ở mục 3).
- Publish, archive, sửa hoặc xóa trên admin có hiệu lực từ lần app tải content kế tiếp; ván đang chơi giữ nguyên đề đã chọn.
- App lưu cache lần tải thành công gần nhất. Mất mạng thì dùng cache, có thể cũ tới lần đồng bộ thành công; lần mở đầu tiên không có mạng thì báo lỗi và cho thử lại.
- Schema `word_prompts`/`game_categories` trở thành hợp đồng với app đã phát hành: ưu tiên chỉ thêm cột. Đổi tên/xóa cột (như đổi sang `text`, bỏ `imposter_*`) phải phối hợp với phiên bản app trước khi áp dụng lên môi trường app đang dùng.

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

Không cần `objects_path` vì không seed ảnh mẫu. Không seed content ở mọi môi trường; đề và ảnh chỉ được tạo qua admin. Không chạy reset database chỉ để thêm bucket vào môi trường đang có dữ liệu.

### Dev cloud

1. Mở project Dev `imposter-word`, ref `pxycsjwjakzehcuygngv`.
2. Vào **Storage → New bucket** và tạo cùng tên, quyền, dung lượng, MIME như Local.
3. Áp dụng migration policy đã kiểm tra ở local. Không tạo thêm policy “mọi authenticated user được upload”.
4. Chạy admin bằng môi trường Development, đăng nhập admin và thử upload từ form.
5. Kiểm tra ảnh nháp không đọc được bằng client anon; publish thì đọc được; archive thì không cấp được URL mới.
6. Dev không có seed nên content rỗng tới khi admin nhập. UAT gồm tạo và publish đề qua admin, rồi xác nhận app (role anon) đọc được đề và ảnh đó.

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
5. Publish, đưa về nháp, archive, xóa vĩnh viễn ở danh sách/form và xử lý xung đột; RPC xóa triển khai sau migration quản lý đề/ảnh.
6. Kiểm tra luồng đầy đủ Local, sau đó Dev; cập nhật tài liệu tiến độ.

### Kiểm thử

- Test validation và API: trim text, trường tùy chọn, tìm kiếm ký tự đặc biệt, bộ lọc, phân trang, trạng thái và xung đột chỉnh sửa.
- Test SQL: admin/non-admin, danh mục sai loại/locale, publish với danh mục đã tắt, timestamp, ảnh không tồn tại/path sai và khả năng chuyển content khi xóa danh mục.
- Test Storage bằng API thật ở local: admin upload được; user thường không ghi được; ảnh nháp/archived không được cấp quyền đọc; ảnh published đọc được; file sai MIME/quá lớn bị từ chối.
- Test cả role anon lẫn authenticated không phải admin; admin bị vô hiệu hóa phải mất quyền quản lý ảnh/content.
- Test thủ công cả luồng: tạo nháp có ảnh → tải lại → sửa/thay ảnh → preview → publish → archive → publish lại.
- Test thêm: bỏ ảnh rồi hủy form, mất mạng khi upload/lưu, hai tab cùng sửa, không còn danh mục hợp lệ và signed URL hết hạn.
- Test SQL xóa cả `draft`, `published`, `archived`; từ chối anon, user thường, admin vô hiệu hóa, xác nhận sai/null, phiên bản cũ/null và đề không tồn tại; quyền DELETE trực tiếp vẫn bị thu hồi.
- Test API/UI xóa: hủy dialog, bấm nút xác nhận xóa, chặn lặp/rời trang/đăng xuất, lỗi mạng giữ form/file, xóa khi form không hợp lệ, xung đột sửa/xóa từ tab khác, tải lại có xác nhận bỏ thay đổi, giữ URL và điều chỉnh phân trang. Invalidate cả thống kê danh mục.
- Test Storage: file tồn tại sau xóa; anon/user thường không đọc hoặc xin URL mới được; signed URL cấp trước xóa vẫn dùng được đến hết hạn.
- Chạy test admin, build Local/Development và kiểm tra bố cục desktop/tablet, nhãn accessibility, i18n.

### Tiêu chí hoàn thành

- Dữ liệu và liên kết ảnh được giữ đúng sau tải lại.
- Lỗi upload/lưu không làm mất ảnh cũ hoặc dữ liệu đang nhập.
- Người chơi không lấy được dữ liệu nháp/archived hoặc xin URL mới cho ảnh của chúng.
- Preview civilian/imposter đúng lựa chọn đã chốt.
- Xóa được mọi trạng thái đã lưu bằng RPC có xác nhận/version; không lưu hoặc upload dữ liệu chưa lưu; giữ file ảnh, chặn quyền đọc mới cho người chơi và cập nhật danh sách/thống kê đúng.
- Luồng quản trị chạy trọn vẹn trên Local và Dev; chỉ sau đó chuyển sang nội dung câu hỏi.

### Kết quả kiểm tra trong workspace

- `cd admin && yarn test`: 31 test pass, gồm API, validation, i18n và component Vue thật được mount để kiểm tra lỗi mạng, xung đột, xác nhận, busy guard, giữ dữ liệu, phân trang và chuyển tab sidebar.
- Build `localdev` và `development` pass. Đây là build, không phải xác minh môi trường Dev cloud.
- `supabase/tests/word_prompt_management.sql` và bộ hồi quy `category_management.sql` pass trên Local; fixture SQL rollback.
- `node admin/tests/wordStorage.local.js` pass trên Local qua Auth/Data/Storage API thật; tạo fixture riêng và dọn trong `finally`.
- `supabase db advisors --local --type security`: không phát hiện vấn đề. Lịch sử migration Local đã ghi nhận cả hai migration mới.
- Đã kiểm tra Chrome desktop: chuyển giữa Danh mục/Từ ngữ/Câu hỏi, mở bộ lọc danh mục rồi chuyển trang. Đã sửa lỗi option “Tất cả” dùng giá trị rỗng khiến Reka SelectItem lỗi và router giữ view cũ; hiện dùng `all` theo mẫu bộ lọc danh mục, không ghi sentinel vào URL. Test hồi quy kiểm tra cả bốn tab, option Select hợp lệ, bỏ bộ lọc và cảnh báo thay đổi chưa lưu. Chưa kiểm tra kích thước tablet.
- Chưa deploy migration lên Dev cloud hoặc chạy UAT trọn luồng trên Dev. Không ghi nhận milestone Local/Dev đã hoàn tất trước khi làm các bước này.

## Giới hạn và rủi ro đã biết

- Chưa kiểm tra trạng thái project cloud thực tế hoặc áp dụng migration lên Dev trong bước triển khai này.
- Chưa làm màn câu hỏi, tích hợp gameplay Flutter, thư viện ảnh, crop ảnh hoặc dọn ảnh tự động.
- Xóa đề không thể hoàn tác; không bổ sung khôi phục, xóa hàng loạt hoặc job dọn ảnh.
- Signed URL đã cấp có thể dùng đến khi hết hạn sau archive/xóa; ảnh đã tải về không thể thu hồi.
- File ảnh không còn liên kết vẫn chiếm Storage, gồm ảnh cũ, ảnh của đề xóa vĩnh viễn/content bị purge và upload không dọn được sau lỗi.
- App không đóng gói content: lần mở đầu không có mạng thì không chơi được; máy offline dùng cache có thể cũ và chưa nhận archive/xóa mới.

## Tinh gọn Wording theo luật chơi

- Migration `simplify_word_prompts` bỏ `imposter_text` và `imposter_hint` khỏi `word_prompts`, thay hàm trigger trong cùng transaction; không sửa migration cũ.
- Giữ `text`, `category_id` và các trường ảnh/trạng thái/lọc hiện có. Giữ nguyên schema trò câu hỏi.
- App Flutter hiện chưa có gameplay Wording; thiết lập hiển thị danh mục sẽ thuộc ván lưu local, tên danh mục lấy từ danh mục có cùng `category_id` trong dữ liệu API/cache app đã tải.
- Triển khai môi trường dùng chung: xuất sao lưu các giá trị khác rỗng trong hai cột; cập nhật admin trước rồi áp dụng migration. Admin cũ không tương thích sau khi xóa cột.

### Kết quả kiểm chứng tinh gọn Wording (2026-10-13)

- Local trước migration: 0 word prompts, 0 bản ghi có từ/hint imposter; không có dữ liệu cần xuất sao lưu.
- Migration `20261013164020_simplify_word_prompts.sql` đã áp dụng Local không reset; kiểm tra schema xác nhận hai cột đã bỏ.
- 31 test admin pass, gồm payload loại bỏ trường cũ và template preview không lộ từ/ảnh; build local pass.
- Hai bộ SQL `word_prompt_management.sql` và `category_management.sql` pass; security advisor Local không báo vấn đề ở mức warn/error.
- Kiểm tra tích hợp Local bằng `wordStorage.local.js` pass: tạo nháp, sửa/publish, archive/publish lại, tìm kiếm literal có dấu phẩy/wildcard/ngoặc kép, quyền ảnh và xóa đề. Fixture được dọn sau test.
- Kiểm tra migration với fixture có từ/hint cũ trong transaction rollback: dữ liệu còn lại giữ nguyên và trigger vẫn trim/cập nhật được.
- Replay toàn bộ migration từ schema ứng dụng rỗng trên database Local tạm, giữ nền tảng Auth/Storage Supabase: hai bộ SQL pass; database tạm được dọn.
- Chưa kiểm tra giao diện thủ công vì công cụ không kết nối được trình duyệt; chưa áp dụng Dev cloud.


## Cập nhật form và trường `text` (2026-10-21)

- Đổi `word_prompts.civilian_text` thành `word_prompts.text` bằng migration `20261021032252_rename_word_prompt_text.sql`; đổi tên tại chỗ, không tạo lại bảng hoặc reset dữ liệu. Migration cũ giữ nguyên.
- Admin dùng `text` cho form, danh sách, tìm kiếm, sắp xếp và dialog xóa; nhãn là “Từ bí mật”. URL cũ `sort=civilian_text` vẫn được đọc thành `sort=text`.
- Form sạch nhận bản mới từ query; form đang sửa/đang thao tác giữ nguyên dữ liệu và file. Xung đột lưu được giữ đến khi tải lại thành công, không mất nút tải lại khi sửa trường; chặn lưu/chuyển trạng thái khi còn xung đột.
- Form tách Nội dung, Phân loại, Ảnh và Xem trước; hai card có nền teal/vàng nhẹ, icon vai trò, nội dung tự xuống dòng, ảnh giữ tỷ lệ và xếp dọc ở màn hẹp. Xóa vĩnh viễn tách khỏi nhóm lưu.
- 32 test admin pass, gồm test cache sạch/dirty/busy, giữ xung đột sau nhập tiếp, hủy/tải lại lỗi/thành công, công tắc preview không tạo thay đổi chưa lưu và URL sort cũ.
- Build Local và Development pass. SQL `word_prompt_management.sql`, `category_management.sql`, kiểm tra migration giữ dữ liệu bằng fixture rollback, và tích hợp Auth/Data/Storage Local đều pass. Security advisor Local không phát hiện vấn đề.
- Migration đã áp dụng Local; chưa áp dụng Dev cloud. Khi triển khai môi trường dùng chung, cập nhật database và admin trong cùng đợt vì admin cũ dùng tên cột cũ; không cần xuất/nhập lại dữ liệu.
- Đã kiểm tra trực quan Chrome desktop với đề có ảnh: hai card cân đối, ảnh giữ tỷ lệ; bật gợi ý chỉ hiện danh mục, tắt chỉ hiện vai trò. Đã làm mới Vite để theme Nuxt UI nhận công tắc mới. Chưa kiểm tra trực quan tablet/mobile.

### Cột `text` hiển thị ở cuối Supabase Studio

Database vẫn giữ thứ tự `id`, `category_id`, `text`, `image_path`, … (`text` ở vị trí 3). Studio lưu thứ tự cột riêng trong trình duyệt; sau đổi tên, cột mới có thể bị đưa về cuối. Không cần migration khác để sắp xếp bảng.

Có thể sửa bằng JavaScript bên dưới trong DevTools Console của **đúng tab bảng word_prompts trên Studio Local**. Đoạn này chỉ đặt lại thứ tự hiển thị cột của bảng đang mở; giữ độ rộng cột, bộ lọc và cấu hình bảng khác. Không chạy trong SQL Editor.

```js
(() => {
  if (location.origin !== 'http://127.0.0.1:54323') {
    throw new Error('Chỉ chạy trên Supabase Studio Local.');
  }
  const match = location.pathname.match(/^\/project\/([^/]+)\/editor\/(\d+)$/);
  if (!match || !document.title.includes('word_prompts')) {
    throw new Error('Mở bảng word_prompts trước khi chạy.');
  }
  const key = `supabase_grid_${match[1]}`;
  let changed = false;
  for (const storage of [localStorage, sessionStorage]) {
    const raw = storage.getItem(key);
    if (!raw) continue;
    const state = JSON.parse(raw);
    const table = state[match[2]];
    if (!Array.isArray(table?.gridColumns)) continue;
    const textColumn = table.gridColumns.find(c => c.key === 'text')
      || table.gridColumns.find(c => c.key === 'civilian_text')
      || { key: 'text', name: 'text', width: 250 };
    const columns = table.gridColumns.filter(c => !['text', 'civilian_text'].includes(c.key));
    const categoryIndex = columns.findIndex(c => c.key === 'category_id');
    if (categoryIndex < 0) throw new Error('Không tìm thấy cột category_id trong cấu hình.');
    columns.splice(categoryIndex + 1, 0, { ...textColumn, key: 'text', name: 'text' });
    table.gridColumns = columns.map((column, idx) => ({ ...column, idx }));
    storage.setItem(key, JSON.stringify(state));
    changed = true;
  }
  if (changed) location.reload();
  else console.info('Chưa có cấu hình thứ tự cột được lưu cho bảng này.');
})();
```

Cơ chế lưu cấu hình: [mã nguồn Supabase Studio](https://github.com/supabase/supabase/blob/master/apps/studio/components/grid/SupabaseGrid.utils.ts).

Đoạn JavaScript chỉnh layout đã được kiểm tra với storage giả lập: giữ độ rộng, bộ lọc và cấu hình bảng khác, hỗ trợ cả tên cột cũ/mới và từ chối origin khác. Chưa áp dụng trên storage thật của tab Studio.
