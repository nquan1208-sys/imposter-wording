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

4. **Khu vực chọn mode**
   - Chỉ hiển thị sau khi đã chọn loại trò chơi.
   - Hai lựa chọn:
     - `Cổ điển` — sử dụng toàn bộ content cổ điển.
     - `Gia đình` — chỉ sử dụng content có `is_family_friendly = true`.
   - Một mode luôn ở trạng thái được chọn.

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
   - `Kẻ giả mạo biết nhau`.
   - Mỗi tùy chọn gồm biểu tượng, nhãn và công tắc bật/tắt.
   - Danh sách tùy chọn nằm trong cùng một thẻ và được ngăn cách bằng các đường phân chia.
   - Word chỉ có tiết lộ danh mục, không có công tắc hoặc dữ liệu hint riêng. Các tùy chọn tiết lộ danh mục/biết nhau hiện chỉ áp dụng word.
   - Chế độ `Trò chơi câu hỏi` không hiển thị tùy chọn gợi ý này.

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

- Chạm vào thẻ số lượng kẻ mạo danh sẽ mở một bảng chọn dạng bottom sheet.
- Tiêu đề bảng: `Chọn kẻ mạo danh`.
- Công tắc `Ngẫu nhiên` chuyển giữa hai cách chọn:
  - `Cố định`: chọn chính xác số kẻ mạo danh cho mỗi ván.
    - Có nút `−` và `+` để điều chỉnh số lượng.
    - Hiển thị giá trị hiện tại ở giữa.
    - Phạm vi hợp lệ là 1…floor((N−1)/2), với N từ 3 đến 100. Giảm N tự hạ số cố định về giới hạn mới.
  - `Ngẫu nhiên`: chọn đều số lượng trong cùng phạm vi hợp lệ, một lần khi bắt đầu ván.
- Công tắc `Kẻ mạo danh không đi trước` nằm ở setup. Chọn `startingPlayerId` trước; khi bật, loại ID này khỏi tập gán vai. Tên hiển thị ở thảo luận dùng cùng ID.
- Back bảng chọn hủy thay đổi; `Xác nhận` mới áp dụng.

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
   - App random trong toàn bộ content đã publish thuộc loại game và mode hiện tại.

5. **Danh mục tùy chỉnh**
   - Có thẻ `Tạo tùy chỉnh` nếu tính năng content tùy chỉnh được bật.
   - Danh mục tùy chỉnh chỉ được áp dụng cho ván hiện tại và lưu local.

### Hành vi

- Chạm vào một hoặc nhiều thẻ danh mục để chọn/bỏ chọn.
- Chọn `Tất cả danh mục` sẽ bỏ chọn toàn bộ danh mục cụ thể.
- Nút `Xác nhận` quay về màn hình cài đặt trò chơi và hiển thị số category đã chọn.
- Nếu không chọn danh mục cụ thể, giữ giá trị `Tất cả danh mục`.
- Danh sách và số lượng content được lọc theo loại game và mode đã chọn.
- Với mode `Gia đình`, chỉ hiển thị category có ít nhất một content `is_family_friendly = true`.
- Không mô tả hoặc triển khai các danh mục Premium trong phạm vi bản nháp này.

## 5. Màn hình tạo tùy chỉnh

### Mục đích

Cho phép người dùng tự tạo một danh mục từ riêng để sử dụng trong các ván chơi.

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
     - Ảnh thu nhỏ ở bên trái nếu đã thêm ảnh.
     - Nội dung từ ở giữa.
     - Nút thêm/thay ảnh.
     - Nút xóa ở bên phải.
   - Khi chưa có từ, hiển thị trạng thái trống: `Chưa có từ nào`.

4. **Thêm từ**
   - Nút `Thêm từ` đặt ngay dưới danh sách.
   - Chạm vào sẽ mở form thêm từ gồm:
     - Field `Từ` — bắt buộc trong chế độ `Trò chơi từ ngữ`.
     - Field `Câu hỏi` — bắt buộc trong chế độ `Trò chơi câu hỏi`.
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
   - Mỗi từ hoặc câu hỏi có field `Ảnh` riêng; ảnh không bắt buộc.
   - Chạm vào vùng ảnh của một từ sẽ cho phép:
     - Chọn ảnh từ thư viện.
     - Chụp ảnh mới.
     - Xóa ảnh hiện tại.
   - Nếu chưa có ảnh, hiển thị ô trống với biểu tượng thêm ảnh.
   - Khi nhập nhiều từ, chỉ tạo các từ; ảnh được thêm sau cho từng từ.

7. **Nút lưu**
   - Nút cố định ở cuối màn hình: `Lưu danh mục`.
   - Chỉ bật khi tên danh mục không trống và có ít nhất một từ.

### Trạng thái và hành vi

- Rời màn hình khi chưa lưu phải hỏi xác nhận nếu đã có thay đổi.
- Tên danh mục không được để trống.
- Mỗi từ được cắt khoảng trắng đầu/cuối trước khi lưu.
- Nếu danh mục đã tồn tại, yêu cầu đổi tên thay vì ghi đè.
- Lưu thành công sẽ quay về màn hình `Chọn danh mục`, tab `Cổ điển`, và chọn danh mục vừa tạo.
- Thẻ danh mục tùy chỉnh hiển thị tên danh mục, tổng số từ và trạng thái có ảnh minh họa.

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
- Phase 4 hỗ trợ nhiều kẻ mạo danh; khi bật `Biết nhau`, chỉ imposter đã mở thẻ mới thấy tên các imposter khác. Không hiện từ/ảnh cho imposter. Ảnh word được bổ sung ở Phase 7.
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

- Với người chơi nhận câu hỏi khác, thẻ câu hỏi ở trạng thái khóa.
- Hiển thị biểu tượng khóa và dòng `Nhấn để hiển thị`.
- Sau khi chạm, câu hỏi mới được hiển thị để người chơi trả lời.
- Câu hỏi và câu trả lời chỉ dành cho người chơi hiện tại.

### Hành vi

- Nút `Gửi câu trả lời` chỉ bật khi câu trả lời không trống.
- Sau khi gửi, tăng bộ đếm đã gửi và quay về màn hình `Người chơi`.
- Không cho phép sửa hoặc xem lại câu trả lời sau khi đã gửi.
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
- `Tìm kẻ giả mạo` chuyển sang trạng thái công bố kết quả.

## 14. Màn hình kết quả — Trò chơi câu hỏi

### Bố cục

- Giữ tiêu đề `Giai đoạn thảo luận` và câu hỏi chung ở đầu màn hình.
- Các câu trả lời vẫn hiển thị trong danh sách.
- Thẻ của người nhận câu hỏi khác được đánh dấu nổi bật bằng nhãn `Kẻ mạo danh`.
- Thẻ này hiển thị thêm câu hỏi riêng mà người đó đã nhận.
- Nút cuối màn hình: `Chơi lại`.

### Hành vi

- Chỉ sau khi công bố kết quả mới hiển thị câu hỏi riêng của kẻ mạo danh.
- `Chơi lại` kết thúc ván và quay về màn thiết lập trò chơi, giữ nguyên danh sách người chơi và thiết lập. Ván mới chỉ được tạo sau khi nhấn bắt đầu tại màn thiết lập.

## 15. Màn hình tên người chơi

### Mục đích

Cho phép nhập, sắp xếp và quản lý danh sách người chơi trước khi chơi.

### Bố cục chính

1. **Thanh tiêu đề**
   - Nút quay lại ở bên trái.
   - Tiêu đề căn giữa: `Tên người chơi`.

2. **Thẻ danh sách đang chọn**
   - Hiển thị biểu tượng thư mục.
   - Hiển thị tên danh sách, ví dụ `Ban Văn Thể`.
   - Có nút mở danh sách đã lưu.

3. **Thông tin số người chơi**
   - Hiển thị số lượng hiện tại, ví dụ `4 người chơi` hoặc `5 người chơi`.
   - Hiển thị giới hạn cho phép: `3–100`.

4. **Danh sách người chơi**
   - Mỗi người chơi nằm trong một thẻ riêng.
   - Thẻ gồm chữ cái đại diện, tên người chơi, số thứ tự và nút xóa.
   - Khi thêm người chơi vượt quá danh sách tên có sẵn, dùng tên mặc định như `Người chơi 5`.

5. **Thanh hành động cuối màn hình**
   - `Xóa`: xóa người chơi hoặc thao tác xóa theo ngữ cảnh hiện tại.
   - `Thêm`: thêm một người chơi mới vào danh sách.

### Hành vi danh sách hiện tại (Phase 4)

- Mở bằng `Chỉnh sửa người chơi` tại setup; chưa mở thư viện danh sách đã lưu (Phase 6).
- Nhập tên, trim khi xác nhận, chặn tên trống. Cho phép trùng tên vì vai được gắn bằng ID riêng ổn định.
- Thêm/xóa trong giới hạn 3–100; dùng số tên mặc định còn trống trong danh sách hiện tại, ID mới không tái sử dụng.
- Nút lên/xuống sắp xếp từng người, dùng được với screen reader; không cần kéo thả.
- Thao tác nằm trong draft; `Xác nhận` mới áp dụng/lưu. Back có thay đổi hỏi bỏ draft; hủy giữ nguyên form.
- Lỗi lưu giữ roster trong bộ nhớ và hiện cảnh báo/thử lại tại setup.

### Danh sách đã lưu

- Mở từ nút chọn danh sách ở thẻ danh sách đang chọn.
- Hiển thị dưới dạng bottom sheet có tiêu đề `Danh sách đã lưu`.
- Có mục `Trò chơi chưa lưu` để chơi nhanh không lưu.
- Các danh sách đã lưu hiển thị tên, số người chơi và dấu chọn cho danh sách đang dùng.
- Có hai hành động ở cuối:
  - `Lưu thành danh sách...` để lưu cấu hình hiện tại thành danh sách mới.
  - `Quản lý danh sách` để mở màn hình quản lý.

### Lưu thành danh sách mới

- Hiển thị hộp thoại/modal `Lưu thành danh sách mới...`.
- Có trường nhập `Tên danh sách` với placeholder `Nhập tên danh sách`.
- Có hai hành động: `Hủy` và `Lưu`.
- Khi trường nhập được chọn, bàn phím hệ thống xuất hiện.

### Quản lý danh sách

- Thanh tiêu đề: nút quay lại và tiêu đề `Quản lý danh sách`.
- Danh sách các bộ người chơi đã lưu hiển thị thành từng thẻ.
- Mỗi thẻ có menu thao tác:
  - `Chi tiết`.
  - `Đổi tên danh sách`.
  - `Xóa`.

### Chi tiết danh sách

- Mở dưới dạng bottom sheet.
- Hiển thị thẻ tổng quan gồm tên danh sách và số người chơi.
- Phần `Tên người chơi` hiển thị các tên dưới dạng chip/thẻ nhỏ.
- Phần `Cài đặt trò chơi` hiển thị:
  - Số lượng kẻ mạo danh.
  - Trạng thái hiển thị số kẻ mạo danh.
  - Trạng thái tùy chọn `Kẻ mạo danh không bao giờ đi trước`.
- Có ghi chú rằng thay đổi sẽ được lưu tự động khi sử dụng danh sách.

### Hành vi

- Thay đổi số người chơi cập nhật danh sách thẻ ngay lập tức.
- Có thể xóa từng người chơi bằng nút xóa trên thẻ.
- Có thể thêm người chơi bằng nút `Thêm`.
- Chọn một danh sách đã lưu sẽ nạp lại tên người chơi và cấu hình liên quan.

## 16. Màn hình cài đặt

### Mục đích

Cho phép người dùng thay đổi ngôn ngữ, mở hướng dẫn, gửi đánh giá hoặc phản hồi và xem thông tin nhận diện ứng dụng.

### Bố cục

1. **Thanh tiêu đề**
   - Nút quay lại ở bên trái.
   - Tiêu đề căn giữa: `Cài đặt`.

2. **Nhóm tùy chọn chung**
   - `Ngôn ngữ`: có biểu tượng, ngôn ngữ hiện tại và mũi tên mở màn hình chọn ngôn ngữ.
   - `Cách chơi`: có biểu tượng và mũi tên mở màn hình hướng dẫn.
   - Hai mục nằm trong cùng một thẻ và được ngăn cách bằng đường phân chia.

3. **Nhóm đánh giá và phản hồi**
   - `Đánh giá ứng dụng`: mở trang đánh giá ứng dụng trên cửa hàng tương ứng với nền tảng.
   - `Gửi phản hồi`: mở kênh gửi phản hồi cho nhà phát triển.
   - Hai mục nằm trong cùng một thẻ và được ngăn cách bằng đường phân chia.

4. **Thông tin ứng dụng**
   - Tiêu đề nhóm: `Thông tin ứng dụng`.
   - `Phiên bản ứng dụng`: hiển thị phiên bản và build hiện tại, ví dụ `4.2.2 (158)`.
   - `ID khách hàng`: hiển thị ID ẩn danh ở dạng rút gọn và có nút sao chép.
   - Hai mục nằm trong cùng một thẻ và được ngăn cách bằng đường phân chia.

### Hành vi

- Chọn ngôn ngữ cập nhật nội dung hiển thị và được lưu trên thiết bị.
- Chạm `Cách chơi` mở màn hình hướng dẫn hiện có.
- Chạm `Đánh giá ứng dụng` hoặc `Gửi phản hồi` chuyển sang ứng dụng phù hợp trên thiết bị.
- Chạm nút sao chép lưu toàn bộ ID khách hàng vào clipboard dù giá trị trên màn hình đang được rút gọn.
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
