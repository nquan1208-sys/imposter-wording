# Quản lý nội dung đa ngôn ngữ — Admin và DB

Ngày lập: 2026-10-24

## Mục tiêu và quyết định đã chốt

Chuyển danh mục, đề từ và đề câu hỏi sang mô hình **bản gốc + bảng bản dịch**. Admin mở một nội dung, thêm và chỉnh sửa các bản ngôn ngữ trong cùng màn hình.

- Ban đầu hỗ trợ `vi`, `en`; thêm ngôn ngữ bằng dữ liệu, không thêm cột DB.
- Mỗi bản dịch có trạng thái riêng: `draft`, `published`, `archived`.
- Ảnh, độ khó, nhãn gia đình và danh mục thuộc đề gốc, dùng chung.
- Không bắt buộc có bản Việt; không tự thay nội dung thiếu bằng ngôn ngữ khác.
- Giới hạn ở admin và DB; chưa triển khai lấy đề trong Flutter, dịch tự động hoặc quản lý ngôn ngữ bằng giao diện.
- Các phase được phát triển và kiểm thử tuần tự; triển khai DB và admin cùng đợt khi hoàn tất.

## Phase 1 — Kiểm kê dữ liệu và chốt migration

**Đã hoàn tất trên local (2026-10-24):** [Báo cáo kiểm kê, dependencies và hợp đồng migration](./admin-content-translations-phase-1.md). Có audit SQL chỉ đọc và tests; số lượng đích hiện là dự kiến. Đối chiếu backfill thật thuộc Phase 2, audit DB triển khai phải chạy lại trước Phase 6.

### Công việc

- Kiểm kê dữ liệu theo ngôn ngữ, trạng thái, danh mục và ảnh; rà soát tất cả truy vấn, trigger, RLS, RPC và fixtures phụ thuộc các cột sẽ chuyển.
- Kiểm tra mã ngôn ngữ thực tế trước khi tạo danh sách ngôn ngữ; giữ lại tất cả mã đang có.
- Mỗi bản ghi hiện tại trở thành một bản gốc và một bản dịch tương ứng. Giữ nguyên ID gốc, liên kết danh mục, đường dẫn ảnh và người tạo.
- Không tự ghép hai bản ghi Việt–Anh thành cùng một đề hoặc danh mục vì hiện chưa có liên kết đáng tin cậy.
- Bản dịch danh mục cũ nhận trạng thái `published`; giữ nguyên `is_active` trên bản gốc, kể cả danh mục đang tắt.
- Slug trở thành mã dùng chung của danh mục, duy nhất theo loại trò chơi. Nếu trùng khi bỏ `locale`, giữ slug cho ID nhỏ nhất, thêm hậu tố UUID đầy đủ cho các bản còn lại và ghi rõ trong báo cáo chuyển đổi.

### Tiêu chí hoàn thành

Có đối chiếu số lượng trước/sau và không có dữ liệu bị bỏ qua hoặc tự suy đoán ghép bản dịch.

## Phase 2 — Schema, bảo mật và API DB

**Đã hoàn tất trên local (2026-10-24):** [Báo cáo migration, hợp đồng RPC và kiểm thử](./admin-content-translations-phase-2.md). Đã áp dụng migration, đối chiếu đủ 5 dòng nguồn, sinh lại database types; SQL suites, concurrency, DB lint và advisors đạt. Theo ranh giới đã chốt, admin callers/UI và fixtures TypeScript chuyển ở Phase 3–5; admin hiện chưa tương thích với schema mới, typecheck chưa đạt. Chưa triển khai cloud.

### Cấu trúc mới

| Bảng | Dữ liệu chính |
| --- | --- |
| `content_languages` | Mã ngôn ngữ, tên hiển thị, thứ tự |
| `game_categories` | ID, loại trò chơi, slug, thứ tự, bật/tắt |
| `game_category_translations` | Category ID, locale, tên, mô tả, trạng thái |
| `word_prompts` | ID, category ID, độ khó, nhãn gia đình, ảnh |
| `word_prompt_translations` | Prompt ID, locale, nội dung từ, trạng thái |
| `question_prompts` | ID, category ID, độ khó, nhãn gia đình |
| `question_prompt_translations` | Prompt ID, locale, hai câu hỏi, trạng thái |

Giữ metadata tạo/cập nhật trên bản gốc và bản dịch; mỗi cặp nội dung–ngôn ngữ là duy nhất, `locale` tham chiếu `content_languages`.

### Hành vi và giao diện API

- Thêm RPC lưu cho từng loại nội dung: nhận dữ liệu chung, một bản dịch đang chỉnh sửa và phiên bản dự kiến; lưu toàn bộ trong một transaction.
- Mỗi thay đổi bản dịch cập nhật `updated_at` của bản gốc. RPC dùng phiên bản này để chống ghi đè giữa nhiều tab.
- Chỉ admin đang hoạt động được ghi; không cho client ghi trực tiếp vào các bảng nội dung. RPC kiểm tra quyền và dữ liệu đầy đủ.
- Bản dịch đã lưu phải có nội dung hợp lệ; đề câu hỏi vẫn yêu cầu hai câu khác nhau. Tab chưa nhập không tạo bản ghi rỗng.
- Xuất bản đề yêu cầu danh mục đang bật và bản dịch danh mục cùng ngôn ngữ đã xuất bản.
- Người đọc công khai chỉ thấy bản dịch đã xuất bản thuộc danh mục đang bật và có bản dịch danh mục đã xuất bản cùng ngôn ngữ. Bản gốc chỉ được đọc khi có bản dịch công khai hợp lệ.
- Sửa quyền Storage để ảnh dùng chung được đọc khi đề có ít nhất một bản dịch công khai hợp lệ; giữ kiểm tra định dạng, kích thước, quyền sở hữu đường dẫn và cleanup hiện tại.
- Cập nhật RPC xóa đề để xóa cả các bản dịch, vẫn kiểm tra phiên bản và giữ file Storage như hiện nay.
- Sinh lại TypeScript database types sau khi schema ổn định.

### Tiêu chí hoàn thành

Lưu nguyên tử, phân quyền và chống ghi đè được kiểm thử trực tiếp trên DB.

## Phase 3 — Admin quản lý danh mục

**Đã hoàn tất trên local (2026-10-24):** [Báo cáo API, editor đa ngôn ngữ và kiểm thử](./admin-content-translations-phase-3.md). Có danh sách theo ngôn ngữ mặc định `vi`, tìm tên mọi bản dịch/slug và phân trang server; RPC bổ sung cho list, bật/tắt có version và danh mục nhận hợp lệ. Admin 48 tests, DB rehearsal 5 nhóm và concurrency 8 race đạt; Vite bundle đạt. Full build/typecheck còn lỗi chuyển tiếp ở hai loại đề của Phase 4. Chưa triển khai cloud.

- Một màn hình chỉnh sửa gồm thông tin chung và các tab ngôn ngữ lấy từ `content_languages`.
- Mỗi tab có tên, mô tả, trạng thái và thao tác lưu/xuất bản/lưu trữ riêng. Tab thiếu bản dịch hiển thị “Chưa có bản dịch”.
- Đổi tab giữ nội dung chưa lưu trong bộ nhớ; lưu chỉ gửi phần chung và bản dịch của tab hiện tại. Rời trang vẫn có cảnh báo thay đổi chưa lưu.
- Danh sách hiển thị một dòng mỗi danh mục, các trạng thái ngôn ngữ và tổng số đề gốc. Tìm kiếm trên tên bản dịch và slug; phân trang vẫn ở server.
- Bật/tắt danh mục tác động mọi ngôn ngữ. Lưu trữ một bản dịch danh mục khiến các đề thuộc ngôn ngữ đó ngừng hiển thị công khai.
- Chuyển đề sang danh mục khác yêu cầu cùng loại trò chơi, danh mục đích đang bật và có bản dịch đã xuất bản cho mọi ngôn ngữ đề đang xuất bản.
- Preview xóa phân biệt số đề gốc và số bản dịch theo trạng thái. Snapshot bao gồm thay đổi bản dịch để từ chối xác nhận cũ; purge xóa đầy đủ các bản dịch liên quan.

### Tiêu chí hoàn thành

Tạo, dịch, xuất bản, chuyển và xóa danh mục hoạt động với cả hai ngôn ngữ.

## Phase 4 — Admin quản lý hai loại đề

**Đã triển khai và kiểm thử tự động trên local (2026-10-24):** [Báo cáo editor, RPC danh sách và kiểm thử](./admin-content-translations-phase-4.md). Hai editor dùng phần chung + tab ngôn ngữ, lưu nguyên tử một bản dịch và giữ các draft còn lại. Admin tests, full typecheck/build, SQL rehearsal, concurrency và Storage integration đạt. Kiểm tra trực tiếp bàn phím/layout còn chuyển sang Phase 5 vì phiên công cụ không truy cập được browser window. Chưa triển khai cloud.

- Áp dụng bố cục phần chung và tab bản dịch cho đề từ, đề câu hỏi bằng các component Nuxt UI hiện có.
- Thêm bản dịch không nhân đôi đề gốc; không tự sao chép nội dung từ ngôn ngữ khác.
- Nút lưu, xuất bản và lưu trữ chỉ tác động bản dịch đang chọn. Xóa đề gốc xóa toàn bộ bản dịch và phải ghi rõ trong hộp xác nhận.
- Danh sách có một dòng mỗi đề gốc, bộ lọc ngôn ngữ mặc định `vi`, thể hiện trạng thái của các bản dịch.
- Khi thiếu bản dịch của ngôn ngữ đang chọn, vẫn hiện dòng với nhãn “Chưa có bản dịch”, cho phép mở để bổ sung. Lọc trạng thái loại các bản chưa tồn tại.
- Tìm kiếm và sắp xếp nội dung theo ngôn ngữ đang chọn; nội dung thiếu xếp cuối. Tổng số và phân trang tính theo đề gốc.
- Giữ quy trình upload ảnh, xử lý lỗi, chống bấm lặp, tải lại khi xung đột và cảnh báo chưa lưu. Nhắc rõ khi sửa dữ liệu chung vì ảnh hưởng mọi ngôn ngữ.
- Cập nhật API, form schemas, types và fixtures; locale nội dung độc lập với locale giao diện admin.

### Tiêu chí hoàn thành

Xuất bản Việt trong khi Anh còn nháp được; sửa một bản dịch không ghi đè bản còn lại.

## Phase 5 — Dashboard và kiểm thử tích hợp

**Đã triển khai và kiểm thử tự động trên local (2026-10-24), chưa hoàn tất manual verification:** [Báo cáo dashboard, sửa conflict HTTP và kiểm thử](./admin-content-translations-phase-5.md). Admin 57/57 tests, full typecheck/build, migration rehearsal 6 nhóm, concurrency 8 race, Storage HTTP integration và DB lint/advisors đạt. Thêm forward migration đổi explicit conflict từ `40001` sang `PT409` để tránh PostgREST retry đến timeout. Đã kiểm tra trực tiếp dashboard, giữ draft đề từ và tạo/lưu/publish/archive đề câu hỏi; còn layout 390px và các luồng UI được liệt kê trong báo cáo vì công cụ browser/capture không ổn định. Chưa triển khai cloud.

- Dashboard thêm bộ chọn ngôn ngữ mặc định `vi`; thống kê đề xuất bản, bản nháp và cảnh báo theo ngôn ngữ đó.
- `admin_dashboard_summary` nhận `p_locale`; item trả về có locale để liên kết mở đúng tab bản dịch.
- Cập nhật cache keys và invalidation cho danh mục, đề và dashboard sau mọi thay đổi liên quan.
- Cập nhật các SQL tests, admin tests, Storage integration test và kiểm thử concurrency hiện có.

### Các tình huống bắt buộc

- Migration giữ đủ nội dung, trạng thái, ID và ảnh; chạy được trên DB mới lẫn bản sao dữ liệu cũ.
- Trùng bản dịch, mã ngôn ngữ không tồn tại, nội dung rỗng và câu hỏi giống nhau bị từ chối.
- Người ngoài không đọc được bản nháp hoặc ghi nội dung; admin bị thu hồi quyền không tiếp tục ghi.
- Hai tab lưu đồng thời báo xung đột; save lỗi không lưu dở phần chung hoặc bản dịch.
- Lưu trữ/bật tắt danh mục, chuyển/purge và chỉnh bản dịch sau preview đều giữ đúng quyền đọc và kiểm tra phiên bản.
- Ảnh chỉ được truy cập khi đủ điều kiện công khai; upload/save thất bại giữ đúng cleanup.
- Thêm ngôn ngữ thử nghiệm vào danh sách tạo được tab và bản dịch mà không sửa schema hay viết thêm form riêng.

### Tiêu chí hoàn thành

SQL tests, admin tests, typecheck, build local và Storage integration đều đạt; kiểm tra trực tiếp luồng admin bằng bàn phím và giao diện.

## Phase 6 — Chuyển đổi và triển khai

- Chạy thử migration trên bản sao DB, đối chiếu dữ liệu và kiểm tra quyền trước khi triển khai thật.
- Sao lưu DB; tạm dừng admin, đóng các phiên cũ, áp dụng migration rồi triển khai admin mới.
- Chỉ bỏ các cột nội dung cũ sau khi đối chiếu backfill thành công trong transaction; cập nhật đầy đủ dependencies trước khi commit migration.
- Kiểm tra nhanh đăng nhập, danh sách, lưu, xuất bản và đọc công khai; mở lại admin và yêu cầu tải lại tab.
- Nếu migration thất bại, rollback transaction. Nếu kiểm tra sau triển khai thất bại trước khi mở lại ghi dữ liệu, khôi phục backup và admin cũ.
- Cập nhật tài liệu schema, ngôn ngữ, lệnh kiểm thử và quy trình triển khai.

## Giới hạn và rủi ro

Đã đối chiếu DB local ở Phase 1; chưa đối chiếu Dev cloud đang inactive hoặc DB triển khai. Không có client ngoài repo được biết đến theo xác nhận của người dùng. Schema và API nội dung sẽ thay đổi; admin cũ phải dừng trong lúc chuyển đổi và cần kiểm tra lại consumers trước triển khai.
