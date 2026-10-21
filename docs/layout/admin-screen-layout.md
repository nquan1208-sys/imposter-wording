# Bố cục màn hình Admin

> Tài liệu mô tả bố cục, nội dung và thành phần giao diện của Admin Vue.

Style danh sách dùng chung được quy định tại [Quy tắc style danh sách Admin](admin-style-rules.md), lấy Word Prompt làm mẫu tham chiếu.

## Mục đích

Admin dùng để quản lý danh mục và nội dung từ backend. Người chơi không đăng nhập; tên người chơi, câu trả lời, lượt vote và trạng thái ván được lưu local trên thiết bị theo phạm vi R1.

Thứ tự triển khai và tiêu chí hoàn thành được mô tả trong [Kế hoạch triển khai màn hình Admin](../admin-screen-implementation-plan.md).

## Admin shell

Admin sử dụng bố cục desktop-first, có thể responsive trên tablet. UI MVP chỉ tập trung vào quản lý content, không có các màn hình quản trị mở rộng.

1. **Sidebar cố định bên trái**
   - Logo/tên ứng dụng: `Imposter Admin`.
   - `Tổng quan`.
   - `Danh mục`.
   - `Nội dung từ ngữ`.
   - `Nội dung câu hỏi`.
   - Ở cuối sidebar: thông tin email admin và nút `Đăng xuất`.

2. **Thanh đầu trang**
   - Breadcrumb của màn hình hiện tại.
   - Tiêu đề màn hình hiện tại.

3. **Vùng nội dung chính**
   - Tiêu đề màn hình.
   - Mô tả ngắn nếu cần.
   - Nút hành động chính nằm ở góc trên bên phải.

## Màn hình Tổng quan admin

### Mục đích

Cho admin biết nhanh tình trạng content và các việc cần xử lý.

### Bố cục

- Hàng thẻ thống kê:
  - `Đề từ ngữ đã publish`.
  - `Đề câu hỏi đã publish`.
  - `Danh mục đang hoạt động`.
  - `Nội dung bản nháp`.
- Khu vực `Nội dung cập nhật gần đây`.
- Khu vực `Nội dung bản nháp cần xử lý`.
- Khu vực cảnh báo:
  - Danh mục không có content.
  - Question civilian và imposter bị trùng.
  - Content chưa được gắn Family Mode nhưng có difficulty `easy`.

## Màn hình Danh mục

### Bố cục

- Nút chính: `+ Thêm danh mục`.
- Bộ lọc:
  - Loại game: `Từ ngữ` hoặc `Câu hỏi`.
  - Ngôn ngữ hiển thị trong bảng; bản tạo mới cố định tiếng Việt.
  - Trạng thái active/inactive.
- Bảng danh mục gồm:
  - Tên danh mục.
  - Loại game.
  - Số lượng content.
  - Ngôn ngữ.
  - Trạng thái.
  - Thời gian cập nhật.
  - Menu thao tác.

### Form danh mục

- Tên danh mục.
- Slug.
- Loại game.
- Mô tả.
- Ngôn ngữ.
- Thứ tự hiển thị.
- Active/inactive.

Loại game và ngôn ngữ được cố định khi sửa. Nếu cần đổi loại, admin phải tạo danh mục mới.

### Xóa danh mục

- Danh mục rỗng: xác nhận rồi xóa vĩnh viễn.
- Danh mục có content: chuyển toàn bộ content sang danh mục đang hoạt động cùng loại/ngôn ngữ rồi xóa, hoặc xóa cả danh mục và toàn bộ content.
- Xóa toàn bộ hiển thị số nháp/published/archived và yêu cầu nhập đúng tên danh mục. Nếu content thay đổi sau khi mở hộp thoại, tải lại thống kê để xác nhận lại.
- Backend xử lý trong một giao dịch; không cascade tự động. Xóa bản ghi không dọn file ảnh Storage.


## Màn hình Nội dung từ ngữ

### Danh sách

- Nút chính: `+ Thêm đề từ ngữ`.
- Bộ lọc:
  - Danh mục.
  - Độ khó.
  - Family Mode.
  - Ngôn ngữ.
  - Trạng thái: `Draft`, `Published`, `Archived`.
- Bảng gồm:
  - Ảnh thumbnail.
  - Từ của civilian.
  - Danh mục.
  - Độ khó.
  - Family Mode.
  - Trạng thái.
  - Ngày cập nhật.

### Form tạo/sửa đề từ ngữ

- Từ cho civilian.
- Upload ảnh.
- Preview ảnh.
- Thay ảnh hoặc xóa ảnh.
- Danh mục.
- Độ khó: `Easy`, `Medium`, `Hard`.
- Checkbox: `Phù hợp chế độ gia đình`.
- Ngôn ngữ.

Khu vực preview nên mô phỏng hai trạng thái:

- `Civilian thấy`: ảnh và từ bí mật.
- `Imposter thấy`: vai trò và tên danh mục nếu bật hiển thị danh mục; khi tắt chỉ thấy vai trò. Preview mô phỏng cả hai trường hợp, không lưu cấu hình vào đề.

Nút cuối form:

- `Lưu nháp`.
- `Publish`.
- `Archive`.

## Màn hình Nội dung câu hỏi

### Danh sách

- Nút chính: `+ Thêm đề câu hỏi`.
- Bộ lọc giống màn hình nội dung từ ngữ.
- Bảng gồm:
  - Câu hỏi civilian.
  - Câu hỏi imposter.
  - Danh mục.
  - Độ khó.
  - Family Mode.
  - Trạng thái.
  - Ngày cập nhật.

### Form tạo/sửa đề câu hỏi

Form chia thành hai cột:

```text
┌────────────────────────┬────────────────────────┐
│ Câu hỏi cho civilian   │ Câu hỏi cho imposter   │
│ [textarea]             │ [textarea]             │
└────────────────────────┴────────────────────────┘
```

- Câu hỏi civilian.
- Câu hỏi imposter.
- Hint cho imposter.
- Danh mục câu hỏi.
- Độ khó.
- Checkbox `Phù hợp chế độ gia đình`.
- Ngôn ngữ.
- Preview câu hỏi hiển thị cho từng vai trò.

Validation:

- Hai câu hỏi không được rỗng.
- Hai câu hỏi không được giống nhau.
- Câu hỏi phải thuộc đúng category loại `question`.
- Không được publish content chưa đủ dữ liệu.

## Quy tắc UI và trạng thái

- `Draft`: badge màu vàng.
- `Published`: badge màu xanh.
- `Archived`: badge màu xám.
- Nút `Publish` cần nổi bật hơn `Lưu nháp`.
- Archive hoặc deactivate phải có hộp thoại xác nhận.
- Các bảng hỗ trợ phân trang, tìm kiếm và sắp xếp.
- Tên/nội dung chính và tên danh mục dài trong bảng được xuống dòng; click vào tên để mở màn sửa. Ngày, trạng thái và nhóm thao tác giữ trên một hàng.
- Upload ảnh hiển thị tiến trình, preview và lỗi định dạng/kích thước.
- Family Mode là một thuộc tính độc lập với độ khó; app chỉ lấy content có `is_family_friendly = true` khi chế độ gia đình được bật.
- Nút `Đăng xuất` nằm cố định ở cuối sidebar, tách biệt với các mục content.
- Khi nhấn `Đăng xuất`, hiển thị trạng thái loading ngắn rồi chuyển về màn hình đăng nhập admin.
- Nếu admin chưa lưu thay đổi trong form, hiển thị cảnh báo trước khi đăng xuất.

## Luồng điều hướng admin

```text
Đăng nhập admin
└── Tổng quan
    ├── Danh mục
    │   ├── Tạo danh mục
    │   └── Sửa danh mục
    ├── Nội dung từ ngữ
    │   ├── Danh sách
    │   ├── Tạo/sửa đề từ ngữ
    │   └── Upload ảnh
    ├── Nội dung câu hỏi
    │   ├── Danh sách
    │   └── Tạo/sửa đề câu hỏi
    └── Đăng xuất
```
