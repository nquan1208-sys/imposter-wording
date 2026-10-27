# Family Mode theo danh mục từ ngữ

Hợp đồng hiện hành từ migration `20261027050239_category_family_mode.sql`.

- `game_categories.is_family_friendly`: boolean, NOT NULL, mặc định false; CHECK chỉ cho `game_type = 'word'` bật cờ. Cờ dùng chung cho mọi bản dịch.
- Migration giữ nguyên danh mục, prompt, bản dịch và ảnh. Mọi danh mục cũ đều tắt Family để admin duyệt lại; không chuyển cờ từ prompt lên danh mục.
- `word_prompts` và `question_prompts` không còn `is_family_friendly`.
- Admin quản lý cờ, cột và bộ lọc Family ở danh mục. Prompt và dashboard không còn trường/bộ lọc/cảnh báo Family.

## RPC

Giữ tên RPC, thay chữ ký; không giữ overload cũ:

```sql
save_category(p_id uuid, p_game_type game_type, p_slug text,
  p_sort_order integer, p_is_active boolean, p_is_family_friendly boolean,
  p_locale text, p_name text, p_description text, p_status content_status,
  p_expected_updated_at timestamptz)

admin_list_categories(p_locale text, p_search text, p_game_type game_type,
  p_is_active boolean, p_is_family_friendly boolean, p_sort text, p_page integer)

save_word_prompt(p_id uuid, p_category_id uuid, p_difficulty difficulty_level,
  p_image_path text, p_locale text, p_text text, p_status content_status,
  p_expected_updated_at timestamptz)

save_question_prompt(p_id uuid, p_category_id uuid, p_difficulty difficulty_level,
  p_locale text, p_civilian_question text, p_imposter_question text,
  p_status content_status, p_expected_updated_at timestamptz)

admin_list_word_prompts(p_locale text, p_search text, p_category_id uuid,
  p_difficulty difficulty_level, p_status content_status, p_sort text, p_page integer)

admin_list_question_prompts(p_locale text, p_search text, p_category_id uuid,
  p_difficulty difficulty_level, p_status content_status, p_sort text, p_page integer)
```

Bộ lọc nullable nghĩa là tất cả. Giữ phân trang 20 dòng, kiểm tra admin đang hoạt động, khóa giao dịch, bản dịch độc lập và `PT409` khi phiên bản gốc đã thay đổi. RPC quản trị chỉ cấp EXECUTE cho authenticated và vẫn kiểm tra quyền admin trong hàm.

## App

Màn danh mục từ ngữ có hai tab: **Tất cả danh mục** (gồm cả gia đình) và **Chế độ gia đình** (chỉ danh mục bật cờ và có từ hợp lệ). Family lấy toàn bộ từ hợp lệ trong danh mục, không lọc độ khó hay cờ prompt. Số lượng trên thẻ dùng cùng quy tắc.

Tab, danh mục và **Hiển thị ảnh** là bản nháp, ghi chung một lần khi **Xác nhận**. Quay lại hủy bản nháp; lỗi ghi giữ nguyên cấu hình cũ và màn chọn để thử lại. Đổi tab loại danh mục không hợp lệ và thông báo; không chọn mục cụ thể nghĩa là tất cả trong tab. Tab gia đình rỗng có thông báo, không bắt đầu ván khi không có từ.

Nhớ lựa chọn ảnh nhưng chỉ hiển thị khi chơi từ ngữ ở chế độ gia đình. Trò câu hỏi không có tab Family hay lọc Family; chuyển sang câu hỏi hoặc khôi phục cấu hình câu hỏi cũ đưa mode về thường. Cache cũ thiếu cờ danh mục mặc định false, bỏ qua cờ prompt cũ và vẫn chơi offline ở tab tất cả.

## Áp dụng local và xác minh

1. Sao lưu toàn bộ DB trước khi chạy migration bằng `pg_dump -Fc`; lưu bản sao bên ngoài Git.
2. Chạy `supabase migration up --local`, không reset. Sinh types bằng `cd admin && yarn types:database`.
3. Chạy `python3 supabase/tests/content_translations.py`: diễn tập trên DB sao chép dùng một lần, kiểm tra backfill, dữ liệu, SQL và cạnh tranh khóa.
4. Chạy `supabase db lint --local` và `supabase db advisors --local --type security`.
5. Admin: `yarn test`, `yarn build:local` (gồm typecheck). App: `flutter analyze`, `flutter test`.
6. Chạy các kiểm tra HTTP theo `postman/simulations/phase-7.context.md` khi cần xác minh Supabase client qua mock HTTP.

Chỉ áp dụng local trong thay đổi này. Cloud cần triển khai DB, admin và app cùng hợp đồng: client cũ sẽ lỗi vì cột và chữ ký RPC cũ đã bị xóa. Tab gia đình rỗng cho tới khi admin bật danh mục.
