# Kế hoạch triển khai Question Prompts

## Mục tiêu

Hoàn thiện danh sách, tạo/sửa, preview và quản lý trạng thái câu hỏi theo [Kế hoạch triển khai màn hình Admin](admin-screen-implementation-plan.md). Giao diện bám sát Word Prompts hiện tại. Bỏ hoàn toàn `imposter_hint`; app tự xử lý hiển thị danh mục khi bật hint.

## Tài liệu tham chiếu

- [Quy tắc style danh sách Admin](layout/admin-style-rules.md): áp dụng cho màn danh sách Question Prompts, gồm token, class CSS chung, bộ lọc, bảng, nút và responsive. Form tạo/sửa và dialog tiếp tục theo style Word Prompts hiện tại.

## Giao diện và luồng thao tác

- Giữ cùng shell, khoảng cách, typography, card, bộ lọc, bảng, nút và cách responsive của Word Prompts; tái sử dụng CSS phù hợp, không đổi thiết kế màn từ ngữ.
- Danh sách hiển thị hai câu hỏi, danh mục, độ khó, Family Mode, trạng thái và ngày cập nhật. Nội dung dài được rút gọn; mở form để xem đầy đủ.
- Tìm kiếm backend trên cả hai câu hỏi, debounce 300 ms; lọc danh mục, độ khó, Family Mode, ngôn ngữ và trạng thái. Phân trang 20 dòng; sắp xếp theo ngày cập nhật giảm dần hoặc câu hỏi civilian tăng dần, có thứ tự phụ theo ID. Giữ bộ lọc trong URL khi tạo/sửa và quay lại.
- Thêm route `/question-prompts/new` và `/question-prompts/:id/edit`.
- Form dùng hai textarea cạnh nhau trên desktop, xếp dọc trên màn nhỏ. Phần phân loại và thanh hành động theo Word Prompts.
- Preview hai card civilian/imposter hiển thị câu hỏi tương ứng. Không có trường hint hay cấu hình hint được lưu vào đề.
- Có lưu nháp, publish, chuyển về nháp, archive và xóa với cách xác nhận như Word Prompts. Giữ dữ liệu khi lỗi, chặn thao tác lặp và cảnh báo thay đổi chưa lưu khi rời trang hoặc đăng xuất.
- Có trạng thái loading, danh sách rỗng, lỗi tải/lưu và cách thử lại. Khi lưu hoặc xóa thành công, cập nhật cache câu hỏi và số lượng content của danh mục.

## API và database

- Tách API, validation và component theo cấu trúc Word Prompts; dùng Vue Query và hệ thống dịch hiện có, không thêm dependency.
- Payload gồm `civilian_question`, `imposter_question`, `category_id`, `difficulty`, `is_family_friendly`, `locale` và `status`. Mặc định đề mới: `vi`, `medium`, Family Mode tắt, trạng thái `draft`.
- Trim trước khi lưu; cả hai câu hỏi bắt buộc và phải khác nhau sau khi trim, không phân biệt hoa/thường. Áp dụng cùng quy tắc tại frontend và backend cho mọi trạng thái. Không kiểm tra trùng giữa các đề khác nhau.
- Backend kiểm tra danh mục thuộc loại `question`, cùng locale; publish yêu cầu danh mục đang hoạt động. Đề cũ thuộc danh mục đã tắt vẫn mở được để sửa hoặc archive. Form giữ lựa chọn danh mục cũ khi danh mục đó không còn trong danh sách đang hoạt động.
- Dùng `updated_at` để phát hiện sửa đồng thời; báo xung đột và yêu cầu tải lại, không ghi đè âm thầm. Khi tải lại mà form có thay đổi, xác nhận bỏ thay đổi trước.
- Thêm RPC `delete_question_prompt(p_id uuid, p_expected_updated_at timestamptz)` theo mẫu xóa Word Prompts: kiểm tra admin, khóa bản ghi và đối chiếu phiên bản. Không cấp quyền DELETE trực tiếp cho client.
- Tạo migration mới bỏ cột `question_prompts.imposter_hint`, thêm validation backend và cập nhật timestamp khi ghi. Không sửa migration lịch sử.
- Giữ quyền đọc published và quyền ghi admin hiện có; kiểm thử cả grants và RLS theo [hướng dẫn Supabase](https://supabase.com/docs/guides/database/postgres/row-level-security).
- Cập nhật tài liệu triển khai, layout, schema và assertion cũ đang yêu cầu giữ hint. Tài liệu lịch sử phải ghi rõ thay đổi schema hiện tại nếu vẫn mô tả trường này.

## Kiểm thử và triển khai

- Unit/API: validation hai câu hỏi, payload không có hint, tìm kiếm hai trường, lọc/phân trang, lỗi quyền và xung đột phiên bản.
- Component: tải/rỗng/lỗi/thử lại, tạo/sửa, preview, thay đổi trạng thái, xóa, chống gửi lặp và cảnh báo chưa lưu.
- SQL: cột hint đã bị bỏ; chặn câu hỏi rỗng/trùng, sai loại/locale và publish với danh mục tắt; xác minh quyền admin, đọc published và xóa có kiểm tra phiên bản. Script kiểm thử rollback fixture.
- Chạy lại kiểm thử danh mục và Word Prompts để kiểm tra luồng chuyển/xóa content và thay đổi assertion về hint.
- Chạy `yarn test` và `yarn build:local` trong thư mục `admin`; kiểm tra trực quan cạnh Word Prompts ở desktop và màn nhỏ.
- Áp dụng migration local, không reset dữ liệu. Migration phải được triển khai trước frontend; không tự push remote.

## Giả định và giới hạn

- Xóa cột sẽ xóa dữ liệu hint cũ theo lựa chọn đã chốt.
- Phạm vi là admin và backend liên quan; không sửa app hoặc thêm logic hint vào admin.
- Đây là kế hoạch triển khai; chưa thực hiện thay đổi code, migration hoặc chạy kiểm thử tính năng.
