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

1. Danh sách `/categories`: tìm kiếm backend theo tên/slug (debounce 300 ms), lọc loại game/trạng thái, phân trang 20 dòng và sắp xếp. Giữ bộ lọc trong URL.
2. Form `/categories/new` và `/categories/:id/edit`: tạo tiếng Việt; khi sửa giữ nguyên ngôn ngữ và khóa loại trò chơi.
3. Backend đọc/ghi qua `admin/src/api/categories.js`; component hiển thị, utils và CSS tách riêng. Vue Query tải lại dữ liệu sau thao tác.
4. Xóa rỗng; chuyển toàn bộ content sang danh mục đang hoạt động cùng loại/locale rồi xóa; hoặc xóa toàn bộ content và danh mục. RPC xử lý nguyên tử, kiểm tra quyền admin, khóa dữ liệu và xác nhận phiên bản content trước purge.
5. Xóa toàn bộ phải nhập đúng tên và xem số content theo trạng thái. File Storage được giữ lại; chưa có luồng dọn ảnh.
6. Tắt danh mục cần xác nhận; cảnh báo thay đổi chưa lưu khi điều hướng, tải lại hoặc đăng xuất.

### Kiểm thử và triển khai danh mục

- `cd admin && yarn test` và `yarn build:local`.
- Áp dụng migration mới bằng `supabase migration up --local`; không reset dữ liệu.
- Chạy `supabase/tests/category_management.sql` bằng psql với `ON_ERROR_STOP=1`; script rollback fixture.
- Chạy `python3 supabase/tests/category_concurrency.py` để kiểm tra thêm content đồng thời trên container local.
- Deployment backend phải áp dụng migration `20261012155821_category_management.sql` trước khi phát hành frontend; bản triển khai này không tự push lên remote.

### Tiêu chí hoàn thành mỗi màn

- Có trạng thái loading, danh sách rỗng, lỗi tải/lưu và cách thử lại.
- Chặn gửi form nhiều lần khi đang lưu; giữ dữ liệu đã nhập nếu lưu thất bại.
- Form có validation và cảnh báo khi rời trang hoặc đăng xuất với thay đổi chưa lưu.
- Hoàn thành các thao tác chính với dữ liệu backend trước khi chuyển sang màn tiếp theo.
- Kiểm tra quyền truy cập dữ liệu: phiên hết hạn hoặc tài khoản không có quyền admin không được đọc/ghi dữ liệu quản trị trái phép.

