# Quy tắc style danh sách Admin

Danh sách Word Prompt là mẫu tham chiếu cho danh sách Danh mục. Khi thêm màn danh sách admin, dùng các quy tắc dưới đây và các class chung trong `admin/src/styles/admin-lists.css`.

## Token và bố cục

- Dùng token trong `admin/src/styles/theme.css`; không chép mã màu hoặc khoảng cách sang từng màn.
- Nền trang dùng `--color-gray-50`, chữ chính `--color-charcoal`, chữ phụ `--color-charcoal-soft`.
- Các khối nội dung cách nhau `--space-4` (20px). Toolbar và phân trang dùng flex, căn giữa theo chiều dọc, hai đầu theo chiều ngang, gap `--space-3` (16px).
- Toolbar đặt mô tả bên trái, nút tạo mới có icon plus bên phải. Giữ tiêu đề ở admin shell.
- Vùng chứa bảng cần `min-width: 0`; với grid dùng `minmax(0, 1fr)` để bảng không đẩy rộng trang.

## Bộ lọc

- Dùng `admin-filter-grid`, không bọc thêm card. Mỗi input/select có `UFormField` với label rõ ràng và rộng 100%.
- Desktop: 4 cột bằng nhau, gap `--space-3`. Từ 1000px trở xuống: 2 cột; từ 600px trở xuống: 1 cột.
- Giữ tìm kiếm ở đầu, bộ lọc theo nghiệp vụ ở giữa, sắp xếp ở cuối. Giữ nguyên cách lưu bộ lọc trên URL của mỗi màn.

## Bảng

- Wrapper dùng `admin-table-scroll`: nền trắng, viền `--color-teal-border` 1px, bo `--radius-md` (12px), cuộn ngang bên trong.
- Table dùng `admin-table`: rộng 100%, gộp viền, padding ô `--space-3`, căn trái và căn giữa theo chiều dọc.
- Header dùng nền `--color-teal-surface`, chữ 14px, weight 600. Nội dung dùng cỡ chữ body. Các hàng ngăn bằng viền teal, hàng cuối không có viền dưới.
- Với `UTable`, đặt class wrapper trên component, truyền `base: 'admin-table …'` và `tbody: 'tw:divide-y-0'` qua `ui`. Giữ caption, thông báo rỗng và loading của component.
- Chiều rộng tối thiểu phụ thuộc số cột: Danh mục 1100px, Word Prompt 1240px, Question Prompts 1400px. Không ép bảng co đến mức mất nút hoặc cắt nội dung.
- Tên/nội dung chính và tên danh mục dài được xuống dòng, có `overflow-wrap: anywhere`; giới hạn ô text ở 320px. Thông tin ngắn như ngày, trạng thái và thao tác không xuống dòng.
- Tên có thể sửa dùng `UButton` neutral/link, padding 0, căn trái. Slug là dòng chữ phụ bên dưới. Trạng thái Danh mục tiếp tục dùng badge.
- Question Prompts rút gọn hai câu hỏi tối đa ba dòng; mở form để đọc toàn bộ.
- Quy tắc riêng như ảnh Word Prompt 96×96px và độ rộng từng cột nằm trong CSS của màn.

## Nút và trạng thái

- Nút tạo mới dùng primary mặc định. Các thao tác trong bảng dùng neutral/outline; Xóa dùng error/outline.
- Nhóm thao tác trong bảng nằm trên một hàng, gap `--space-1` (8px), nút không co lại. Nhóm nút ngoài bảng được phép wrap.
- Giữ `UAlert` cho thành công/lỗi, loading và retry hiện có. Empty state dùng nội dung dịch của từng màn.
- Giữ nguyên disabled/loading khi đang xử lý, xác nhận thao tác, nhãn truy cập và focus bàn phím; thay style không được đổi hành vi CRUD.

## Responsive và kiểm tra

- Ở ≤600px, toolbar và phân trang xếp dọc; bảng vẫn cuộn ngang trong wrapper.
- Kiểm tra desktop, tablet, mobile với tên dài, bảng rỗng, loading và hàng đủ nút thao tác. Trang không được có cuộn ngang do bảng gây ra.
- Các quy tắc này áp dụng cho danh sách. Form tạo/sửa và dialog giữ style riêng cho đến khi có yêu cầu đồng bộ.
