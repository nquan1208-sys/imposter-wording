# Phase 5 — Dashboard và kiểm thử tích hợp

Đã triển khai và kiểm thử tự động trên local ngày 2026-10-24. Kiểm tra trực tiếp bằng bàn phím đạt một phần; chưa đóng phase vì còn kiểm tra viewport 390px và một số luồng giao diện. Chưa triển khai cloud.

## Dashboard và cache

- Bộ chọn dùng `content_languages`, mặc định `vi`, lưu trong query URL `locale`; mã không tồn tại chuyển về `vi` sau khi tải danh sách. Ngôn ngữ nội dung độc lập ngôn ngữ giao diện, không fallback nội dung.
- API `getDashboardSummary(client, locale = 'vi')` gửi `p_locale` vào RPC đã có từ Phase 2. `DashboardItem` có `locale` và `category_name: string | null` theo JSON thực tế.
- Summary chỉ tải khi locale đã xác thực; cache key là `['dashboard', 'summary', locale]`. Chuyển ngôn ngữ không hiển thị kết quả ngôn ngữ trước dưới lựa chọn mới. Lỗi tải ngôn ngữ và summary đều có thử lại.
- Recent/draft mở đúng tab bằng locale của item. Liên kết danh sách và cảnh báo mang locale đang chọn, giữ các bộ lọc draft/difficulty/family hiện có.
- Giữ nguyên nghĩa thống kê của RPC: đếm trạng thái bản dịch trong locale chọn. Đề có trạng thái `published` vẫn được thống kê khi danh mục bị tắt/lưu trữ; quyền đọc công khai vẫn áp dụng các điều kiện riêng.
- Giữ invalidation theo prefix đã có. Tests xác nhận lưu thông tin chung/bản dịch, bật/tắt danh mục, transfer/purge, archive và xóa hai loại đề làm stale caches danh mục, hai loại đề và dashboard cho cả `vi`, `en`, ngôn ngữ thứ ba.

## Sửa lỗi conflict phát hiện qua HTTP

Storage integration cố ý gửi version cũ sau upload đã tái hiện request timeout thay vì trả lỗi conflict. Nguyên nhân là RPC dùng SQLSTATE `40001` cho xung đột phiên bản do ứng dụng phát hiện; PostgREST retry lỗi này. Đây là [lỗi được Supabase mô tả](https://supabase.com/kb/troubleshooting/high-cpu-and-infinite-transaction-retries-when-using-custom-error-codes-in-rpc-functions).

- Forward migration [20261024093556_admin_content_conflict_errors.sql](../../../supabase/migrations/20261024093556_admin_content_conflict_errors.sql) đổi literal lỗi explicit conflict sang `PT409` trong bảy RPC: ba save, ba delete và bật/tắt danh mục.
- Migration dùng `CREATE OR REPLACE` từ định nghĩa hiện tại, chỉ thay literal SQLSTATE; giữ signatures, locks, validation, security attributes và grants. Không sửa migration lịch sử hoặc đổi database types.
- Admin nhận `PT409` là conflict và vẫn hiểu `40001` để tương thích. Tests editor dùng mã mới và giữ hành vi chặn lưu/xóa đến khi explicit reload.
- Suite mới `admin_content_conflicts.sql` yêu cầu chính xác `PT409` ở cả bảy RPC và kiểm tra không ghi dở shared fields/bản dịch. Helpers và concurrency suites hiểu cả mã cũ/mới để rehearsal các mốc migration trước vẫn chạy được.
- Đã áp dụng migration bằng psql local và ghi ledger với `supabase migration repair --local --status applied 20261024093556`. Không reset DB local.

## Kiểm thử tự động

Từ thư mục `admin`:

```bash
rtk proxy yarn test
rtk proxy yarn build:local
rtk proxy yarn test:storage
```

Từ repo root:

```bash
rtk proxy python3 supabase/tests/content_translations.py
rtk proxy psql postgresql://postgres:postgres@127.0.0.1:54322/postgres -X -v ON_ERROR_STOP=1 -f supabase/tests/admin_dashboard.sql
rtk proxy psql postgresql://postgres:postgres@127.0.0.1:54322/postgres -X -v ON_ERROR_STOP=1 -f supabase/tests/admin_content_conflicts.sql
rtk proxy supabase db lint --local --schema public,private --level warning --fail-on warning
rtk proxy supabase db advisors --local --type all --level warn --fail-on warn
rtk proxy supabase migration list --local
```

- Admin **57/57 tests đạt**: dashboard API, URL/cache theo locale, thiếu tên danh mục, link đúng tab, loading/error/retry, lỗi discovery ngôn ngữ, độc lập locale giao diện, ngôn ngữ thứ ba, invalidation và conflict/reload.
- Full typecheck app/node/tests và Vite build local đạt. Vẫn có cảnh báo bundle admin lớn hơn 500 kB; không thêm dependency hoặc thay cấu trúc bundle trong phase này.
- Migration rehearsal **6 nhóm unittest đạt**, replay DB rỗng và dữ liệu cũ, đối chiếu nội dung/metadata/ID/trạng thái/Storage, chạy các SQL suites qua toàn bộ forward migrations và **8 concurrency races**. Disposable copies được dọn sau kiểm thử.
- SQL dashboard mở rộng xác nhận ngôn ngữ thứ ba, thống kê/cảnh báo độc lập, draft links, panel tối đa 5 item và tên danh mục nullable. Các suites hiện có tiếp tục bao phủ validation, quyền đọc/ghi, revoked admin, atomic save, stale preview, transfer/purge và xung đột nhiều tab.
- Storage HTTP integration đạt: Việt published/Anh draft; archive Việt chặn ảnh; publish Anh cho đọc lại; archive bản dịch danh mục hoặc tắt danh mục chặn ảnh; khôi phục cho đọc lại. Save conflict dọn đúng ảnh mới upload, upload không có quyền không để lại file, ảnh chung cũ vẫn đọc được. Xóa đề giữ bytes, chặn truy cập mới và giữ hiệu lực signed URL đã cấp.
- Lần chạy Storage trước sửa mã lỗi đã timeout và thất bại; sau migration suite đạt trong khoảng 2 giây.
- DB lint/advisors không có warning/error; migration ledger local khớp. Sau cleanup còn **3 danh mục, 1 đề từ, 1 đề câu hỏi**, không có tài khoản Storage test hoặc rehearsal DB.

## Kiểm tra trực tiếp và phần còn lại

Chrome native truy cập được trong phiên này, dù browser inventory không có browser surface:

- Dashboard mặc định Việt hiển thị thống kê; chuyển English bằng bàn phím cập nhật URL, số liệu và links đúng locale. Tab đến link danh sách có focus rõ; Enter mở list English với nhãn thiếu bản dịch.
- Mở tab English đang thiếu của đề từ: nhập draft tạm, chuyển Việt rồi dùng phím Right trở lại English giữ nguyên draft. Rời trang hiện cảnh báo; Cancel giữ nội dung. Draft tạm đã bỏ, không thay dữ liệu đề gốc.
- Tạo một đề câu hỏi tạm qua UI, lưu draft và chuyển create → edit, publish bằng bàn phím rồi archive qua hộp xác nhận. DB xác nhận trạng thái archived; fixture đã dọn bằng đúng ID sau kiểm thử.
- Chưa xác minh viewport **390px**: DevTools toggle không hiện controls responsive, coordinate click/drag báo `noWindowsAvailable`; một lần capture trả `SCStreamErrorDomain -3811`, ảnh chụp có lúc giữ nội dung cũ dù AX đã cập nhật. Không coi các capture này là bằng chứng hoàn tất visual QA.
- Còn cần kiểm trực tiếp layout 390px của dashboard/danh mục/hai editor, vòng đời danh mục và đầy đủ luồng upload/save thất bại trong editor từ ngữ. Những luồng dữ liệu tương ứng đã có kiểm thử tự động, nhưng chưa thay thế kiểm tra giao diện thật.

Phase 5 giữ trạng thái **đã triển khai, chưa hoàn tất manual verification**. Backup, cutover và triển khai cloud vẫn thuộc Phase 6.
