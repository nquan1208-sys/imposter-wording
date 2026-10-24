# Phase 4 — Admin quản lý hai loại đề

Triển khai local ngày 2026-10-24. Migration bổ sung: [20261024055441_admin_prompt_translations.sql](../../../supabase/migrations/20261024055441_admin_prompt_translations.sql). Chưa triển khai cloud.

## Hành vi

- Đề từ và đề câu hỏi có phần chung và tabs từ `content_languages`. Category, độ khó, nhãn gia đình và ảnh đề từ dùng chung; giao diện nhắc tác động mọi ngôn ngữ. Tab mới trống, không sao chép nội dung hay tạo row rỗng.
- Mỗi tab giữ draft trong bộ nhớ. Lưu/xuất bản/lưu trữ gửi phần chung và đúng một bản dịch. Lưu thành công chỉ làm sạch phần chung và tab vừa lưu, vẫn ở editor; lần đầu chuyển URL tạo sang sửa mà không remount hoặc mất draft khác.
- Version luôn lấy từ `original.updated_at`, không dùng timestamp của translation. Refetch nền không thay draft dirty/busy. Xung đột khóa lưu cho đến explicit reload; hủy reload giữ nội dung. Các thao tác upload, save và delete chặn bấm lặp/rời trang/đăng xuất.
- Giữ kiểm định ảnh, object URL preview, signed URL, cleanup upload khi save lỗi và giữ file khi xóa đề. Hộp xác nhận nêu rõ xóa đề gốc và mọi bản dịch, dùng nội dung đã lưu cùng version gốc.
- List một dòng mỗi đề gốc, locale mặc định `vi`, độc lập ngôn ngữ giao diện và lưu trong URL/cache. Locale lạ được chuẩn hóa về `vi`. Hiện trạng thái từng ngôn ngữ, nhãn thiếu bản dịch và cho phép mở tab thiếu để thêm.
- Tìm theo nội dung đúng locale đang chọn; đề câu hỏi tìm cả hai câu. Sort nội dung tăng dần, thiếu xếp cuối; sort cập nhật giảm dần và ID giữ thứ tự ổn định. Lọc trạng thái loại bản dịch chưa tồn tại. Đếm/phân trang tại DB theo đề gốc, 20 dòng/trang.
- Archive từ list chỉ đổi bản dịch đã chọn. Xung đột chặn archive cho đến reload list thành công. Delete vẫn xóa toàn bộ đề. Mutation invalidate caches hai loại đề, danh mục và dashboard.
- Category options phân trang lấy đầy đủ, đúng game type; nhãn lấy bản dịch locale chọn hoặc slug. Editor giữ danh mục hiện tại, cho chọn danh mục đang bật và không xóa lựa chọn khi đổi ngôn ngữ. DB vẫn kiểm điều kiện publish và mọi locale đã xuất bản khi chuyển danh mục.

## Hợp đồng API

- Giữ nguyên RPC `save_word_prompt`, `save_question_prompt`, hai RPC delete và quy tắc bảo mật của Phase 2. Hai save API trả `{ original, translation }`; detail đọc bản gốc, toàn bộ translations và category translations. Không ghi trực tiếp vào bảng.
- Thêm `admin_list_word_prompts` và `admin_list_question_prompts`: nhận `p_locale`, `p_search`, `p_category_id`, `p_difficulty`, `p_is_family_friendly`, `p_status`, `p_sort`, `p_page`; trả JSON `{ rows, total }`.
- Row gồm thông tin gốc, nội dung/status nullable của locale chọn, `locale`, `translations`, `game_categories` kèm tên nullable và slug. Trang vượt phạm vi trả rows rỗng và total chính xác. Tìm literal substring, không coi `%`/`_` là wildcard.
- RPC list yêu cầu admin đang hoạt động; search path rỗng, giới hạn EXECUTE cho authenticated và dùng `private.require_content_admin()` như Phase 3. Không mở direct writes hoặc thay RLS/Storage policies.
- Sinh lại `database.ts` từ schema local; nullable RPC arguments chỉ điều chỉnh trong `AdminDatabase`.
- Migration đã áp dụng qua psql local và ghi nhận ledger bằng `supabase migration repair --local --status applied 20261024055441`. Không reset DB local.

## Kiểm thử

Từ `admin`:

```bash
rtk proxy yarn test
rtk proxy yarn build:local
rtk proxy yarn test:storage
```

Từ repo root:

```bash
rtk proxy python3 supabase/tests/content_translations.py
rtk proxy psql postgresql://postgres:postgres@127.0.0.1:54322/postgres -X -v ON_ERROR_STOP=1 -f supabase/tests/admin_prompt_translations.sql
rtk proxy supabase db lint --local --schema public,private --level warning --fail-on warning
rtk proxy supabase db advisors --local --type all --level warn --fail-on warn
rtk proxy supabase migration list --local
```

- Admin: **52/52 tests đạt**. Bao phủ API/schema, độc lập locale giao diện, lưu một translation, giữ draft khác, ngôn ngữ thứ ba, version trả về, lỗi/retry, xung đột/reload, background refetch, chặn bấm lặp và delete/leave/logout guards.
- Navigation test compile template thật: cả hai editor giữ draft Việt qua lần lưu English đầu tiên và chuyển create → edit trong AdminShell.
- Full typecheck gồm app và node/test config, cùng Vite build local đạt; đã hết lỗi chuyển tiếp của Phase 3.
- Migration rehearsal: **6 nhóm unittest đạt** trên disposable copies, gồm replay Phase 4 cho DB rỗng và dữ liệu cũ, các SQL suites và **8 concurrency races**. Không reset hoặc thay dữ liệu gốc local.
- SQL suite mới kiểm cả hai loại đề: đếm đề gốc, sort/pagination/empty page, missing translations, trạng thái độc lập, search đúng locale/cả hai câu/literal ký tự đặc biệt, filters và từ chối anon/người ngoài/admin bị thu hồi.
- DB lint/advisors không có warning/error; local migration ledger khớp.
- Storage HTTP integration đạt: draft bị chặn, publish cho phép đọc, archive/publish lại, xóa đề giữ bytes nhưng chặn truy cập mới, signed URL cũ giữ hiệu lực, người ngoài không upload và admin bị thu hồi không đọc được. Fixture đã chuyển sang RPC và dùng version gốc; cleanup khóa category trước khi xóa.
- Một lần chạy Storage đầu dùng sai version trong fixture đã timeout; đã sửa fixture, chạy lại đạt và dọn đúng dữ liệu tạm để DB về **3 danh mục, 1 đề từ, 1 đề câu hỏi**, không còn user Storage test.

## Còn lại

Không kiểm được giao diện trực tiếp bằng bàn phím hoặc viewport 390px: inventory công cụ không có browser surface; Chrome native trả `cgWindowNotFound`. Template/navigation tests không thay thế kiểm tra visual/accessibility thực tế; chuyển mục kiểm tra này sang Phase 5.

Dashboard locale/statistics và kiểm thử tích hợp mở rộng vẫn thuộc Phase 5; triển khai cloud/backup/cutover thuộc Phase 6. Không thêm dependency hoặc framework editor dùng chung.
