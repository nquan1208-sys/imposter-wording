# Phase 3 — Admin quản lý danh mục

Hoàn tất local ngày 2026-10-24. Migration bổ sung: [20261024053232_admin_category_translations.sql](../supabase/migrations/20261024053232_admin_category_translations.sql). Chưa triển khai cloud.

## Hành vi đã triển khai

- Form tách thông tin chung và bản dịch. Tabs đọc từ `content_languages`, theo `sort_order, code`; tab thiếu hiển thị “Chưa có bản dịch”, không tạo row rỗng hoặc sao chép nội dung ngôn ngữ khác.
- Tên, mô tả và trạng thái nằm trong tab. Lưu gửi phần chung và đúng một bản dịch; xuất bản/lưu trữ chỉ đổi trạng thái bản dịch đang chọn. Có xác nhận khi tắt danh mục hoặc lưu trữ bản dịch đang xuất bản.
- Đổi tab giữ từng draft trong bộ nhớ. Lưu thành công chỉ làm sạch phần chung và tab vừa lưu; tab khác còn sửa vẫn kích hoạt cảnh báo rời trang, đóng tab và đăng xuất.
- Lần lưu đầu tạo một UUID, chuyển sang URL chỉnh sửa và giữ editor cùng các draft. Shell giữ component danh mục khi chuyển route tạo/sửa; navigation test dùng template thật bao phủ trường hợp này.
- Mỗi lần lưu tiếp theo dùng chính `original.updated_at` từ RPC. Lỗi giữ nguyên dữ liệu; xung đột khóa thao tác lưu đến khi tải lại rõ ràng, có xác nhận bỏ draft. Refetch nền không ghi đè editor đang dirty/busy.
- Danh sách có bộ chọn ngôn ngữ nội dung mặc định `vi`, lưu trong URL/cache key, độc lập locale giao diện. Locale lạ được đưa về `vi`, kể cả khi danh sách ngôn ngữ đã nằm trong cache.
- Mỗi danh mục có một dòng: tên của ngôn ngữ đã chọn hoặc nhãn thiếu bản dịch, slug, trạng thái của mọi ngôn ngữ và tổng đề gốc. Tìm trên mọi tên bản dịch và slug; sắp xếp tên theo ngôn ngữ chọn, tên thiếu nằm cuối. Phân trang và tổng số ở server.
- Bật/tắt dùng version bản gốc và không sửa metadata bản dịch. Các mutation danh mục invalidate caches danh mục, hai loại đề và dashboard.
- Preview xóa hiển thị riêng số đề gốc và số bản dịch đề theo trạng thái. Đề chưa có bản dịch vẫn khiến danh mục được coi là có nội dung.
- Danh mục nhận phải đang bật, cùng loại trò chơi và xuất bản đủ mọi locale đề đang xuất bản. Xung đột snapshot chặn xác nhận đến khi refresh thành công; danh mục nhận không còn hợp lệ bị bỏ chọn. Purge ghi rõ xóa toàn bộ bản dịch và giữ file Storage.

## API bổ sung

| RPC | Đầu vào | Kết quả |
| --- | --- | --- |
| `admin_list_categories` | `p_locale`, `p_search`, `p_game_type` nullable, `p_is_active` nullable, `p_sort`, `p_page` | JSON `{ rows, total }`; row có thông tin gốc, `name` nullable, `translations`, `word_count`, `question_count` |
| `set_category_active` | `p_id`, `p_is_active`, `p_expected_updated_at` | Row danh mục sau cập nhật |
| `admin_category_transfer_targets` | `p_source_id`, `p_locale` | Các row `{ id, slug, name }`; tên có thể null |

- RPC mới chỉ cho authenticated gọi và kiểm tra grant admin đang hoạt động; `SECURITY DEFINER`, search path rỗng và khóa grant dùng pattern Phase 2. `anon`, người ngoài và admin bị thu hồi quyền bị từ chối.
- List dùng literal substring search, không coi `%`/`_` là wildcard; `EXISTS` tránh đếm trùng khi nhiều bản dịch cùng khớp. Mỗi trang 20 danh mục gốc, có ID làm khóa sắp xếp cuối. Trang vượt phạm vi vẫn trả tổng chính xác để UI điều chỉnh trang.
- Activation khóa category, kiểm phiên bản, trả `40001` khi cũ và `P0002` khi không còn row. Các trigger hiện có tăng phiên bản và giữ quy tắc đọc công khai.
- Target discovery chỉ gợi ý; `delete_category` vẫn kiểm snapshot và điều kiện chuyển trong transaction trước khi ghi. Client đọc hết các trang 100 candidates, không cắt ở giới hạn API.
- Giữ nguyên hợp đồng `save_category`, `preview_category_delete`, `delete_category` của Phase 2. Không bật lại direct table writes.
- Sinh lại database types bằng script hiện có; nullable args chỉ mở rộng trong `AdminDatabase`, không sửa tay generated file.
- SQL bổ sung đã chạy qua `psql` trên container local; ghi nhận migration đã áp dụng bằng `supabase migration repair --local --status applied 20261024053232`. Ledger local khớp file migration. Không reset DB local.

## Kiểm thử và đối chiếu

Từ repo root:

```bash
rtk proxy python3 supabase/tests/content_translations.py
rtk proxy supabase db lint --local --schema public,private --level warning --fail-on warning
rtk proxy supabase db advisors --local --type all --level warn --fail-on warn
rtk proxy supabase migration list --local
```

Từ thư mục `admin`:

```bash
rtk proxy yarn test
rtk proxy yarn types:database
rtk proxy yarn build:local
rtk proxy yarn vite build --mode localdev
```

- Admin: **48/48 tests đạt**, bao gồm API, schema, i18n, SSR, state editor, delete dialog và navigation template thật. Kiểm giữ draft, save một locale, version trả về, thất bại/retry, xung đột/reload, chặn bấm lặp, tab mới từ dữ liệu và route sau lần lưu đầu.
- DB rehearsal: **5 nhóm unittest đạt** trên disposable copies. Nhóm Phase 3 replay cả DB rỗng lẫn dữ liệu cũ qua migration Phase 2 rồi migration mới, chạy lại năm SQL suites hiện có và suite `admin_category_translations.sql`.
- Concurrency: **8 race đạt**, gồm race mới giữa sửa translation và bật/tắt bằng version cũ. Không có deadlock. Các race preview/purge, publish/archive, transfer/archive và revoke admin vẫn đạt.
- DB lint không có lỗi; advisors không có warning/error. SQL mới cũng được chạy trực tiếp trên DB local với fixtures rollback.
- Vite bundle local đạt. `yarn build:local` còn dừng tại typecheck với **70 diagnostics trong API/components/views của hai loại đề**, thuộc chuyển tiếp Phase 4. Không có diagnostic trong category code. Kiểm riêng node/test config vẫn còn lỗi legacy trong prompt code và Storage fixture; không coi toàn bộ admin đã build đạt.
- Browser local: tạo bản dịch English published khi Vietnamese chưa lưu, giữ draft Vietnamese qua lần lưu đầu và route mới, rồi lưu Vietnamese draft; danh sách hiện `vi: Nháp`, `en: Đã xuất bản`. Kiểm chuyển tab bằng phím mũi tên, layout editor ở 390px, preview counts và danh mục nhận hợp lệ.
- Browser test tạo hai danh mục tạm không có đề; đã xóa đúng hai bản ghi này và file preview tạm sau kiểm thử. DB trở về **3 danh mục, 1 đề từ, 1 đề câu hỏi**. Không thay nội dung gốc hiện có hoặc Storage files.

## Phần chuyển tiếp

Chưa triển khai cloud, chưa chạy lại Storage HTTP integration và chưa chuyển prompt editors/dashboard sang giao diện đa ngôn ngữ. Các phần này vẫn thuộc Phase 4–6. DB và admin hoàn chỉnh phải triển khai cùng đợt; không dùng prompt editors cũ để ghi với schema mới.
