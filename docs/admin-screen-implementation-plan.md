# Kế hoạch triển khai màn hình Admin

> Bố cục và trường dữ liệu từng màn được mô tả trong [Bố cục màn hình Admin](layout/admin-screen-layout.md).

## Thứ tự triển khai sau đăng nhập/đăng xuất

**Màn hình nên làm tiếp theo: Danh mục.** Nội dung từ ngữ và câu hỏi đều cần danh mục để tạo/sửa và lọc dữ liệu.

Hiện đã có tích hợp Supabase, đăng nhập/đăng xuất, admin shell và route cho bốn màn hình. Các màn `Tổng quan`, `Danh mục`, `Nội dung từ ngữ`, `Nội dung câu hỏi` vẫn đang dùng placeholder. Tái sử dụng shell và route hiện có khi triển khai.

| Thứ tự | Màn hình / phạm vi | Kết quả cần đạt | Lý do ưu tiên |
| --- | --- | --- | --- |
| 1 | Danh mục: danh sách → form tạo/sửa | Xem, lọc, tạo, sửa và bật/tắt danh mục; dữ liệu được lưu và tải lại từ backend. | Là dữ liệu nền cho cả hai loại content. |
| 2 | Nội dung từ ngữ: danh sách → form tạo/sửa → ảnh và preview → publish/archive | Hoàn thành luồng tạo nháp, sửa, gắn danh mục, quản lý ảnh, kiểm tra preview và thay đổi trạng thái. | Hoàn thiện một luồng quản lý content từ đầu đến cuối trước khi làm loại còn lại. |
| 3 | Nội dung câu hỏi: danh sách → form tạo/sửa và preview → publish/archive | Hoàn thành luồng quản lý cặp câu hỏi, kiểm tra câu hỏi rỗng/trùng và đúng loại danh mục. | Tái sử dụng cách lọc, phân trang và hiển thị trạng thái đã làm ở màn từ ngữ. |
| 4 | Tổng quan | Hiển thị thống kê, nội dung gần đây, nháp cần xử lý và cảnh báo từ dữ liệu thật; liên kết đến màn xử lý tương ứng. | Các màn quản lý đã tạo ra dữ liệu và luồng xử lý để dashboard tổng hợp. |

Thứ tự triển khai khác với thứ tự menu: `Tổng quan` vẫn là màn đầu sau đăng nhập, nhưng hoàn thiện sau các màn quản lý content.

### Phạm vi bước tiếp theo: Danh mục

1. Làm bảng danh mục với bộ lọc loại game, ngôn ngữ, trạng thái; tìm kiếm, phân trang và sắp xếp theo tài liệu layout.
2. Làm form thêm/sửa với các trường đã quy định; khóa loại game khi danh mục đã có content.
3. Nối thao tác đọc/ghi backend, hiển thị lỗi lưu và xác nhận trước khi deactivate.
4. Kiểm tra tạo → sửa → lọc → deactivate → tải lại trang để xác nhận dữ liệu được lưu đúng.

### Tiêu chí hoàn thành mỗi màn

- Có trạng thái loading, danh sách rỗng, lỗi tải/lưu và cách thử lại.
- Chặn gửi form nhiều lần khi đang lưu; giữ dữ liệu đã nhập nếu lưu thất bại.
- Form có validation và cảnh báo khi rời trang hoặc đăng xuất với thay đổi chưa lưu.
- Hoàn thành các thao tác chính với dữ liệu backend trước khi chuyển sang màn tiếp theo.
- Kiểm tra quyền truy cập dữ liệu: phiên hết hạn hoặc tài khoản không có quyền admin không được đọc/ghi dữ liệu quản trị trái phép.

