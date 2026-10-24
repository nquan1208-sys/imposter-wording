# Phase 1 — Kiểm kê và chốt migration nội dung đa ngôn ngữ

Ngày kiểm kê: 2026-10-24. Phạm vi: local Supabase của repo `imposter-wording`.

## Kết quả và cách chạy lại

Đã chạy [audit SQL](../supabase/scripts/audit_content_translations.sql) bằng role `postgres`, transaction `REPEATABLE READ READ ONLY`, kết thúc bằng `ROLLBACK`. Không thay schema, nội dung, quyền hoặc file Storage. Audit trả hai dòng JSON: dữ liệu/ánh xạ dự kiến và catalog dependencies. Chạy từ thư mục gốc:

```bash
# Local: nhập password DB local khi psql yêu cầu.
rtk proxy psql -X -qAt -h 127.0.0.1 -p 54322 -U postgres -d postgres \
  -v ON_ERROR_STOP=1 -f supabase/scripts/audit_content_translations.sql

# Tự lấy connection local từ supabase status; không in credential.
rtk proxy python3 supabase/tests/audit_content_translations.py
```

Với DB khác, dùng connection qua `DB_URL` đã cấu hình riêng:

```bash
rtk proxy psql "$DB_URL" -X -qAt -v ON_ERROR_STOP=1 \
  -f supabase/scripts/audit_content_translations.sql
# Tests cũng nhận DB_URL; fixtures chỉ tồn tại trong CTE, không ghi vào DB.
rtk proxy python3 supabase/tests/audit_content_translations.py
```

Chỉ nhận kết quả audit khi `rls_bypassed = true`, `read_only = on`, `isolation = repeatable read`, và `blockers = []`. Nếu có blocker, dừng chốt migration; không loại dòng lỗi khỏi backfill. Audit cần schema cũ với đủ migration đến `20261021163720`; không dùng lại nguyên script sau khi Phase 2 bỏ cột cũ. Catalog của SQL/PLpgSQL không ghi đủ mọi dependency trong thân hàm, vì vậy audit xuất toàn bộ routines `public`/`private`, cộng routines của trigger trên các bảng được kiểm kê.

### Số lượng nguồn và đích dự kiến

| Loại | Nguồn hiện tại | Bản gốc dự kiến | Bản dịch dự kiến | Locale nguồn | Trạng thái bản dịch dự kiến |
| --- | ---: | ---: | ---: | --- | --- |
| Danh mục | 3 | 3 | 3 | `vi` | 3 `published` (quy tắc backfill mới) |
| Đề từ | 1 | 1 | 1 | `vi` | 1 `published` (giữ nguyên) |
| Đề câu hỏi | 1 | 1 | 1 | `vi` | 1 `published` (giữ nguyên) |

Đây là **số lượng đích dự kiến**, chưa phải kết quả migration. Cả ba danh mục đang bật: hai loại `word`, một loại `question`. Không có bản nháp/lưu trữ trong baseline; các trạng thái này được kiểm tra bằng CTE fixtures.

| Category ID | Loại | Đề từ | Đề câu hỏi | Tham chiếu ảnh |
| --- | --- | ---: | ---: | ---: |
| `05e3818b-1a72-45d2-94e0-b2ab68d14512` | question | 0 | 1 | 0 |
| `55660f48-084b-4a10-9fcc-383858bd73ec` | word | 1 | 0 | 1 |
| `78abddb8-12a6-4da2-b49a-a24515336446` | word | 0 | 0 | 0 |

- Locale thực tế: chỉ `vi`; danh sách ngôn ngữ đích: `vi`, `en`. Chưa tạo bản dịch `en` rỗng.
- Không trùng slug khi bỏ locale; không có slug phải đổi trong baseline này.
- Không phát hiện nội dung rỗng, câu hỏi giống nhau, liên kết sai loại/locale, hoặc ảnh tham chiếu bị thiếu/sai đường dẫn.
- Bucket `word-prompt-images` có 3 objects, một object đang được tham chiếu và **2 objects không có tham chiếu hiện tại**. Giữ nguyên cả ba; không suy đoán hai object còn lại là rác.
- Bucket private, giới hạn 5 MiB, MIME JPEG/PNG/WebP. Audit kiểm tra metadata object và đường dẫn, chưa tải/giải mã bytes ảnh.
- Lịch sử local có đủ 10 migrations từ `20261003072606` đến `20261021163720`. Đây là đối chiếu ledger và catalog hiện tại, không phải chứng minh mọi migration đã được áp dụng giống hệt nội dung file.

### Manifest nguồn

`source_md5` được tính bằng `md5(to_jsonb(row)::text)`, bao gồm toàn bộ trường nguồn và metadata; dùng kiểm tra toàn vẹn, không dùng làm cơ chế bảo mật. Không xuất nội dung đề hay ID người tạo vào báo cáo.

| Loại | ID nguồn = ID bản gốc đích | source_md5 |
| --- | --- | --- |
| category | `05e3818b-1a72-45d2-94e0-b2ab68d14512` | `530c3f4e712561449d30d6bc38e4b992` |
| category | `55660f48-084b-4a10-9fcc-383858bd73ec` | `e435410e60f74a95d49ca39b6172cee9` |
| category | `78abddb8-12a6-4da2-b49a-a24515336446` | `6fc6bda12f0aec377d514be9ff9bf4c3` |
| question | `0adbb3fb-1498-48dd-972f-a6baf26a6a36` | `cd307a4814867d2ccd40af8f98e500b0` |
| word | `fa776d42-af60-437f-b488-2fe0f70b84c1` | `f2959d0d605d63f22e71b1de1d0e3754` |

Đề câu hỏi thuộc category `05e3818b-1a72-45d2-94e0-b2ab68d14512`; đề từ thuộc `55660f48-084b-4a10-9fcc-383858bd73ec`. Audit trả mapping đầy đủ theo `(kind, id, locale, category_id, status)` để chạy lại trên dữ liệu khác.

## Hợp đồng backfill cho Phase 2

| Nguồn | Giữ trên bản gốc | Chuyển sang bản dịch |
| --- | --- | --- |
| `game_categories` | `id`, `game_type`, slug sau ánh xạ, `sort_order`, `is_active` | `name`, `description`, `locale`; thêm `status = published` |
| `word_prompts` | `id`, `category_id`, `difficulty`, `is_family_friendly`, `image_path` | `text`, `locale`, `status` |
| `question_prompts` | `id`, `category_id`, `difficulty`, `is_family_friendly` | `civilian_question`, `imposter_question`, `locale`, `status` |

- Mỗi dòng nguồn thành một bản gốc và đúng một bản dịch. Hai dòng khác ID vẫn là hai nội dung độc lập dù văn bản giống nhau hoặc locale khác nhau.
- Giữ nguyên `created_by`, `created_at`, `updated_at` trên bản gốc; sao chép các giá trị này sang bản dịch ban đầu, kể cả `created_by = null`. Backfill phải hoàn thành trước khi bật trigger mới có thể sửa timestamps.
- Không di chuyển/đổi tên/upload lại ảnh. Không đổi liên kết category hay difficulty/family flag. Không phục hồi các cột đã bị migration cũ xóa (`imposter_text`, `imposter_hint`, `civilian_text`).
- Danh mục cũ chưa có status: **mọi bản dịch danh mục nhận `published`**, kể cả khi bản gốc `is_active = false`. Bật lại danh mục sau này vẫn chịu quy tắc công khai của schema mới.
- Seed ngôn ngữ `vi`/`en` với tên `Tiếng Việt`/`English`; lấy hợp tất cả locale thực tế của ba bảng. Mã khác giữ nguyên và dùng mã làm tên hiển thị ban đầu; không tự đổi `vn` thành `vi`, lowercase hay trim. Locale rỗng hoặc có khoảng trắng ngoài phải được báo blocker để xử lý có chủ đích.
- Slug duy nhất theo `(game_type, slug)`. Sắp UUID tăng dần trong mỗi nhóm trùng: dòng đầu giữ slug, mỗi dòng còn lại nhận `<slug>-<UUID đầy đủ>`. Audit trả từng đổi tên trong `slug_changes`. Kiểm tra lại toàn bộ slug kết quả; nếu hậu tố đụng slug sẵn có, báo `resulting_slug_collision` và dừng, không tự đặt thêm hậu tố.
- Không sửa migration cũ. Phase 1 không thay public API/types; các thay đổi schema, RPC và quyền được thực hiện cùng migration ở Phase 2, admin chuyển theo các phase kế tiếp.

## Dependencies và hành động ở các phase sau

### Database hiện tại

Catalog local có 11 constraints, 21 indexes (13 nội dung, 8 Storage), 7 user triggers, 16 policies và 13 routines được xuất. Không thấy view/materialized view phụ thuộc nội dung. Audit cũng xuất table/column grants, RLS flags, columns/defaults và `pg_depend`; cần kiểm tra lại trên DB triển khai.

| Dependency | Hiện trạng và hành động bắt buộc |
| --- | --- |
| `game_categories_slug_locale_key` | Unique `(game_type, slug, locale)`; thay bằng unique `(game_type, slug)` sau mapping. |
| PK, `*_created_by_fkey`, `*_category_id_fkey` | Giữ ID/FK gốc và `ON DELETE SET NULL` của người tạo; thêm FK/unique của bản dịch, cascade cho xóa bản gốc. Không đổi FK Storage. |
| `game_categories_active_sort_order_idx`, `*_created_by_idx`, PK indexes, `word_prompts_image_path_idx` | Giữ các index trên trường chung; tạo index metadata bản dịch khi cần. |
| `*_category_status_difficulty_idx`, `*_status_locale_idx` | Đang dùng status/locale trên đề gốc; thay index phù hợp cho shared fields và bảng dịch trước khi bỏ cột. Giữ indexes Storage do Supabase quản lý. |
| `private.category_before_write` / trigger cùng tên | Đang trim tên/mô tả, kiểm slug/sort_order, cấm đổi game type/locale và set timestamp. Tách validation bản gốc/bản dịch; giữ game type bất biến, chuyển kiểm nội dung và locale sang bảng dịch. |
| `private.word_prompt_before_write`, `private.question_prompt_before_write` / triggers cùng tên | Đang xác nhận category cùng loại/locale và điều kiện publish. Chuyển kiểm nội dung/status sang bản dịch; giữ kiểm ảnh/ownership/path/tồn tại object ở đề gốc, Unicode trim và hai câu khác nhau ở câu hỏi. |
| `private.validate_prompt_category_game_type` / `validate_word_prompt_category_game_type`, `validate_question_prompt_category_game_type` | Giữ kiểm game type trên FK bản gốc; không dùng locale cũ của category. |
| `private.category_content_snapshot(uuid)` | Đang đếm status và hash JSON của đề gốc. Thêm nội dung/bản dịch danh mục và đề vào snapshot; tách số đề gốc khỏi số bản dịch theo status. |
| `public.preview_category_delete(uuid)` | Trả category + snapshot cũ; đổi shape và cập nhật callers/types/fixtures đồng thời. |
| `public.delete_category(uuid,text,uuid,text)` | Bỏ so sánh locale giữa category gốc; transfer kiểm mọi locale đề đã publish ở category đích; purge xóa đủ bản dịch. Giữ khóa admin/parent/children và kiểm snapshot, bổ sung khóa bản dịch. |
| `public.delete_word_prompt(uuid,timestamptz)`, `public.delete_question_prompt(uuid,timestamptz)` | Giữ kiểm active admin/phiên bản/khóa hàng; xóa bản dịch cùng bản gốc. Giữ file Storage. |
| `public.admin_dashboard_summary()` | Đang đếm/title/category name trực tiếp từ bảng cũ. Chuyển sang locale ở Phase 5, thêm `p_locale` và locale cho item trả về. |
| `private.is_admin()` | Giữ tra cứu `admin_users` active thay vì tin quyền JWT cũ. RPC ghi mới phải giữ khóa grant admin như delete RPC hiện có. |
| `storage.protect_delete`, `storage.update_updated_at_column` / hai trigger Storage | Giữ nguyên; không thay code hệ thống của Supabase. |

### Quyền và Storage

- Ba bảng nội dung đều bật RLS. Hiện có bốn policies mỗi bảng: public/authenticated read và admin insert/update. Client authenticated đang có quyền insert/update trực tiếp; delete đã bị thu hồi. Phase 2 thu hồi direct writes và chuyển ghi sang save RPC có kiểm admin, version, validation và transaction.
- Policies đọc danh mục hiện kiểm `is_active`; đọc đề hiện chỉ kiểm `status = published`, chưa ràng buộc category còn bật. Schema mới cố ý siết điều kiện: bản dịch đề publish + category bật + bản dịch category cùng locale publish. Không diễn giải việc siết quyền này thành mất dữ liệu.
- `Word image admin read`, `Word image admin upload`: giữ kiểm admin, path, bucket, MIME/kích thước. `Word image admin cleanup`: giữ cấm xóa file đang được đề gốc tham chiếu. `Word image published read`: thay kiểm status cũ bằng tồn tại ít nhất một bản dịch đủ điều kiện công khai.
- Bucket vẫn private; giữ signed URL 300 giây và hành vi cleanup khi upload/save lỗi. URL đã cấp có thể dùng đến hết hạn; thay policy không thu hồi URL đã phát.
- Audit xuất ACL của routine: năm public RPC hiện chỉ cấp cho authenticated/service_role/postgres; `private.is_admin` cho authenticated/postgres. Hai trigger functions cũ có ACL mặc định (`category_before_write`, `validate_prompt_category_game_type`); rà quyền thực thi rõ ràng khi thay chúng. Không cấp quyền public mặc định cho save RPC mới.

### Admin, tests và tài liệu

| Nhóm | Những nơi phải cập nhật |
| --- | --- |
| Queries / mutations | `admin/src/api/{categories,wordPrompts,questionPrompts,dashboard}.ts`: direct writes, joins tên category, search/sort/filter/count, category options/transfer targets, version check, upload/cleanup và delete preview. Dùng translations và save RPC; phân trang/count theo bản gốc. |
| Forms / UI | Các list/form views trong `admin/src/views/{categories,word-prompts,question-prompts}`; components category table/form/delete và hai prompt delete dialogs. Thêm tabs ngôn ngữ từ DB, giữ drafts theo tab, ghi rõ tác động shared fields/xóa cả translations. Dashboard view thêm locale ở Phase 5. |
| Validation / types | `admin/src/utils/{categories,wordPrompts,questionPrompts}.ts`, `admin/src/types/{admin,database}.ts`: tách shared/translation fields; category hiện hardcode `vi`. Sinh lại database types bằng script hiện có sau schema ổn định. Giữ shared unsaved-changes helper. |
| Cache | Keys hiện có: `categories` list/detail/delete-preview/transfer-targets/word-options/question-options; `word-prompts`, `question-prompts` list/detail; `dashboard/summary`; `word-images` theo path. Thêm locale cho query phụ thuộc ngôn ngữ; invalidate các nhóm liên quan khi sửa category/shared/translation, kể cả dashboard và delete preview. |
| SQL / concurrency fixtures | `supabase/tests/{category_management,word_prompt_management,question_prompt_management,admin_dashboard}.sql`, `category_concurrency.py`: đang insert/query trực tiếp các cột cũ; đổi fixtures và expectations cho translations/RPC, quyền mới và khóa bản dịch. Không sửa lịch sử migration để chiều fixtures. |
| Admin fixtures | `admin/tests/{categories,wordPrompts,questionPrompts,dashboard}.test.ts`, các `*Components.test.ts`, `navigation.test.ts`, `wordStorage.local.ts`: đổi query mocks, payloads, joined rows, cache keys, preview counts và Storage lifecycle assertions. i18n tests kiểm message keys mới khi có thay đổi UI. |
| Config / docs | `supabase/config.toml` trỏ `./seed.sql` nhưng repo không có seed file; fixtures hiện nằm trong tests. Không thêm seed runtime ở Phase 1. Phase 6 cập nhật DBML, hướng dẫn môi trường/setup và triển khai; không thay credentials/environment của admin. |
| Flutter / ngoài repo | Không tìm thấy query nội dung/RPC trong `app/lib`; Flutter hiện ngoài phạm vi. Người dùng xác nhận không có client ngoài repo được biết đến. Locale giao diện admin (`vi`/`en`, file tiếng Việt tên `vn.json`) độc lập với locale nội dung; không đổi mã dữ liệu theo tên file. |

## Đối chiếu bắt buộc khi thực hiện migration

Thực hiện trong cùng transaction migration, sau khi dừng ghi và trước khi bỏ cột cũ:

1. Giữ snapshot đầy đủ các dòng cũ trước backfill. So sánh counts trước/sau theo loại, locale, trạng thái và category; số bản gốc = số dòng cũ, số bản dịch = số dòng cũ cho từng loại.
2. Anti-join hai chiều theo ID bản gốc và `(ID, locale)` bản dịch: không thiếu, không thừa, không trùng, không tự ghép; không chỉ dựa vào tổng số.
3. Join bản gốc/bản dịch rồi dựng lại row JSON đúng các keys/types cũ để so từng trường bằng `IS NOT DISTINCT FROM`. Danh mục dùng `old_slug` từ mapping để dựng lại; status danh mục mới được kiểm riêng là `published`. Kiểm metadata trên **cả hai** bản, giữ nulls và timezone nhất quán khi đối chiếu hash manifest.
4. Kiểm riêng slug đích đúng mapping và unique, danh sách ngôn ngữ giữ đủ mã, toàn bộ FK/category links, ảnh/path và tập objects không thay đổi. Không áp trigger cập nhật timestamp lên metadata backfill.
5. Có bất kỳ chênh lệch/blocker thì raise error để rollback. Chỉ thay dependencies/bỏ cột cũ khi tất cả assertions đạt; không dùng `DROP ... CASCADE` để bỏ dependency chưa kiểm kê.

## Kiểm thử và phần còn lại

Đã đạt **6 tests** trong `supabase/tests/audit_content_translations.py`: dữ liệu rỗng; đủ trạng thái, nhiều locale và thứ tự UUID; slug kết quả đụng slug sẵn có; nội dung/locale/link/ảnh không hợp lệ; ảnh giữ lại và FK thiếu; chạy audit live hai lần với dữ liệu/catalog không đổi, read-only và snapshot isolation đúng. Fixtures dùng typed JSON recordsets trong CTE, không insert fixture hoặc sửa schema.

Đã hoàn tất kiểm kê local và hợp đồng migration của Phase 1. Chưa chạy migration/backfill thật nên chưa xác nhận số lượng đích thực tế; việc đó thuộc Phase 2. Không chạy admin build, Storage integration hay concurrency suite vì chưa đổi runtime/schema.

Dev cloud `imposter-word` (`pxycsjwjakzehcuygngv`) đang inactive theo Supabase project inventory lúc lập kế hoạch; không resume project hoặc query dữ liệu cloud. Trước triển khai phải chạy lại audit trên DB đích/bản sao hiện hành, kiểm kê dependencies phát sinh và rehearsal theo Phase 6. Baseline local nhỏ không đại diện dữ liệu cloud.
