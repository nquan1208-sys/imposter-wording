# Nghiên cứu chế độ gia đình cho trò câu hỏi

Ngày nghiên cứu: 03/11/2026. Cập nhật triển khai: 04/11/2026.
Đã có dữ liệu mẫu, bộ lọc Family cho trò câu hỏi, điều khiển admin và kiểm tra tự động.
Luật chơi giữ nguyên; đánh giá độ phù hợp và cân bằng bằng chơi thử vẫn đang chờ.

## Tham khảo và hướng chọn

| Nguồn chính thức | Cơ chế liên quan | Áp dụng cho dự án |
| --- | --- | --- |
| [Herd Mentality — Big Potato](https://bigpotato.co.uk/blogs/how-to-play/herd-mentality) | Viết đáp án riêng, so đáp án theo số đông; nhà phát hành ghi 10+ | Dùng sở thích và tình huống quen thuộc, không đòi kiến thức chuyên môn. Không thêm tính điểm theo đa số. |
| [Insider — Oink Games](https://oinkgames.com/en/games/analog/insider/) | Hỏi đáp, thảo luận và tìm người ẩn vai; nhà phát hành ghi 9+ | Giữ phần suy luận từ câu trả lời và thảo luận. Không thêm quản trò hay vòng đố có đáp án đúng. |

Đề xuất riêng cho app: giữ lượt xem câu hỏi bí mật → nhập đáp án → xem câu hỏi
chung → thảo luận → lộ vai. Thử nghiệm trước với người có thể tự đọc và nhập đáp án,
khoảng 10 tuổi trở lên; đây là giả thuyết cần chơi thử, không phải phân loại tuổi đã xác nhận.

## Tiêu chí biên soạn

- Mỗi câu yêu cầu một đáp án ngắn; hai câu trong cặp cùng kiểu đáp án: món ăn,
  hoạt động, địa điểm, màu sắc hoặc đồ vật. Ví dụ: trái cây làm nước ép / làm kem.
- Hai hoàn cảnh khác nhau nhưng có vùng đáp án giao nhau; tránh cặp quá xa khiến
  người ẩn vai lộ ngay, hoặc gần như đồng nghĩa khiến không có manh mối.
- Không hỏi thu nhập, tình cảm, bí mật, ngoại hình, xếp hạng thành viên hay trải
  nghiệm bắt buộc như từng đi máy bay. Không yêu cầu biết người nổi tiếng.
- Không chép bộ thẻ của nguồn tham khảo. 15 cặp trong seed được biên soạn mới.
- `easy` là nhãn biên tập ban đầu; phù hợp nội dung không đồng nghĩa đã cân bằng
  độ khó suy luận. Cần thử với nhóm có trẻ em và người lớn.

## Dữ liệu đã thêm

| Danh mục | Slug | Số cặp |
| --- | --- | --- |
| Gia đình · Bữa ăn vui vẻ | `family-mealtime` | 5 |
| Gia đình · Cùng nhau mỗi ngày | `family-together` | 5 |
| Gia đình · Tưởng tượng ngộ nghĩnh | `family-imagination` | 5 |

Mỗi cặp và danh mục có bản Việt/Anh đã publish, dùng chung ID. Trong trò câu hỏi,
vào Danh mục → Chế độ gia đình → Xác nhận. Không chọn riêng danh mục nghĩa là
chơi toàn bộ danh mục được gắn cờ Family; không trộn câu hỏi ngoài bộ lọc.
Tab Tất cả danh mục vẫn cho chơi nội dung thông thường và nội dung tự tạo.
Cần kết nối backend local và tải mới nội dung; cache cũ thiếu cờ Family sẽ cho
kết quả rỗng trong Family thay vì dùng nội dung chưa được duyệt.

Seed nằm ở `supabase/seed_family_questions.sql`, chạy trong một transaction,
ID cố định và `ON CONFLICT ... DO NOTHING` để giữ chỉnh sửa đã có. File được khai
báo sau `seed.sql` trong `config.toml` nên DB mới cũng nhận dữ liệu này theo
[cơ chế seed của Supabase](https://supabase.com/docs/guides/local-development/seeding-your-database).

Nạp thêm vào stack local đang chạy, không reset và không nạp lại seed khác:

```bash
rtk proxy supabase migration up --local
rtk proxy sh -c 'docker exec -i supabase_db_imposter-wording psql -U postgres -d postgres -v ON_ERROR_STOP=1 < supabase/seed_family_questions.sql'
rtk proxy sh -c 'docker exec -i supabase_db_imposter-wording psql -U postgres -d postgres -v ON_ERROR_STOP=1 < supabase/tests/family_question_seed.sql'
```

Kiểm tra SQL dùng role `anon`: 3 danh mục, mỗi mục 5 cặp easy, đủ bản dịch publish
ở cả hai ngôn ngữ. Chạy lại seed không thêm trùng, không cập nhật nội dung cũ.

## Bộ lọc Family đã triển khai

- DB: migration `20261104082852_question_family_mode.sql` bỏ CHECK
  `family_word_categories_only`, bật cờ cho đúng 3 ID/slug seed nêu trên nếu đã tồn tại.
  Seed mới tạo danh mục có cờ Family; chạy lại không ghi đè chỉnh sửa đã có.
  RPC, RLS và cấu trúc types giữ nguyên vì đã hỗ trợ cờ ở cấp danh mục.
- Admin: form cho bật/tắt Family với cả word và question, giữ cờ khi đổi loại game;
  danh sách và bộ lọc dùng lại cột/RPC có sẵn.
- App: hai loại game dùng chung tab Tất cả/Family và cơ chế bản nháp → xác nhận.
  Lọc từ danh mục đã duyệt xuyên suốt số lượng, lựa chọn và tạo phiên chơi.
  Family được lưu và giữ khi chuyển game hoặc đổi ngôn ngữ; danh mục không còn
  hợp lệ được bỏ khỏi lựa chọn. Không có nội dung Family thì không bắt đầu ván.
- Câu hỏi tự tạo không được tự gắn cờ; chỉ hiện và tham gia trò chơi ở chế độ
  Tất cả. Tab Family của câu hỏi không có nút tạo danh mục. Nội dung đã lưu vẫn còn.
  Tuỳ chọn hiển thị ảnh ở tab Family tiếp tục dành riêng cho trò từ.

Migration đã áp dụng trên DB local, không reset dữ liệu. Khi triển khai môi trường
khác, phát hành app có model mới trước khi bật cờ Family cho câu hỏi: app cũ từ chối
snapshot có danh mục question mang cờ này. Chưa triển khai remote/production.

Các kiểm tra tự động bao gồm lọc category (không tin cờ prompt cũ), cache thiếu cờ,
VI/EN, đổi ngôn ngữ, chuyển game, lưu/khôi phục Family, danh mục rỗng, loại câu hỏi
tự tạo, hủy bản nháp, lỗi lưu và thử lại; SQL kiểm tra quyền anon/admin và RPC.

## Chơi thử còn chờ

Cần chơi thử 15 cặp với nhóm có trẻ em và người lớn: ghi cặp khó hiểu, đáp án thường
gặp và trường hợp người ẩn vai lộ chỉ vì kiểu đáp án. Chưa có kết quả chơi thử để
xác nhận độ cân bằng hoặc độ tuổi phù hợp; nhãn `easy` chỉ là đánh giá biên tập.
Không suy từ nhãn tuổi của game tham khảo rằng bộ câu hỏi đã phù hợp mọi gia đình.
