# Nghiên cứu chế độ gia đình cho trò câu hỏi

Ngày nghiên cứu: 03/11/2026. Phần đã triển khai: dữ liệu mẫu local và kiểm tra SQL.
Đề xuất luật và mở rộng bộ lọc bên dưới chưa được triển khai.

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
chọn riêng các danh mục trên để chơi bộ gia đình. Nếu không chọn danh mục, app vẫn
trộn với các câu hỏi khác. Cần kết nối backend local và tải mới nội dung; cache offline
cũ chưa có dữ liệu vừa thêm.

Seed nằm ở `supabase/seed_family_questions.sql`, chạy trong một transaction,
ID cố định và `ON CONFLICT ... DO NOTHING` để giữ chỉnh sửa đã có. File được khai
báo sau `seed.sql` trong `config.toml` nên DB mới cũng nhận dữ liệu này theo
[cơ chế seed của Supabase](https://supabase.com/docs/guides/local-development/seeding-your-database).

Nạp thêm vào stack local đang chạy, không reset và không nạp lại seed khác:

```bash
rtk proxy sh -c 'docker exec -i supabase_db_imposter-wording psql -U postgres -d postgres -v ON_ERROR_STOP=1 < supabase/seed_family_questions.sql'
rtk proxy sh -c 'docker exec -i supabase_db_imposter-wording psql -U postgres -d postgres -v ON_ERROR_STOP=1 < supabase/tests/family_question_seed.sql'
```

Kiểm tra SQL dùng role `anon`: 3 danh mục, mỗi mục 5 cặp easy, đủ bản dịch publish
ở cả hai ngôn ngữ. Chạy lại seed không thêm trùng, không cập nhật nội dung cũ.

## Phạm vi cần sửa nếu mở rộng thành bộ lọc Family

Hiện `family_word_categories_only` cấm gắn cờ Family cho câu hỏi.
Vì vậy các danh mục mới giữ `is_family_friendly = false`; tên/slug chỉ giúp chọn
thủ công, không phải hợp đồng lọc. Không thể chỉ bật cờ trong DB.

1. DB: bỏ hoặc thay CHECK giới hạn loại game; dùng lại cờ ở danh mục, không thêm
   cờ từng prompt. Kiểm tra RPC danh mục, RLS và sinh lại types nếu cần.
2. Admin: bỏ điều kiện ép cờ false khi `game_type = question` trong
   `admin/src/utils/categories.ts`; cho hiển thị điều khiển Family ở form và danh sách.
3. App: bỏ giới hạn Family chỉ ở word trong `GameSetup`, thêm lọc ở
   `ContentRepository.eligibleQuestions` và các caller/count trong `SetupStore`;
   mở chọn tab cho câu hỏi theo cơ chế bản nháp/xác nhận sẵn có.
4. Quyết định cách xử lý danh mục câu hỏi tự tạo: hiện không có cờ Family;
   không tự coi nội dung người dùng nhập là đã duyệt.
5. Kiểm tra chuyển game, phục hồi cấu hình/cache cũ, đổi ngôn ngữ, danh mục rỗng,
   hủy lựa chọn và lỗi lưu; Family phải không lọt câu hỏi ngoài danh mục được duyệt.

Trước khi mở rộng, chơi thử 15 cặp: ghi cặp khó hiểu, đáp án thường gặp và trường
hợp người ẩn vai lộ chỉ vì kiểu đáp án. Đánh giá nội dung với cả trẻ em lẫn người lớn;
không suy từ nhãn tuổi của game tham khảo rằng bộ câu hỏi đã phù hợp mọi gia đình.
