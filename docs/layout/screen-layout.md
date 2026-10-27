# Bố cục màn hình ứng dụng

> Bản nháp từ các ảnh tham khảo hiện có. Tài liệu tập trung vào bố cục, nội dung và thành phần giao diện; chưa mô tả màu sắc, font chữ hoặc thông số pixel.

## 1. Màn hình bắt đầu

### Mục đích

Giới thiệu nhanh trò chơi và dẫn người dùng vào luồng chính.

### Bố cục từ trên xuống dưới

1. **Khu vực hình ảnh chính**
   - Minh họa nhân vật/biểu tượng chủ đề “kẻ mạo danh”.
   - Đặt ở vùng trung tâm phía trên màn hình.

2. **Tên trò chơi**
   - Tiêu đề lớn: `Kẻ mạo danh`.

3. **Thông điệp phụ**
   - Dòng giới thiệu ngắn: `Trò chơi từ ngữ`.

4. **Mô tả trò chơi**
   - Mô tả ngắn về cách chơi, ví dụ: trò chơi tiệc tùng với từ bí mật và gợi ý.
   - Căn giữa, nằm dưới tiêu đề.

5. **Nhóm nút hành động ở cuối màn hình**
   - Nút chính: `Bắt đầu`.
   - Nút phụ: `Cách chơi`.
   - Hai nút có cùng chiều rộng và xếp theo chiều dọc.

### Luồng điều hướng

- `Bắt đầu` → màn hình thiết lập ván chơi.
- `Cách chơi` → màn hình hướng dẫn.

## 2. Màn hình cách chơi

### Mục đích

Giải thích luật chơi theo từng bước trước khi người dùng bắt đầu ván đầu tiên.

### Khung màn hình

1. **Thanh tiêu đề**
   - Nút quay lại ở bên trái.
   - Tiêu đề căn giữa: `Cách chơi`.
   - Thanh tiêu đề nằm cố định ở đầu màn hình khi nội dung cuộn.

2. **Danh sách các bước hướng dẫn**
   - Các bước hiển thị thành từng thẻ lớn, xếp dọc.
   - Mỗi thẻ gồm:
     - Biểu tượng minh họa ở bên trái.
     - Tiêu đề bước.
     - Mô tả ngắn ở bên phải hoặc phía dưới tiêu đề.

### Nội dung các bước hiện có

#### Bước 1 — Thiết lập trò chơi

- Người chơi chọn danh sách người chơi và danh mục từ.
- Chọn số kẻ mạo danh cố định hoặc ngẫu nhiên trong 1…floor((N−1)/2); người thường luôn chiếm đa số.
- Biểu tượng: thiết lập/cài đặt.

#### Bước 2 — Tiết lộ từ

- Mỗi người lần lượt xem thông tin của mình.
- Người chơi bình thường nhìn thấy từ bí mật.
- Kẻ mạo danh thấy vai trò; chỉ thấy tên danh mục nếu bật hiển thị danh mục.
- Biểu tượng: con mắt.

#### Bước 3 — Đưa ra gợi ý

- Người chơi lần lượt nói các từ liên quan đến từ bí mật.
- Gợi ý không nên quá rõ ràng để tránh lộ từ.
- Biểu tượng: tin nhắn/hội thoại.

#### Bước 4 — Tìm kẻ mạo danh

- Cả nhóm thảo luận.
- Mọi người bỏ phiếu cho người có khả năng không biết từ bí mật.
- Nếu nhóm bỏ phiếu sai, kẻ mạo danh thắng.
- Biểu tượng: tìm kiếm.

3. **Thẻ mẹo chuyên nghiệp**
   - Đặt sau danh sách các bước.
   - Có biểu tượng bóng đèn.
   - Gồm tiêu đề `Mẹo chuyên nghiệp` và một đoạn lời khuyên ngắn.
   - Nội dung mẫu: kẻ mạo danh nên lắng nghe cẩn thận, hòa nhập và đưa ra gợi ý phù hợp với danh mục.

### Hành vi

- Nội dung hướng dẫn có thể cuộn theo chiều dọc.
- Nút quay lại đưa người dùng về màn hình bắt đầu.
- Không cần thao tác xác nhận ở cuối màn hình trong bản hiện tại.

## 3. Màn hình cài đặt trò chơi

### Mục đích

Cho phép người chơi cấu hình ván chơi trước khi bắt đầu.

### Khung màn hình

1. **Thanh điều hướng đầu màn hình**
   - Nút quay lại ở bên trái.
   - Nút cài đặt ở bên phải.
   - Tiêu đề lớn: `Cài đặt trò chơi`.

2. **Thẻ thông số người chơi**
   - Hai thẻ nằm cạnh nhau trên cùng một hàng:
     - `Có bao nhiêu người chơi?` — hiển thị số người chơi hiện tại.
     - `Có bao nhiêu kẻ mạo danh?` — hiển thị số kẻ mạo danh hiện tại.
   - Mỗi thẻ có biểu tượng, nhãn mô tả và giá trị số lớn.
   - Có thể chạm vào thẻ để thay đổi giá trị.

3. **Khu vực chọn loại trò chơi**
   - Tiêu đề nhóm: `Chế độ trò chơi`.
   - Hai thẻ lựa chọn xếp thành hai cột:
     - `Trò chơi từ ngữ` — tìm người không biết từ bí mật.
     - `Trò chơi câu hỏi` — tìm người nhận câu hỏi khác.
   - Một thẻ luôn ở trạng thái được chọn.

4. **Chế độ chơi**
   - Chọn chế độ tại màn danh mục từ ngữ bằng hai tab `Tất cả danh mục` và `Chế độ gia đình`.
   - Switch `Hiển thị ảnh` chỉ xuất hiện trong tab gia đình; màn thiết lập không có chọn mode hoặc switch ảnh.
   - Trò câu hỏi luôn là chế độ thường.

5. **Khu vực danh mục**
   - Tiêu đề nhóm: `Danh mục`.
   - Một thẻ cấu hình lớn chứa:
     - Tên danh mục hiện tại: `Tất cả danh mục` khi chưa chọn danh mục cụ thể.
     - Cho phép chọn một hoặc nhiều danh mục.
     - Nút mũi tên để mở màn hình chọn danh mục.
     - Nếu không chọn danh mục, app random trong tất cả content phù hợp với loại game và mode.
     - Nếu chọn danh mục, app chỉ random trong các danh mục đã chọn.

6. **Các tùy chọn trong ván chơi**
   - `Hiển thị danh mục cho kẻ mạo danh`.
   - `Kẻ mạo danh biết nhau`.
   - Mỗi tùy chọn gồm biểu tượng, nhãn và công tắc bật/tắt.
   - Danh sách tùy chọn nằm trong cùng một thẻ và được ngăn cách bằng các đường phân chia.
   - Word chỉ có tiết lộ danh mục, không có công tắc hoặc dữ liệu hint riêng; `Hiển thị danh mục cho kẻ mạo danh` tiếp tục chỉ áp dụng word.
   - **Bổ sung theo kế hoạch Phase 6, chưa triển khai:** `Kẻ mạo danh biết nhau` hiện cho cả word/question và cả Cổ điển/Gia đình, dùng chung giá trị đã lưu khi đổi loại game, nạp nhóm và chơi lại. Khi bật và có ít nhất hai imposter, chỉ imposter đã mở thẻ riêng thấy tên đồng vai; thẻ khóa/người thường không thấy.

7. **Nút bắt đầu**
   - Nút cố định gần cuối màn hình: `Bắt đầu trò chơi`.
   - Nút luôn dễ nhìn thấy khi người dùng cuộn nội dung.

### Trạng thái được quan sát

- `Trò chơi từ ngữ` + `Cổ điển` được chọn, danh mục là `Tất cả danh mục`.
- `Trò chơi từ ngữ` + `Gia đình` được chọn, danh sách danh mục chỉ hiển thị content phù hợp gia đình.
- `Trò chơi câu hỏi` + `Gia đình` được chọn, danh sách danh mục chỉ hiển thị question prompt phù hợp gia đình.

### Hành vi

- Có thể cuộn dọc để xem toàn bộ tùy chọn.
- Nút `Bắt đầu trò chơi` vẫn nằm ở vùng cuối màn hình.
- Loại trò chơi và mode được chọn quyết định tập content được phép random.
- Cả hai loại trò chơi đều có hai mode `Cổ điển` và `Gia đình`.
- Danh mục là tùy chọn, mặc định là `Tất cả danh mục`.
- Có thể chọn nhiều danh mục cùng lúc.
- Không chọn danh mục sẽ random trong toàn bộ content đã publish phù hợp với loại game và mode.
- Chọn một hoặc nhiều danh mục sẽ giới hạn random trong các category đó.
- Word không có gợi ý riêng ngoài tên danh mục khi bật công tắc tương ứng.
- Số kẻ mạo danh phải phù hợp với số người chơi.
- Nút quay lại đưa người dùng về màn hình trước đó.

### Bảng chọn kẻ mạo danh

- Chạm vào thẻ số lượng kẻ mạo danh ở word hoặc question sẽ mở một bảng chọn dạng bottom sheet; tiêu đề `Chọn kẻ mạo danh`.
- **Bố cục bổ sung Phase 6, chưa triển khai:** theo cấu trúc ảnh `IMG_2987.PNG`, có nền phía sau làm mờ tối, phần đầu có biểu tượng/tiêu đề; hai thẻ `Cố định` và `Ngẫu nhiên` có radio, chỉ một thẻ được chọn. Dùng theme/component hiện có của app.
- **Style theo rules của app:** ảnh chỉ tham khảo bố cục/tương tác; màu sắc, typography, spacing, bo góc, biểu tượng, trạng thái chọn, lớp phủ modal và theme sáng/tối dùng `AppTheme`/`AppColors`, constants và component hiện có, không tạo bộ style riêng theo ảnh.
- Hai cách chọn:
  - `Cố định`: chọn chính xác số kẻ mạo danh cho mỗi ván.
    - Có nút `−` và `+` để điều chỉnh số lượng.
    - Hiển thị giá trị lớn ở giữa và dòng phạm vi; số `1` có nhãn `Được khuyến nghị`. Khóa nút tăng/giảm khi tới biên.
    - Phạm vi hợp lệ là 1…floor((N−1)/2), với N từ 3 đến 100. Giảm N tự hạ số cố định về giới hạn mới.
  - `Ngẫu nhiên`: chọn đều số lượng trong cùng phạm vi hợp lệ, một lần khi bắt đầu ván. Thu phần tăng/giảm và giữ số cố định trong draft để quay lại.
- Phase 4 đặt công tắc `Kẻ mạo danh không đi trước` ở setup; **Phase 6 chuyển vào cuối modal**, nhãn `Kẻ mạo danh không bao giờ đi trước`, không hiện trùng ở setup. Chọn `startingPlayerId` trước; khi bật, loại ID này khỏi tập gán vai. Tên hiển thị ở thảo luận dùng cùng ID.
- Số lượng, chế độ và không đi trước dùng chung draft. Back/kéo đóng/chạm ngoài hủy thay đổi; `Xác nhận` mới áp dụng và lưu, gồm tự cập nhật nhóm đang dùng. Lỗi ghi giữ draft và cho thử lại. Sheet cuộn được trên màn nhỏ/chữ lớn, giữ SafeArea và nhãn truy cập.

## 4. Màn hình chọn danh mục

### Mục đích

Cho phép chọn một hoặc nhiều danh mục, hoặc dùng toàn bộ danh mục có sẵn.

### Khung màn hình

1. **Thanh điều hướng**
   - Nút quay lại ở bên trái.
   - Tiêu đề lớn: `Chọn danh mục`.

2. **Thông tin loại game và mode**
   - Hiển thị dạng badge ở đầu màn hình, ví dụ:
     - `Trò chơi từ ngữ · Cổ điển`.
     - `Trò chơi câu hỏi · Gia đình`.
   - Mode được chọn ở màn hình cài đặt trò chơi; màn hình này chỉ hiển thị danh mục phù hợp với mode đó.

3. **Danh sách danh mục**
   - Hiển thị các danh mục trong lưới hai cột.
   - Có thể chọn nhiều danh mục cùng lúc.
   - Mỗi thẻ gồm:
     - Checkbox hoặc trạng thái được chọn.
     - Tên danh mục.
     - Số lượng content hợp lệ theo loại game và mode hiện tại.
   - Nội dung ví dụ cho game từ ngữ:
     - Động vật.
     - Đồ ăn.
     - Phim ảnh.
     - Địa điểm.
   - Nội dung ví dụ cho game câu hỏi:
     - Cuộc sống & xã hội.
     - Tình yêu & mối quan hệ.
     - Tiền bạc & danh vọng.
     - Tương lai & công nghệ.

4. **Trạng thái tất cả danh mục**
   - Có lựa chọn `Tất cả danh mục` ở đầu danh sách.
   - Đây là trạng thái mặc định.
   - Khi được chọn, các category cụ thể được bỏ chọn.
   - App random trong toàn bộ content remote đã publish và custom local hợp lệ thuộc loại game, locale và mode hiện tại; mỗi đề có cơ hội như nhau.

5. **Danh mục tùy chỉnh**
   - Phase 8 có ô `Tạo danh mục tùy chỉnh` ở cuối cùng lưới word, cùng chiều rộng/kiểu viền/khoảng cách với ô danh mục có sẵn; nền xanh nhạt và biểu tượng dấu cộng để phân biệt hành động tạo. Ô tạo không có checkbox chọn danh mục; Phase 9 cũng hiện trong picker question, kể cả offline.
   - **Phase 8:** word tùy chỉnh lưu cùng bộ thiết lập local, dùng qua các ván/replay và khởi động lại. Chỉ xóa sau khi xác nhận quay từ thiết lập về trang đầu; mở app ở trang đầu không tự xóa. Phase 9 áp dụng cùng vòng đời cho cặp câu hỏi tùy chỉnh.

### Hành vi

- Chạm vào một hoặc nhiều thẻ danh mục để chọn/bỏ chọn.
- Chọn `Tất cả danh mục` sẽ bỏ chọn toàn bộ danh mục cụ thể.
- Nút `Xác nhận` quay về màn hình cài đặt trò chơi và hiển thị số category đã chọn.
- Nếu không chọn danh mục cụ thể, giữ giá trị `Tất cả danh mục`.
- Danh sách và số lượng content được lọc theo loại game và mode đã chọn.
- Tab `Tất cả danh mục` gồm cả danh mục thường và gia đình; tab `Chế độ gia đình` chỉ gồm danh mục `game_categories.is_family_friendly = true` có từ hợp lệ.
- Tab, danh mục và ảnh là bản nháp. `Xác nhận` ghi cả ba trong một lần; quay lại hủy thay đổi. Lưu lỗi giữ màn hình để thử lại.
- Đổi tab giữ danh mục còn hợp lệ, loại mục không thuộc tab và thông báo. Không chọn mục cụ thể là tất cả trong tab.
- Tab gia đình rỗng có thông báo; xác nhận được nhưng không thể bắt đầu ván khi không có từ.
- Nhớ lựa chọn ảnh; chỉ hiển thị khi chơi từ ngữ ở chế độ gia đình. Cache cũ thiếu cờ danh mục mặc định false, bỏ qua cờ prompt cũ.
- Không mô tả hoặc triển khai các danh mục Premium trong phạm vi bản nháp này.

## 5. Màn hình tạo tùy chỉnh

### Mục đích

Cho phép người dùng tự tạo danh mục từ (Phase 8) hoặc cặp câu hỏi (Phase 9) để sử dụng trong các ván chơi. Phase 10 đã thêm ảnh local tùy chọn cho từng từ hoặc cả cặp câu hỏi. Dùng theme/component hiện tại của app.

### Bố cục đề xuất

1. **Thanh tiêu đề**
   - Nút quay lại ở bên trái.
   - Tiêu đề: `Tạo danh mục tùy chỉnh`.

2. **Tên danh mục**
   - Ô nhập bắt buộc: `Tên danh mục`.
   - Placeholder: `Ví dụ: Từ ngữ công ty`.

3. **Danh sách từ**
   - Tiêu đề nhóm: `Danh sách từ`.
   - Hiển thị số lượng từ hiện có.
   - Mỗi từ nằm trên một dòng/thẻ, gồm:
     - Nội dung từ ở trên; ảnh thu nhỏ và nút thêm/thay ảnh nằm bên dưới để giữ khoảng trống trên màn hình nhỏ.
     - Nút thêm/thay ảnh.
     - Nút xóa ở bên phải.
   - Khi chưa có từ, hiển thị trạng thái trống: `Chưa có từ nào`.

4. **Thêm từ**
   - Nút `Thêm từ` đặt ngay dưới danh sách.
   - Chạm vào sẽ mở form thêm từ gồm:
     - Field `Từ` — bắt buộc trong chế độ `Trò chơi từ ngữ`.
     - Hai field `Câu hỏi thường dân` và `Câu hỏi kẻ mạo danh` — bắt buộc trong chế độ `Trò chơi câu hỏi`.
     - Field `Ảnh` — tùy chọn, hiển thị vùng chọn ảnh hoặc ảnh xem trước.
     - Nút `Lưu từ`.
   - Cho phép thêm từng từ rồi tiếp tục thêm từ khác.

5. **Nhập nhiều từ**
   - Nút phụ `Nhập nhiều từ` đặt cạnh hoặc dưới nút `Thêm từ`.
   - Mở ô nhập văn bản nhiều dòng.
   - Mỗi dòng được tính là một từ.
   - Sau khi xác nhận, các dòng hợp lệ được thêm vào danh sách.
   - Dòng trống được bỏ qua; từ trùng lặp chỉ giữ một bản.

6. **Ảnh minh họa**
   - Mỗi từ có ảnh riêng; mỗi **cặp câu hỏi có một ảnh dùng chung**; ảnh không bắt buộc.
   - Chạm vào vùng ảnh của một từ sẽ cho phép:
     - Chọn ảnh từ thư viện.
     - Chụp ảnh mới.
     - Xóa ảnh hiện tại.
   - Nếu chưa có ảnh, hiển thị nút có biểu tượng và nhãn `Thêm ảnh`. Nếu đã có ảnh, hiện thumbnail và `Thay ảnh`. Sheet có `Thư viện ảnh`, `Máy ảnh`, `Xóa ảnh` khi đã có ảnh, và `Hủy`.
   - Khi nhập nhiều từ, chỉ tạo các từ; ảnh được thêm sau cho từng từ.

7. **Nút lưu**
   - Nút cố định ở cuối màn hình: `Lưu danh mục`.
   - Chỉ bật khi tên danh mục không trống và có ít nhất một từ.

### Trạng thái và hành vi

- Rời màn hình khi chưa lưu phải hỏi xác nhận nếu đã có thay đổi.
- Tên danh mục không được để trống.
- Mỗi từ được cắt khoảng trắng đầu/cuối trước khi lưu.
- So sánh từ sau trim, không phân biệt hoa thường; dòng trống bỏ qua và từ trùng giữ cách viết đầu tiên. Nhập trùng toàn bộ báo cần ít nhất một từ mới.
- Nếu tên trùng danh mục word remote hoặc custom ở locale hiện tại (kể cả danh mục ngoài tab Gia đình), yêu cầu đổi tên thay vì ghi đè; so sánh sau trim, không phân biệt hoa thường và kiểm tra lại lúc lưu.
- Lưu thành công trở về `Chọn danh mục`, giữ nguyên tab hiện tại, thêm danh mục mới vào lựa chọn nháp và giữ các lựa chọn trước đó. `Xác nhận` picker mới áp dụng tab/danh mục/ảnh; Back picker chỉ hủy lựa chọn nháp, không xóa category đã lưu.
- Tạo tại tab Gia đình bắt buộc checkbox xác nhận từ phù hợp chơi cùng gia đình. Category này hiện ở cả hai tab; tạo tại tab Tất cả không được coi là phù hợp Gia đình. Đổi tab/game chỉ ẩn mục không phù hợp, không xóa nội dung.
- Lưu lỗi giữ nguyên tên/danh sách/checkbox và cho thử lại, không tạo category dở dang; trong khi lưu khóa chỉnh sửa và điều hướng. Ô nhập có label, lỗi gần field, thao tác xóa có nhãn; form cuộn và nút lưu nằm trên bàn phím.
- Nội dung lưu local cùng setup, giữ qua restart và `Chơi lại`, không đi vào nhóm người chơi đã lưu hoặc backend. Back từ setup về trang đầu phải xác nhận xóa vĩnh viễn nội dung tùy chỉnh; chỉ rời sau khi xóa và bỏ selected IDs thành công. Ghi lỗi giữ nguyên setup cho thử lại.
- Thẻ danh mục tùy chỉnh hiển thị tên danh mục, tổng số từ và trạng thái có ảnh minh họa.

### Ảnh local — Phase 10

- Dialog thêm một mục có ảnh tùy chọn và nút xác nhận; nhập nhiều vẫn chỉ nhận văn bản. Thumbnail dưới nội dung từng mục; ô danh mục chỉ hiện `Có hình ảnh`, không lộ ảnh.
- Chấp nhận ảnh giải mã được tối đa 5 MiB. Chọn/hủy/đọc/ghi lỗi giữ ảnh trước đó; lỗi hiển thị ngay cạnh điều khiển, có live-region VI/EN. Quyền bị từ chối/hạn chế hướng dẫn mở Cài đặt hệ thống, camera không khả dụng cho chọn thư viện. File thiếu/hỏng lúc chơi dùng placeholder ổn định.
- Khóa thao tác và Back khi picker/import/save chạy. Thay đổi ảnh nằm trong draft/discard; save lỗi giữ ảnh và văn bản để thử lại. Dialog cuộn, dùng inset 16 để nút/ảnh còn truy cập được trên màn 320×568 với text scale 2 và bàn phím. Dùng theme, nút và touch target Material hiện tại.
- Word: chỉ hiện ảnh khi session bật Gia đình + Hiển thị ảnh; người thường sau reveal và kết quả được xem, kẻ mạo danh không xem trong thẻ riêng. Question: ảnh chung dưới câu hỏi của người hiện tại sau reveal; kết quả hiện đúng một lần dưới câu thường dân. Handoff, locked card, common-question, discussion không có ảnh; conceal/background/submit/Back/đổi người gỡ widget và semantics riêng. Nhãn `Ảnh câu hỏi` không nêu vai hoặc câu đối lập.
- Ảnh đã lưu ở thiết bị suốt vòng đời category, qua replay/restart/offline; không đi vào preset/backend. Draft chưa lưu mất khi process kết thúc. Android startup nhận/bỏ lost-data của picker, thông báo tạo lại draft; không gắn ảnh vào mục mới.
- Đã kiểm tra bằng unit/widget/semantics: thêm/thay/xóa/hủy, retry, disposal, lifecycle, các stage question VI/EN, ba cấu hình ảnh word, màn nhỏ/text lớn/bàn phím/theme sáng-tối. Không dùng screenshot. Kiểm tra thư viện/camera/quyền/process death trên thiết bị thật vẫn là điều kiện nghiệm thu.

### Question tùy chỉnh — Phase 9

- Dùng chung màn tạo, tên danh mục, nút lưu, lỗi lưu và xác nhận bỏ thay đổi với word. Picker question giữ giao diện chuẩn; không có tab/checkbox Gia đình.
- Nhóm `Danh sách cặp câu hỏi` hiển thị tổng số cặp; mỗi mục có nhãn thường dân/kẻ mạo danh và nút `Xóa cặp N` có semantics. Có hai hành động `Thêm cặp câu hỏi` và `Nhập nhiều cặp câu hỏi`.
- Thêm một cặp bằng hai ô có label. Trim hai câu; cấm rỗng và cấm giống nhau không phân biệt hoa thường.
- Nhập nhiều bằng hai ô nhiều dòng, ghép theo số dòng. Giữ dòng trống khi ghép; nhận LF/CRLF và một newline cuối. Số dòng lệch, câu trống/giống nhau hoặc cặp trùng báo các dòng cần sửa; không thêm một phần. Cặp trùng được so theo thứ tự thường dân/kẻ mạo danh sau trim/lowercase với cả batch và draft. Dùng lại một câu với câu đối ứng khác được phép.
- Tên chỉ đối chiếu danh mục remote/local cùng loại game và locale; kiểm tra lại trong write queue. Lỗi ghi giữ nguyên draft và counter. Lưu thành công chỉ chọn trong picker draft; Back vẫn giữ danh mục đã lưu.
- Catalog question kết hợp remote/local dùng chung cho số lượng, điều kiện bắt đầu, random và tên danh mục trong session. Nội dung `vi` và ID `custom-question-N` lưu trong setup; không vào preset/cache remote. Chơi offline, refresh, đổi game, restart và replay giữ nội dung; session chụp cặp/tên lúc bắt đầu.
- Trước reveal chỉ người đang nhận điện thoại xem câu theo vai của mình; discussion chỉ công bố câu thường dân, kết quả mới công bố câu kẻ mạo danh. Rời setup về trang đầu yêu cầu xác nhận và xóa cả word/question cùng selected IDs trong một lần ghi; ghi lỗi giữ người dùng ở setup.

## 6. Màn hình chọn người chơi

### Mục đích

Cho phép từng người chơi lần lượt mở thông tin bí mật của mình trên cùng một thiết bị.

### Bố cục

- Nút quay lại ở góc trên bên trái.
- Tiêu đề lớn: `Người chơi`.
- Hướng dẫn: `Nhấn vào tên của bạn để xem từ, sau đó chuyển thiết bị cho người chơi tiếp theo.`
- Danh sách người chơi hiển thị dạng lưới hai cột.
- Mỗi thẻ gồm chữ cái đại diện trong vòng tròn và tên người chơi.
- Người chơi chưa xem từ có thẻ ở trạng thái có thể chạm.
- Người chơi đã xem từ bị làm mờ và không thể mở lại.

### Hành vi

- Chạm vào thẻ tên của mình sẽ mở màn hình tiết lộ từ.
- Sau khi xác nhận xong, quay lại màn hình này và chuyển sang người chơi tiếp theo.
- Chỉ khi tất cả người chơi đã xem thông tin, ván mới chuyển sang bước đưa ra gợi ý.

## 7. Màn hình tiết lộ từ

### Trạng thái trước khi tiết lộ

- Nút quay lại ở góc trên bên trái.
- Khu vực trung tâm hiển thị tên người nhận, ví dụ `Từ dành cho Hà`.
- Khi thẻ còn che, không hiện danh mục hoặc nội dung bí mật qua heading hay screen reader.
- Vùng nội dung bí mật là một thẻ che kín từ.
- Hướng dẫn bên dưới: `Nhấn để hiển thị`.

### Trạng thái sau khi tiết lộ

- Thẻ bí mật hiển thị từ dành cho người chơi, ví dụ `Inception`.
- Từ được căn giữa và là nội dung nổi bật nhất trên thẻ. Người thường thấy thêm tên danh mục sau khi mở thẻ.
- Nút hành động cuối màn hình: `Hiểu rồi!`.

### Hành vi

- Chạm vào thẻ bí mật sẽ chuyển từ trạng thái che sang trạng thái hiển thị.
- Người chơi thường nhìn thấy từ bí mật.
- Kẻ mạo danh thấy vai trò và tên danh mục của từ được chọn khi bật `Hiển thị danh mục cho kẻ mạo danh`; khi tắt chỉ thấy vai trò. Không hiển thị từ, hint hoặc ảnh bí mật. Thiết lập thuộc ván và lưu local, không thuộc từng đề.
- Chạm `Hiểu rồi!` sẽ quay về màn hình `Người chơi` và đánh dấu người chơi hiện tại đã hoàn tất.
- Không cho phép hiển thị lại từ của người chơi đã hoàn tất.
- Phase 4 hỗ trợ nhiều kẻ mạo danh; khi bật `Biết nhau`, chỉ imposter đã mở thẻ mới thấy tên các imposter khác. Không hiện từ/ảnh cho imposter. Phase 7 hiển thị ảnh local dưới từ cho người thường đã mở thẻ; thiếu/lỗi ảnh giữ placeholder cao 180dp, không có image path thì chỉ hiện chữ. Ảnh tới sau tự cập nhật và bị gỡ khỏi widget/semantics khi che thẻ.
- Back khi xem thẻ che nội dung và về danh sách, chưa đánh dấu hoàn tất. App ra nền che thẻ; khi trở lại phải chủ động mở lại.

## 8. Màn hình giai đoạn bầu chọn

### Mục đích

Hướng dẫn nhóm thảo luận và bầu chọn kẻ mạo danh sau khi tất cả người chơi đã xem từ.

### Bố cục

- Nút quay lại ở góc trên bên trái.
- Tiêu đề lớn: `Giai Đoạn Bầu Chọn`.
- Mô tả: `Đã đến lúc thảo luận và bầu chọn kẻ mạo danh!`.
- Tiêu đề phụ: `Cách Bầu Chọn`.
- Các bước hướng dẫn hiển thị thành các thẻ xếp dọc:
  1. `Người Chơi Bắt Đầu` — chọn ngẫu nhiên một lần khi tạo ván; khi bật ràng buộc không đi trước, người này không được gán vai imposter.
  2. `Thảo Luận Nhóm` — tiếp tục lần lượt theo chiều kim đồng hồ.
  3. `Thời Gian Bầu Chọn` — mỗi người nói một từ liên quan đến từ bí mật, có thể thực hiện nhiều vòng.
  4. `Giai Đoạn Tiết Lộ` — bầu chọn người bị nghi ngờ, sau đó chạm để xem kết quả.
- Nút cuối màn hình: `Thông báo kết quả`.

### Hành vi

- Chỉ mở giai đoạn này sau khi tất cả người chơi xác nhận đã xem thẻ.
- Nhóm thảo luận và bầu bằng lời; app không thu từng phiếu.
- `Thông báo kết quả` mở bottom sheet chọn đúng K người bị nhóm bầu, K bằng số imposter thực của ván (kể cả chế độ ngẫu nhiên). Mặc định chưa chọn; chỉ bật xác nhận khi chọn đủ K ID riêng biệt.
- Nếu hòa, nhóm bầu lại trước khi xác nhận. Hủy/back sheet không ghi nhận người bị bầu hoặc công bố bí mật.
- Xác nhận mới chuyển sang kết quả. Nhóm chỉ thắng nếu tập K ID bị bầu trùng toàn bộ tập imposter; sai bất kỳ người nào thì phe mạo danh thắng.
- Back từ danh sách hoặc giai đoạn thảo luận yêu cầu xác nhận kết thúc; hủy giữ nguyên tiến độ.

## 9. Màn hình tiết lộ kết quả

### Bố cục

- Hiển thị thông báo kẻ mạo danh, ví dụ `KẺ MẠO DANH LÀ`.
- Hiển thị tên toàn bộ kẻ mạo danh thật, những người bị nhóm bầu và bên thắng.
- Hiển thị nhãn `TỪ BÍ MẬT`.
- Hiển thị từ bí mật lớn ở trung tâm, ví dụ `BÁNH STRUDEL TÁO`.
- Nút cuối màn hình: `Chơi lại`.

### Hành vi

- Kết quả chỉ xuất hiện sau khi nhóm hoàn tất bước bầu chọn.
- `Chơi lại` kết thúc ván và quay về màn thiết lập trò chơi, giữ nguyên danh sách người chơi, mode và danh mục để có thể chỉnh trước ván tiếp theo.
- Chỉ tạo session mới và random lại từ/vai/người bắt đầu khi nhấn `Bắt đầu trò chơi` tại màn thiết lập; được phép trùng từ khi tập nhỏ. Thiếu nội dung thì màn thiết lập chặn bắt đầu theo quy tắc chung.
- Back từ kết quả về thiết lập và hủy session. Ván không được khôi phục sau khi hệ điều hành đóng tiến trình.
- Nếu tập bị bầu không đúng toàn bộ imposter, màn hình vẫn hiển thị kết quả thực tế và phe mạo danh thắng.

## 10. Màn hình chọn người chơi — Trò chơi câu hỏi

### Bố cục

- Tiêu đề: `Người chơi`.
- Hướng dẫn: `Mỗi người chơi sẽ thấy câu hỏi của họ và gửi câu trả lời riêng tư.`
- Danh sách người chơi hiển thị dạng lưới hai cột.
- Mỗi thẻ gồm chữ cái đại diện và tên người chơi.
- Thẻ chưa trả lời có thể chạm để mở câu hỏi.
- Thẻ đã gửi câu trả lời được đánh dấu là đã hoàn tất.

## 11. Màn hình trả lời câu hỏi

### Bố cục

- Tiêu đề trên cùng: `Câu hỏi cho [Tên người chơi]`.
- Hiển thị tên người chơi ở trung tâm.
- Hiển thị danh mục câu hỏi bên dưới, ví dụ `Danh mục: Tiền Bạc & Danh Vọng`.
- Thẻ câu hỏi hiển thị câu hỏi dành riêng cho người chơi.
- Bên dưới là vùng nhập nhiều dòng với placeholder `Nhập câu trả lời của bạn ở đây...`.
- Nút `Gửi câu trả lời` nằm dưới vùng nhập.
- Bộ đếm cuối màn hình: `0 / 5 câu trả lời đã gửi`.

### Trạng thái câu hỏi bí mật

- Tất cả người chơi có cùng thẻ khóa. Phase 5 không báo vai hoặc tên đồng vai; **Phase 6 bổ sung** hiển thị tên các imposter khác khi bật `Kẻ mạo danh biết nhau`, có ít nhất hai imposter và chính imposter đã mở thẻ riêng. Không đưa chính mình vào danh sách, lọc bằng ID khi tên trùng. Khi tắt hoặc chỉ có một imposter, giữ hành vi không báo vai/đồng vai.
- Hiển thị biểu tượng khóa và dòng `Nhấn để hiển thị`.
- Sau khi chạm, câu hỏi mới được hiển thị để người chơi trả lời.
- Câu hỏi, danh mục và ô trả lời chỉ hiện sau khi mở thẻ, chỉ dành cho người chơi hiện tại. Danh sách đồng vai cũng chỉ hiện trong thẻ riêng đủ điều kiện; không lộ trên thẻ khóa, danh sách chuyển máy hoặc thảo luận. Không tiết lộ câu hỏi của phe còn lại hoặc câu trả lời riêng của người khác.
- App ra nền che câu hỏi/ô nhập và danh sách đồng vai, bỏ focus bàn phím và yêu cầu mở lại khi trở về. Back, gửi hoặc chuyển người cũng che danh sách đồng vai. Giá trị `knowEachOther` lấy từ snapshot khi bắt đầu ván.

### Hành vi

- Nút `Gửi câu trả lời` chỉ bật khi câu trả lời không trống.
- Sau khi gửi, tăng bộ đếm đã gửi và quay về màn hình `Người chơi`.
- Không cho phép sửa hoặc xem lại câu trả lời sau khi đã gửi. Trước khi gửi, back về danh sách giữ bản nháp riêng theo ID người chơi trong bộ nhớ; chỉ hiện lại sau khi mở thẻ của đúng người đó. Không lưu câu trả lời/bản nháp xuống đĩa hoặc backend.
- Khi tất cả người chơi đã gửi, chuyển sang bước thảo luận và tìm người nhận câu hỏi khác.

## 12. Màn hình xem câu hỏi chung

### Bố cục

- Tiêu đề: `Câu trả lời của mọi người`.
- Hiển thị một câu hỏi chung trong thẻ lớn ở trung tâm.
- Hiển thị hướng dẫn: `Đây là câu hỏi. Sắp tới bạn sẽ thấy tất cả câu trả lời và sau đó thảo luận xem ai đang nói dối về câu trả lời của họ.`
- Nút cuối màn hình: `Bắt đầu vòng`.

### Hành vi

- Chỉ mở màn hình này sau khi tất cả người chơi đã gửi câu trả lời.
- `Bắt đầu vòng` chuyển sang màn hình giai đoạn thảo luận.

## 13. Màn hình giai đoạn thảo luận — Trò chơi câu hỏi

### Bố cục

- Tiêu đề: `Giai đoạn thảo luận`.
- Hiển thị câu hỏi chung ở thẻ đầu màn hình.
- Danh sách câu trả lời hiển thị thành các thẻ theo thứ tự đánh số.
- Mỗi thẻ gồm số thứ tự, tên người chơi và câu trả lời của họ.
- Nút cuối màn hình: `Tìm kẻ giả mạo`.

### Hành vi

- Người chơi thảo luận dựa trên các câu trả lời được công khai.
- Không hiển thị câu hỏi riêng của người nhận câu hỏi khác trước khi tìm kẻ giả mạo.
- `Tìm kẻ giả mạo` công bố trực tiếp mọi kẻ mạo danh; không mở sheet bầu hoặc tính bên thắng trong game câu hỏi. Các luật bầu/thắng của word giữ nguyên.

## 14. Màn hình kết quả — Trò chơi câu hỏi

### Bố cục

- Giữ tiêu đề `Giai đoạn thảo luận` và câu hỏi chung ở đầu màn hình.
- Các câu trả lời vẫn hiển thị trong danh sách.
- Thẻ của mọi người nhận câu hỏi khác được đánh dấu nổi bật bằng nhãn `Kẻ mạo danh`.
- Thẻ này hiển thị thêm câu hỏi riêng mà người đó đã nhận.
- Nút cuối màn hình: `Chơi lại`.

### Hành vi

- Chỉ sau khi công bố kết quả mới hiển thị câu hỏi riêng của mọi kẻ mạo danh. Số imposter cố định/ngẫu nhiên và luật không đi trước dùng lại Phase 4; hiện tên người bắt đầu khi thảo luận. Back trước kết quả hỏi kết thúc ván.
- `Chơi lại` kết thúc ván và quay về màn thiết lập trò chơi, giữ nguyên danh sách người chơi và thiết lập. Ván mới chỉ được tạo sau khi nhấn bắt đầu tại màn thiết lập.

## 15. Màn hình tên người chơi

### Mục đích

Cho phép nhập, sắp xếp và quản lý danh sách người chơi trước khi chơi.

Editor danh sách hiện tại thuộc Phase 4; thư viện nhóm đã lưu thuộc Phase 6. Phase 6 phụ thuộc Phase 4–5 do bổ sung tùy chọn biết nhau cho question. Đặc tả Phase 6 được chốt ngày 27/10/2026, chưa phải trạng thái triển khai. Ảnh tham khảo dùng cho bố cục/tương tác; giao diện tiếp tục theo theme, component và rules hiện tại của app.

### Bố cục chính

1. **Thanh tiêu đề**
   - Nút quay lại ở bên trái.
   - Tiêu đề: `Chỉnh sửa người chơi`, dùng cách căn chỉnh của AppBar hiện tại.

2. **Thẻ danh sách đang chọn**
   - Hiển thị biểu tượng thư mục.
   - Đặt trên cùng nội dung, trước thông tin số người và roster.
   - Hiển thị tên nhóm đang chọn trong draft, ví dụ `Ban Văn Thể`; không chọn nhóm thì hiện `Trò chơi chưa lưu`.
   - Cả thẻ có thể chạm, có dấu hiệu mở bottom sheet `Danh sách đã lưu`.

3. **Thông tin số người chơi**
   - Hiển thị số lượng hiện tại, ví dụ `4 người chơi` hoặc `5 người chơi`.
   - Hiển thị giới hạn cho phép: `3–100`.

4. **Danh sách người chơi**
   - Mỗi người chơi nằm trong một thẻ riêng.
   - Thẻ gồm chữ cái đại diện, tên người chơi, số thứ tự và nút xóa.
   - Khi thêm người chơi vượt quá danh sách tên có sẵn, dùng tên mặc định như `Người chơi 5`.

5. **Thanh hành động cuối màn hình**
   - Giữ nút `Thêm` và nút xóa trên từng người; không thêm thao tác xóa hàng loạt.
   - Giữ nút `Xác nhận` cuối màn hình để áp dụng draft theo editor hiện tại.

### Hành vi danh sách hiện tại (Phase 4)

- Mở từ ô `Người chơi` tại setup. Phase 4 chỉ chỉnh danh sách hiện tại; Phase 6 bổ sung thẻ chọn nhóm và thư viện bên dưới.
- Nhập tên, trim khi xác nhận, chặn tên trống. Cho phép trùng tên vì vai được gắn bằng ID riêng ổn định.
- Thêm/xóa trong giới hạn 3–100; dùng số tên mặc định còn trống trong danh sách hiện tại, ID mới không tái sử dụng.
- Nút lên/xuống sắp xếp từng người, dùng được với screen reader; không cần kéo thả.
- Thao tác nằm trong draft; `Xác nhận` mới áp dụng/lưu. Back có thay đổi hỏi bỏ draft; hủy giữ nguyên form.
- Phase 4 báo lỗi lưu tại setup; khi triển khai Phase 6, xác nhận editor phải chờ ghi xong. Lỗi giữ draft, báo chưa lưu và cho thử lại ngay tại editor.

### Danh sách đã lưu

- Mở bằng cách chạm thẻ nhóm trên cùng editor.
- Hiển thị dưới dạng bottom sheet có tiêu đề `Danh sách đã lưu`.
- Có mục `Trò chơi chưa lưu`, mô tả `Chơi nhanh không cần lưu`.
- Các nhóm đã lưu hiển thị biểu tượng thư mục, tên, số người chơi và dấu chọn theo lựa chọn trong draft.
- Có hai hành động ở cuối:
  - `Lưu thành danh sách…` để lưu roster và luật trong draft thành nhóm mới.
  - `Quản lý danh sách` để mở màn hình quản lý.
- Chọn nhóm nạp roster/luật vào draft rồi đóng sheet; chưa đổi setup. Chọn `Trò chơi chưa lưu` giữ roster/luật trong draft và bỏ liên kết nhóm. Đóng sheet không chọn giữ nguyên draft.
- Hai hành động cuối xuống hàng khi thiếu chiều rộng; sheet cuộn được khi có nhiều nhóm hoặc chữ lớn.

### Lưu thành danh sách mới

- Đóng sheet chọn trước khi mở dialog `Lưu thành danh sách mới…`.
- Có trường nhập `Tên danh sách` với placeholder `Nhập tên danh sách`.
- Có hai hành động: `Hủy` và `Lưu`.
- Khi trường nhập được chọn, bàn phím hệ thống xuất hiện.
- Tên nhóm được trim, chặn rỗng và trùng sau trim/không phân biệt hoa thường. Roster phải hợp lệ, gồm 3–100 người và không có tên trống; tên người chơi có thể trùng vì dùng ID riêng.
- `Lưu` tạo nhóm từ roster/luật trong draft. Sau khi ghi thành công, đóng dialog và chọn nhóm mới trong editor; setup chỉ đổi sau `Xác nhận`.
- Hủy dialog giữ nguyên draft và thư viện. Nếu đã tạo nhóm thành công rồi bỏ draft editor, nhóm mới vẫn tồn tại, setup giữ lựa chọn đã xác nhận trước đó.
- Đang lưu chặn gửi lặp; lỗi giữ nội dung nhập, hiển thị thông báo và cho thử lại. Không đóng dialog hoặc báo thành công trước khi ghi xong.

### Quản lý danh sách

- Đóng sheet chọn trước khi mở màn riêng; thanh tiêu đề có nút quay lại và tiêu đề `Quản lý danh sách`. Back trở về editor, giữ draft.
- Mỗi nhóm là một card có biểu tượng thư mục, tên, số người chơi, nhãn `Đang dùng` nếu là nhóm đã xác nhận ở setup và nút ba chấm dọc.
- Chạm card mở chi tiết, không chuyển nhóm. Nút ba chấm mở popover neo tại nút, không đồng thời kích hoạt card, gồm:
  - `Chi tiết`.
  - `Đổi tên danh sách`.
  - `Xóa`.
- Ngăn cách thao tác xóa bằng divider, dùng màu lỗi từ theme. Đóng menu trước khi mở sheet/dialog tiếp theo.
- Khi chưa có nhóm, hiển thị hướng dẫn quay lại editor để dùng `Lưu thành danh sách…`. Loading/lỗi đọc có trạng thái rõ và nút thử lại; không coi lỗi đọc là thư viện rỗng.

### Đổi tên và xóa nhóm

- `Đổi tên danh sách` mở dialog điền sẵn tên, có `Hủy`/`Lưu`; validation giống tạo nhóm và bỏ qua chính nhóm đang đổi khi kiểm tra trùng. Đổi tên giữ ID, roster và luật; cập nhật tên ở mọi nơi khi ghi thành công.
- `Xóa` mở dialog xác nhận có tên nhóm, nút hủy và nút xóa. Hủy giữ dữ liệu; thành công chỉ xóa nhóm đó.
- Xóa nhóm đang dùng giữ nguyên roster/luật của setup và chuyển sang `Trò chơi chưa lưu`. Draft đang mở giữ nội dung nhưng bỏ liên kết nếu nhóm được chọn đã bị xóa; xác nhận sau đó không được tạo lại nhóm đã xóa.
- Lỗi ghi giữ dialog và nội dung để thử lại; không đóng hoặc báo thành công trước khi ghi xong. Chặn thao tác gửi lặp trong lúc ghi.

### Chi tiết danh sách

- Chạm card hoặc chọn `Chi tiết` mở cùng một bottom sheet chỉ đọc; không chọn/nạp nhóm vào setup hoặc draft.
- Hiển thị thẻ tổng quan gồm tên danh sách và số người chơi.
- Phần `Tên người chơi` hiển thị các tên dưới dạng chip/thẻ nhỏ theo đúng thứ tự đã lưu, tự xuống dòng.
- Phần `Cài đặt trò chơi` hiển thị:
  - Số lượng kẻ mạo danh cố định hoặc chế độ `Ngẫu nhiên`; không hiển thị số đã random của ván.
  - Trạng thái tùy chọn `Kẻ mạo danh không bao giờ đi trước`.
  - Trạng thái `Hiển thị danh mục cho kẻ mạo danh`.
  - Trạng thái `Kẻ mạo danh biết nhau`.
- Bỏ dòng `Hiển thị số kẻ mạo danh` vì app chưa có setting này; không thêm luật mới để khớp ảnh.
- Ghi chú: sửa người chơi được lưu khi `Xác nhận`; sửa luật ở setup tự lưu vào nhóm đang dùng. Các luật chỉ áp dụng với loại game đang hỗ trợ chúng.

### Dữ liệu, bản nháp và lưu trữ

- Nhóm lưu ID/tên nhóm, roster có ID/tên/thứ tự, bộ đếm ID tiếp theo và các luật imposter hiện có: số lượng, cố định/ngẫu nhiên, không đi trước, hiển thị danh mục và biết nhau.
- Không lưu loại game, mode, danh mục nội dung, UI/content locale, nội dung tùy chỉnh hoặc session vào nhóm. Chọn nhóm giữ nguyên các lựa chọn này của setup.
- Editor giữ draft riêng cho roster, luật và ID nhóm. Thêm/xóa/sửa/sắp xếp và chuyển nhóm chỉ thay draft. `Xác nhận` mới áp dụng vào setup và cập nhật nhóm được chọn nếu còn tồn tại; back có thay đổi hỏi bỏ draft. Bỏ draft không cập nhật nhóm cũ, không xóa nhóm mới đã lưu.
- Chọn `Trò chơi chưa lưu` chỉ bỏ liên kết nhóm sau `Xác nhận`, không xóa hay ghi đè nhóm vừa rời. Giảm số người tiếp tục giới hạn lại số imposter theo luật Phase 4.
- Luật chỉnh tại setup tự lưu vào nhóm đã xác nhận đang dùng; thay đổi người chơi chỉ lưu sau `Xác nhận`. Đổi tên/xóa trong màn quản lý lưu độc lập với draft editor.
- Dùng Hive/`LocalJsonStore` hiện có, ghi tuần tự và nguyên tử khi cập nhật setup/liên kết/thư viện để giữ dữ liệu nhất quán. Dữ liệu setup cũ khôi phục với thư viện rỗng, `Trò chơi chưa lưu` và nguyên roster/luật; giữ migration JSON → Hive hiện có.
- Lỗi đọc không tự reset hoặc ghi đè dữ liệu; cho thử lại và chặn ghi liên quan khi chưa đọc/validate được. Lỗi ghi giữ draft/form, báo chưa lưu và cho thử lại; không báo thành công chỉ vì state trong bộ nhớ đã đổi.
- Dữ liệu chỉ nằm trên thiết bị, không gửi tên người chơi/luật lên backend. Session đang chơi giữ nguyên snapshot.

### Quy tắc giao diện và kiểm tra

- Dùng `AppTheme`/`AppColors`, `AppContent`, spacing, routing, Signals/Riverpod và ARB VI/EN hiện có; không sao chép palette tím/nền tối trong ảnh.
- Sheet/modal hỗ trợ cuộn, SafeArea, bàn phím, màn nhỏ và text scale 2; nút biểu tượng có nhãn truy cập, trạng thái chọn/đang dùng có chữ hoặc dấu chọn.
- Kiểm tra bằng unit/widget test và đóng/mở storage thật: chọn/xác nhận/hủy draft, tạo nhóm rồi bỏ draft, tự lưu luật, chi tiết, đổi tên, xóa nhóm đang dùng, draft không khôi phục nhóm đã xóa, lỗi/retry và dữ liệu cũ. Hồi quy word sau khi nạp nhóm; chạy l10n/analyze/test khi triển khai.
- Không yêu cầu chụp ảnh hoặc image-based UI verification cho Phase 6. Không thêm đồng bộ, đăng nhập hoặc luật chơi mới.

## 16. Màn hình cài đặt

### Mục đích

Cho phép người dùng thay đổi ngôn ngữ, mở hướng dẫn, gửi đánh giá hoặc phản hồi và xem thông tin nhận diện ứng dụng.

### Bố cục

1. **Thanh tiêu đề**
   - Nút quay lại ở bên trái.
   - Tiêu đề căn giữa: `Cài đặt`.

2. **Nhóm tùy chọn chung**
    - `Ngôn ngữ giao diện`: có biểu tượng, ngôn ngữ hiện tại và mũi tên mở màn hình chọn ngôn ngữ giao diện. Nội dung game vẫn giữ tiếng Việt cho tới phase 12.
   - `Cách chơi`: có biểu tượng và mũi tên mở màn hình hướng dẫn.
   - Hai mục nằm trong cùng một thẻ và được ngăn cách bằng đường phân chia.

3. **Nhóm đánh giá và phản hồi**
   - `Đánh giá ứng dụng`: mở trang đánh giá ứng dụng trên cửa hàng tương ứng với nền tảng khi đã cấu hình đích.
   - `Gửi phản hồi`: mở kênh gửi phản hồi cho nhà phát triển khi đã cấu hình đích.
   - Nếu chưa có URL/app ID hoặc kênh phản hồi, hai mục ở trạng thái chưa khả dụng và giải thích rõ; không gắn URL giả.
   - Hai mục nằm trong cùng một thẻ và được ngăn cách bằng đường phân chia.

4. **Thông tin ứng dụng**
   - Tiêu đề nhóm: `Thông tin ứng dụng`.
   - `Phiên bản ứng dụng`: hiển thị phiên bản và build hiện tại, ví dụ `4.2.2 (158)`.
    - `ID cài đặt`: hiển thị ID ẩn danh chỉ lưu trên thiết bị ở dạng rút gọn và có nút sao chép toàn bộ.
   - Hai mục nằm trong cùng một thẻ và được ngăn cách bằng đường phân chia.

### Hành vi

- Chọn ngôn ngữ giao diện cập nhật nội dung hiển thị ngay và được lưu trên thiết bị; không đổi ngôn ngữ nội dung game.
- Chạm `Cách chơi` mở màn hình hướng dẫn hiện có.
- Chạm `Đánh giá ứng dụng` hoặc `Gửi phản hồi` chuyển sang ứng dụng phù hợp trên thiết bị nếu đã cấu hình; nếu chưa, mục bị vô hiệu hóa và nêu lý do.
- Chạm nút sao chép lưu toàn bộ ID cài đặt vào clipboard dù giá trị trên màn hình đang được rút gọn.
- Nút quay lại đưa người dùng về màn hình trước đó.

## 17. Quy tắc bố cục dùng chung

- Màn hình dùng bố cục dọc, ưu tiên thiết bị di động.
- Nội dung chính được căn giữa theo chiều ngang.
- Các khối nội dung lớn dùng thẻ bo góc.
- Nút hành động chính đặt gần cuối màn hình bắt đầu.
- Văn bản hướng dẫn chia thành tiêu đề ngắn và mô tả dễ đọc.
- Các màn hình dài phải hỗ trợ cuộn dọc.
- Giữ vùng an toàn cho thanh trạng thái và thanh điều hướng hệ điều hành.

## 18. Luồng hiện đã xác định

```text
Màn hình bắt đầu
├── Bắt đầu
│   └── Cài đặt trò chơi
│       ├── Cài đặt
│       │   ├── Ngôn ngữ
│       │   └── Cách chơi
│       ├── Chọn loại trò chơi
│       │   ├── Trò chơi từ ngữ
│       │   └── Trò chơi câu hỏi
│       ├── Chọn mode
│       │   ├── Cổ điển
│       │   └── Gia đình
│       ├── Chọn danh mục
│       │   ├── Tất cả danh mục
│       │   ├── Một hoặc nhiều danh mục cụ thể
│       │   └── Tạo danh mục tùy chỉnh
│       ├── Tên người chơi
│           ├── Danh sách đã lưu
│           │   ├── Lưu thành danh sách mới
│           │   └── Quản lý danh sách
│           │       └── Chi tiết danh sách
│       └── Bắt đầu trò chơi
│           └── Người chơi
│               └── Tiết lộ từ
│                   ├── Giai đoạn bầu chọn
│                   └── Tiết lộ kết quả
│           └── Trò chơi câu hỏi
│               ├── Người chơi
│               ├── Trả lời câu hỏi
│               ├── Câu trả lời của mọi người
│               ├── Giai đoạn thảo luận
│               └── Kết quả + Chơi lại
└── Cách chơi
    └── Danh sách hướng dẫn + Mẹo chuyên nghiệp
```

## 19. Các màn hình chờ bổ sung ảnh

- Tiết lộ vai trò hoặc từ bí mật.
- Đưa ra gợi ý.
- Bỏ phiếu.
- Kết quả ván chơi.
- Các màn hình phụ khác nếu có.

## Tài liệu liên quan

- [Kế hoạch triển khai ứng dụng theo phase/PR](../app-implementation-plan.md)
- [Bố cục màn hình Admin](admin-screen-layout.md)

### Ghi chú nghiệm thu Phase 7 — 27/10/2026

- App bar setup có `Làm mới nội dung` / `Refresh content`, tooltip/semantics và trạng thái disabled trong lúc đồng bộ. Nội dung giữ lại vẫn chơi được; thành công rỗng thay snapshot và category không còn hợp lệ được bỏ chọn.
- Ảnh word local nằm dưới từ ở thẻ người thường đã mở và màn kết quả. Không có ảnh/semantics ảnh ở thẻ che, imposter, danh sách người chơi hoặc thảo luận. Màn kết quả dùng cùng widget ảnh và vùng cuộn hiện có.
- Widget tests kiểm tra ảnh tới sau, file thiếu/decode lỗi, placeholder, lifecycle/semantics, không đổi session khi refresh, 320×568 với text scale 2 ở cả hai theme. Bộ test hiện có còn kiểm tra kết quả/voting ở 320×568, 844×390 và 1024×768.
- Không chụp screenshot; chưa kiểm tra trên thiết bị thật hoặc bản Release.
