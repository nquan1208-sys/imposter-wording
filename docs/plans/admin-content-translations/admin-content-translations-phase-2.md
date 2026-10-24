# Phase 2 — Schema, bảo mật và API DB

Hoàn tất local ngày 2026-10-24. Migration: [20261024045640_content_translations.sql](../../../supabase/migrations/20261024045640_content_translations.sql).

## Kết quả chuyển đổi

| Loại | Dòng nguồn | Bản gốc thực tế | Bản dịch thực tế |
| --- | ---: | ---: | ---: |
| Danh mục | 3 | 3 | 3 |
| Đề từ | 1 | 1 | 1 |
| Đề câu hỏi | 1 | 1 | 1 |

- Đủ `vi`, `en` trong `content_languages`; dữ liệu hiện chỉ có bản dịch `vi`. Không tạo bản dịch rỗng, ghép ID hoặc đổi liên kết danh mục.
- Cả ba bản dịch danh mục là `published`; hai bản dịch đề giữ `published`. Không đổi slug trong baseline local.
- Giữ ba Storage objects, một ảnh đang tham chiếu và hai ảnh chưa được tham chiếu. Không upload, xóa hoặc di chuyển bytes ảnh.
- Dựng lại cả năm dòng nguồn từ bản gốc và bản dịch: toàn bộ MD5 JSON khớp manifest Phase 1. Migration kiểm tra riêng metadata trên cả hai bản, counts, ID/locale, slug mapping và tập Storage objects trước khi bỏ cột cũ.
- Migration có transaction và khóa dữ liệu nguồn; blocker hoặc đối chiếu sai sẽ rollback. Không sửa migration lịch sử hoặc dùng `DROP ... CASCADE` trong migration.
- Đã tạo backup local trước khi áp dụng tại `/tmp/imposter-wording-phase2-before.dump`, quyền file `0600`. Đây là backup tạm ngoài repo; quy trình backup/rollback triển khai vẫn thuộc Phase 6.

## Schema và quyền đọc

`content_languages(code, display_name, sort_order)` là nguồn danh sách ngôn ngữ; đọc theo `sort_order, code`. Thêm ngôn ngữ bằng dữ liệu do người vận hành có quyền DB thực hiện.

Ba bảng bản dịch dùng khóa ghép `(category_id, locale)` hoặc `(prompt_id, locale)`, FK đến danh sách ngôn ngữ và cascade khi xóa bản gốc. Bản gốc giữ các trường chung; cả hai phía có `created_by`, `created_at`, `updated_at`.

- `anon` và `authenticated` có SELECT rõ ràng, không có direct INSERT/UPDATE/DELETE/TRUNCATE trên bảy bảng nội dung. Admin đang hoạt động đọc tất cả nội dung qua RLS.
- Đọc công khai bản dịch đề yêu cầu đề `published`, danh mục bật và bản dịch danh mục cùng locale `published`. Bản gốc chỉ hiện nếu có ít nhất một bản dịch đủ điều kiện. Không fallback locale.
- Helper trong schema `private` chỉ trả boolean eligibility và tránh vòng lặp RLS giữa bản gốc/bản dịch. RPC ghi dùng `SECURITY DEFINER`, search path rỗng và kiểm/khóa grant admin từ `admin_users`, không tin quyền cũ trong JWT.
- Ảnh được đọc công khai khi đề có ít nhất một bản dịch đủ điều kiện. Giữ bucket private, giới hạn 5 MiB, JPEG/PNG/WebP, quy tắc path, upload và cleanup. Signed URL đã phát vẫn có thể tồn tại đến hết hạn.

## Hợp đồng RPC cho Phase 3–5

### Lưu

Ba RPC đều nhận UUID `p_id` do caller cung cấp, `p_locale`, `p_status`, `p_expected_updated_at` và các trường dưới đây:

| RPC | Trường chung | Trường bản dịch |
| --- | --- | --- |
| `save_category` | `p_game_type`, `p_slug`, `p_sort_order`, `p_is_active` | `p_name`, `p_description` |
| `save_word_prompt` | `p_category_id`, `p_difficulty`, `p_is_family_friendly`, `p_image_path` | `p_text` |
| `save_question_prompt` | `p_category_id`, `p_difficulty`, `p_is_family_friendly` | `p_civilian_question`, `p_imposter_question` |

- Truyền đầy đủ args. `p_expected_updated_at = null` chỉ tạo mới; cập nhật phải truyền chính xác phiên bản bản gốc. `p_description` và `p_image_path` nhận null.
- Response JSON là `{ original, translation }`, chứa row đã lưu; dùng `original.updated_at` trả về cho lần lưu tiếp theo. Không dùng timestamp tự tạo ở browser.
- Lưu phần chung và đúng một bản dịch trong transaction. Mọi thay đổi bản dịch tăng phiên bản bản gốc; không sửa nội dung/metadata các bản dịch khác. Không tự tạo bản dịch cho tab chưa nhập.
- RPC đặt metadata server-side, giữ metadata tạo khi sửa; game type của danh mục không đổi. Trim Unicode whitespace, chặn nội dung rỗng, câu hỏi trùng sau trim/lowercase, locale không tồn tại, ảnh sai chủ sở hữu/path hoặc object thiếu.
- Lưu bản dịch đề ở trạng thái `published` yêu cầu danh mục đang bật và bản dịch danh mục cùng locale đã xuất bản. Chuyển category trên đề kiểm tất cả locale đang `published`.
- Thứ tự khóa: grant admin → categories theo UUID → bản gốc → bản dịch. Các thay đổi cùng danh mục được tuần tự hóa để ổn định điều kiện xuất bản và delete preview; chỉ cần khóa nhỏ hơn nếu đo được contention admin.
- SQLSTATE: `42501` thiếu quyền; `40001` phiên bản cũ hoặc tạo trùng ID; `P0002` không còn bản ghi; `23514` sai điều kiện/nội dung; `23503` FK sai; `23502` thiếu trường bắt buộc; `23505` trùng khóa/slug. Locale lạ khi yêu cầu publish có thể bị chặn bởi điều kiện xuất bản trước FK.

TypeScript types đã sinh lại bằng script hiện có. CLI không thể hiện nullability của RPC args; khi cập nhật `AdminDatabase` ở các phase admin, cần mở rộng nullable args theo pattern `delete_category` đang có, không sửa tay generated types hoặc ép null thành chuỗi.

### Xóa, preview và dashboard

- Giữ `delete_word_prompt(uuid,timestamptz)` và `delete_question_prompt(uuid,timestamptz)`: yêu cầu version bản gốc, cascade mọi bản dịch, giữ file Storage.
- `preview_category_delete(p_id)` trả `{ category, category_translations, counts, version }`. `counts.originals` có `total`, `word`, `question`; `counts.translations` đếm **bản dịch đề** theo `draft`, `published`, `archived`.
- Version preview bao gồm toàn bộ row danh mục, các bản dịch danh mục, đề gốc và các bản dịch đề. Sửa bất kỳ thành phần nào làm preview cũ không còn hợp lệ.
- Giữ `delete_category(p_id,p_mode,p_target_id default null,p_expected_version default null)`. `transfer` và `purge` bắt buộc version preview; `empty` có thể bỏ version, nhưng nếu truyền thì phải khớp. Transfer yêu cầu danh mục đích khác nguồn, đang bật, cùng game type và đã xuất bản mọi locale đề đang xuất bản. Purge cascade đủ bản dịch, giữ ảnh.
- Thay SQL dashboard ngay trong Phase 2 vì routine cũ phụ thuộc các cột bị bỏ: `admin_dashboard_summary(p_locale text default 'vi')`. Chỉ đếm bản dịch locale đang chọn; items có `locale`, category name không fallback và có thể null nếu thiếu bản dịch. Active-category count tính danh mục bật với bản dịch locale đã xuất bản; empty-category warning tính các danh mục có bản dịch locale nhưng chưa có bản dịch đề locale đó. Locale không tồn tại trả `22023`. UI/cache dashboard vẫn thuộc Phase 5.

## Kiểm thử đã chạy

Rehearsal trên DB copies độc lập trong container local, không reset DB đang dùng:

```bash
rtk proxy python3 supabase/tests/content_translations.py
```

Đạt 4 nhóm unittest: replay lịch sử trên DB nội dung rỗng; backfill nhiều locale/trạng thái/metadata và slug trùng; sáu loại blocker rollback cả schema/data; bản sao dữ liệu local và concurrency. Runner tạo và tự xóa DB copies, chạy SQL suites trên các bản migrated.

SQL suites dùng fixtures rollback: `category_management.sql`, `word_prompt_management.sql`, `question_prompt_management.sql`, `admin_dashboard.sql`, `content_translations.sql`. Chạy riêng từ repo root, với connection DB local đã cấu hình trong `DB_URL`:

```bash
rtk proxy psql "$DB_URL" -X -v ON_ERROR_STOP=1 -f supabase/tests/content_translations.sql
rtk proxy python3 supabase/tests/category_concurrency.py
rtk proxy supabase db lint --local --schema public,private --level warning --fail-on warning
rtk proxy supabase db advisors --local --type all --level warn --fail-on warn
rtk proxy supabase migration list --local
```

- Năm SQL suites đạt trên bản sao và DB local sau migration. Bao phủ save nguyên tử, validation, uniqueness, quyền trực tiếp/RPC, RLS nhiều locale, thu hồi admin với JWT cũ, image eligibility, preview, transfer/purge và thêm ngôn ngữ bằng dữ liệu.
- Bảy race đạt: xóa category/tạo đề; hai save khác locale cùng version cho từng loại đề; sửa translation/purge preview cũ; publish/archive category translation; transfer/archive đích; revoke admin/save đang chờ. Không có deadlock.
- DB lint không có lỗi; advisors không có warning/error. Migration ledger local khớp file mới.
- Đã chạy lại sáu Phase 1 audit tests trước migration. Script audit cũ cần schema cũ; không chạy trực tiếp trên schema Phase 2.
- Đã chạy `yarn types:database`; generated types phản ánh đúng tables và RPC mới.

## Phần chuyển tiếp

Theo ranh giới được chốt, Phase 2 chỉ hoàn tất DB contract. Admin API/forms/types dẫn xuất và TypeScript fixtures cũ sẽ được chuyển ở Phase 3–5. Đã chạy `yarn typecheck`: exit 2 với 90 diagnostics do callers/types cũ còn tham chiếu các cột đã bỏ. Chưa chạy admin build/browser UAT hay Storage HTTP integration; đã kiểm Storage policies trực tiếp trên DB. Chưa triển khai hoặc thay đổi cloud.

Không dùng admin cũ để ghi với schema mới. Triển khai DB và admin hoàn chỉnh cùng đợt ở Phase 6; chạy lại audit/rehearsal trên dữ liệu đích trước khi triển khai.
