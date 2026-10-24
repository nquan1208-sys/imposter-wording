# Kế hoạch triển khai ứng dụng

> Nguồn yêu cầu: [Bố cục màn hình ứng dụng](layout/screen-layout.md). Đối chiếu code và migration trong repository ngày 24/10/2026, gồm schema nội dung đa ngôn ngữ mới. Trạng thái dưới đây dựa trên source; riêng phase 1 đã chạy analyze/test và smoke trên iOS Simulator như ghi bên dưới. Chưa xác minh backend đang chạy.

## 1. Mục tiêu và cách chia PR

Triển khai app Flutter chơi chung trên một thiết bị, gồm game từ ngữ và game câu hỏi. Ưu tiên có một ván chơi hoàn chỉnh sớm bằng nội dung tiếng Việt, sau đó thêm các khả năng cấu hình, quản lý nội dung và chọn ngôn ngữ nội dung từ DB.

**Một phase tương ứng một PR.** Mỗi PR có đầu ra sử dụng được, đường vào từ giao diện, kiểm thử riêng và không cần merge một PR đang dở để chạy. Các phase có thể phụ thuộc những PR **đã merge**; độc lập không có nghĩa là tất cả PR đều làm từ cùng một baseline hoặc merge theo thứ tự bất kỳ.

- Mỗi PR gồm UI, store, dữ liệu/validation, route, bản dịch và test cần cho chính tính năng đó.
- Các chức năng chưa triển khai được ẩn hoặc có trạng thái chưa khả dụng rõ ràng; không có nút dẫn tới màn trống hay route không tồn tại.
- Phase 1–2 tạo nền và luồng thiết lập sử dụng được; **phase 3 là mốc đầu tiên chơi trọn một ván**.
- Tính năng đang hoạt động phải tiếp tục chạy sau mỗi lần merge. Không tách một tính năng thành PR UI chỉ có mock và PR logic bắt buộc phải merge cùng lúc.
- Không đưa thay đổi kiến trúc toàn app, làm lại admin hoặc dịch vụ backend mới vào PR tính năng nếu chưa cần.

## 2. Baseline đã kiểm tra

| Khu vực | Hiện trạng trong repository | Hệ quả với kế hoạch |
| --- | --- | --- |
| App | Entry là `LandingScreen`, có `HowToPlayScreen`, theme sáng/tối; nút Bắt đầu đang disabled | Phần nền phase 1 đã có trong source; tiếp tục setup ở phase 2, chưa có luồng chơi. |
| State và DI | `StoreBase`, `StoreProvider`, Signals, `AutoDisposeManager`, Riverpod | Tái sử dụng code hiện tại; không đưa thêm một cơ chế state management. |
| Điều hướng | `RouterService`, `RouteName`, `RouteInput`, `RoutePage`, `RouteScreen`; route landing/Cách chơi/unknown | Dùng Navigator/service hiện có; luồng sản phẩm không còn bottom navigation demo. |
| Tài liệu app | README và `app/docs/` đã mô tả Signals/Store, routing và VI/EN | Tái sử dụng hướng dẫn hiện tại, cập nhật theo tính năng mới. |
| Ngôn ngữ giao diện | Có ARB VI/EN, mặc định `vi`; `AppStore.setLocale` cập nhật MaterialApp nhưng chỉ giữ trong bộ nhớ | Phase 11 thêm picker và lưu UI locale; phase 12 tích hợp ngôn ngữ nội dung độc lập. |
| Cấu hình backend | `AppConfig` đã đọc/validate URL và publishable key theo `APP_ENV`; chưa khởi tạo client hay gọi API | Phase 2 dùng config hiện có, thêm client/repository và quyền đọc anon; không dựng lại cấu hình môi trường. |
| Backend nội dung | Ba bảng gốc, `content_languages` và ba bảng translation; grants/RLS đọc public đã đổi theo bản dịch | Mobile đọc Data API với quyền anon, không dùng các RPC quản trị `admin_*`/`save_*`. |
| Schema hiện tại | Bảng gốc giữ ID/metadata dùng chung; tên danh mục, từ, cặp câu hỏi, `locale` và trạng thái nằm ở translation | Không select `text`/`status`/`locale` từ prompt gốc hoặc `name` từ category gốc. Word giữ `image_path` dùng chung; question chưa có ảnh remote. |
| Dữ liệu trên thiết bị | Chưa có repository content, lưu thiết lập/danh sách, ảnh tùy chỉnh hoặc session game | Thêm khi phase sử dụng tới; không giả định những phần này đã có. |
| Kiểm thử | Có test onboarding/back/VI–EN, cấu hình, theme và auto-dispose; analyze sạch, 27/27 test pass khi nghiệm thu phase 1 | Giữ test nền và thêm test dữ liệu/luật chơi theo từng PR; kết quả này không xác nhận các phase chưa triển khai. |

Nguồn kỹ thuật chính: [pubspec](../app/pubspec.yaml), [AppStore](../app/lib/store/app_store.dart), [routing](../app/lib/base/dependency/router/utils/route_page.dart), [AppConfig](../app/lib/config/app_config.dart), [schema](database-schema.dbml), [migration translations và RLS/Storage hiện tại](../supabase/migrations/20261024045640_content_translations.sql), [test quyền đọc đa ngôn ngữ](../supabase/tests/content_translations.sql), [quy trình cutover backend](plans/admin-content-translations/admin-content-translations-phase-6.md).

Các nhận định backend ở đây dựa trên file trong repo. Báo cáo cutover ghi đã kiểm thử local, chưa triển khai cloud; trước phase 2 phải xác minh backend đích đã áp dụng schema mới và quyền anon đọc được. Không giả định Dev/Production có cùng schema với local; app không hỗ trợ đồng thời schema cũ và mới.

## 3. Những quyết định cần chốt trước phase liên quan

Các phương án dưới đây là **đề xuất triển khai**, không tự thay thế yêu cầu trong layout. Khi chốt, cập nhật layout và test trong cùng PR liên quan.

| Điểm chưa rõ | Đề xuất nhỏ nhất | Cần chốt trước |
| --- | --- | --- |
| Mục 3 có `Hiển thị gợi ý`, nhưng mục 7 cấm lộ hint và backend đã bỏ hint | Chỉ giữ `Hiển thị danh mục cho kẻ mạo danh`; không dựng một nguồn hint mới. Nếu cần gợi ý khác danh mục, phải có đặc tả nội dung và dữ liệu riêng. | Phase 4 |
| Phạm vi số kẻ mạo danh chưa có công thức; `1–4` chỉ là ví dụ | Với N người, dùng 1…floor((N−1)/2), bảo đảm phe thường chiếm đa số; random đều trong phạm vi đó. Với tùy chọn không đi trước, chọn người bắt đầu trước rồi loại người đó khỏi tập gán vai. | Phase 4; phase 3 chỉ dùng 1 kẻ mạo danh |
| Layout vừa nói không đi trước theo người chơi đầu tiên, vừa nói chọn người bắt đầu | Dùng một `startingPlayerId` làm nguồn duy nhất cho luật gán vai và tên người bắt đầu trên màn thảo luận. | Phase 4 |
| Chưa có UI ghi nhận người bị bầu, xử lý hòa hoặc luật thắng khi có nhiều kẻ mạo danh | Nhóm bầu bằng lời nói; nút công bố mở sheet chọn người bị nhóm bầu rồi xác nhận. Một imposter: chọn đúng thì nhóm thắng, sai thì imposter thắng. Nhiều imposter: đề xuất chọn đúng K người và nhóm chỉ thắng khi chọn đúng toàn bộ tập imposter. Nếu hòa, nhóm bầu lại trước khi xác nhận; chưa làm hệ thống thu từng phiếu. | Sheet ở phase 3; luật nhiều imposter phải chốt trước phase 4 |
| Game câu hỏi chưa rõ có báo vai cho người nhận câu hỏi khác hay không | Chỉ hiện câu hỏi riêng, không tự báo vai. Các công tắc tiết lộ danh mục/biết nhau chỉ áp dụng word trong bản đầu; question cần duyệt riêng nếu muốn dùng. | Phase 5 |
| Tùy chỉnh chỉ dùng cho ván hiện tại nhưng cũng nói lưu local và các ván; sau lưu lại về tab `Cổ điển` không tồn tại ở màn danh mục | Giữ nội dung tùy chỉnh cho bộ thiết lập hiện tại và `Chơi lại`, không làm thư viện lâu dài. Sau lưu trở về picker theo đúng loại game/mode hiện tại. Không tự đổi từ Gia đình sang Cổ điển. | Phase 8 |
| Một field `Câu hỏi` không đủ tạo game với hai nhóm nhận câu hỏi khác nhau | Form question tùy chỉnh phải nhập một cặp câu hỏi khác nhau. Nhập nhiều dùng hai ô nhiều dòng, ghép cặp theo dòng, kiểm tra số dòng bằng nhau. | Phase 9 |
| Tùy chỉnh chưa có thuộc tính phù hợp gia đình | Khi tạo trong mode Gia đình, yêu cầu người tạo xác nhận nội dung phù hợp; không mặc định mọi nội dung tự nhập là phù hợp gia đình. | Phase 8–9 |
| Chi tiết danh sách đã lưu có `Hiển thị số kẻ mạo danh`, nhưng setup chưa có công tắc tương ứng | Cần quyết định thêm công tắc ở bảng chọn kẻ mạo danh hoặc bỏ dòng này ở chi tiết. Không tạo một setting không thể chỉnh từ UI. | Phase 6 |
| Mục 16 chỉ có một dòng Ngôn ngữ, trong khi DB đã hỗ trợ bản dịch nội dung riêng | Đề xuất tách `Ngôn ngữ giao diện` (VI/EN từ ARB) và `Ngôn ngữ nội dung` (từ `content_languages`), mặc định đều `vi`. Đổi UI không tự đổi đề; thiếu bản dịch nội dung thì báo rỗng, không fallback sang ngôn ngữ khác. Cập nhật layout khi chốt. | Phase 11–12 |
| Chưa có ảnh cho mọi trạng thái, store URL và kênh phản hồi | Tái sử dụng theme hiện có; không hứa khớp pixel. URL/ID phát hành phải được cung cấp trước phase 11/13. | Theo phase tương ứng |

Nếu một quyết định chưa được chốt, giữ chức năng liên quan chưa khả dụng và ghi rõ trong PR; không báo phase đó hoàn tất toàn bộ đặc tả.

## 4. Quy tắc dữ liệu và vòng đời dùng xuyên suốt

### Nội dung game

Hợp đồng đọc theo schema mới, áp dụng ngay từ phase 2 dù lúc đầu chỉ dùng nội dung `vi`:

| Nguồn | Trường dùng cho app | Quy tắc |
| --- | --- | --- |
| `content_languages` | `code`, `display_name`, `sort_order` | Danh mục ngôn ngữ nội dung; có mã ngôn ngữ không đồng nghĩa đã có đề published. Phase 12 dùng cho picker. |
| `game_categories` + `game_category_translations` | Gốc: `id`, `game_type`, `sort_order`, `is_active`; bản dịch: `category_id`, `locale`, `name`, `description`, `status` | Ghép theo `category_id = id`; chỉ nhận bản dịch published đúng content locale và category active. `slug` unique theo `(game_type, slug)`, không phải theo locale; chọn/lưu bằng ID. |
| `word_prompts` + `word_prompt_translations` | Gốc: `id`, `category_id`, `difficulty`, `is_family_friendly`, `image_path`; bản dịch: `prompt_id`, `locale`, `text`, `status` | Một bản dịch cho mỗi `(prompt_id, locale)`; ảnh thuộc đề gốc, dùng chung giữa các locale. |
| `question_prompts` + `question_prompt_translations` | Gốc: `id`, `category_id`, `difficulty`, `is_family_friendly`; bản dịch: `prompt_id`, `locale`, `civilian_question`, `imposter_question`, `status` | Hai câu hỏi phải lấy từ cùng một hàng bản dịch; không ghép hai locale hoặc tự tạo câu còn thiếu. |

- Dùng một repository nội dung cho cả picker, số lượng content và random; model sau ghép phải giữ ID gốc và `contentLocale`. Giao diện không tự lọc lại bằng một bộ luật khác.
- Content hợp lệ phải đúng loại game, có **bản dịch prompt và bản dịch category cùng locale đều `status = published`**, category `is_active = true`; Gia đình thêm `is_family_friendly = true`. Cổ điển lấy cả content phù hợp và không phù hợp gia đình. Không còn `locale`/`status` trên bảng prompt gốc hay các cột hint từ schema lịch sử.
- RLS cho phép đọc hàng gốc nếu có ít nhất một locale công khai; đọc được hàng gốc không chứng minh locale đang chọn có nội dung. Query translation phải lọc locale/status rõ ràng, ghép đủ cha/con; nested select phải loại hàng thiếu bản dịch, không biến left join thành content hợp lệ.
- Không chọn category nghĩa là tất cả content hợp lệ; chọn nhiều category là hợp của chúng. Mỗi prompt có cơ hội được chọn như nhau trong tập hợp đó; không random category trước khiến category ít đề được ưu tiên.
- Picker chỉ hiện category có content hợp lệ và hiển thị số lượng từ cùng tập dữ liệu dùng để bắt đầu ván. Lấy đủ các trang của dữ liệu cần dùng theo thứ tự ổn định ngay từ phase 2; không tính count/random trên trang đầu hoặc đếm mọi bản dịch thành nhiều đề.
- Đổi loại/mode/content locale hoặc refresh phải loại lựa chọn category không còn hợp lệ và thông báo; nếu không còn category nào thì về `Tất cả danh mục`. Không có content hợp lệ thì chặn bắt đầu, chỉ rõ cách sửa. Giữ ID nếu category vẫn có bản dịch hợp lệ, cập nhật tên hiển thị theo locale mới.
- Content lấy qua API Supabase ngay từ phase 2; không seed database, không đóng gói content/ảnh vào bản build. Cache tách theo backend đích, phiên bản định dạng và content locale; chỉ thay snapshot nguyên tử sau khi tải/validate đủ, kể cả kết quả hợp lệ nhưng rỗng. Lỗi tải dùng cache tốt gần nhất **cùng backend/locale**, chưa có thì báo lỗi và cho thử lại. Fixture chứa draft/archived chỉ nằm trong test.
- Phase 7 hoàn thiện refresh từ setup, ảnh Storage và phục hồi lỗi đồng bộ; phase 12 mở chọn ngôn ngữ nội dung. Chưa cần manifest, delta sync, RPC random, Realtime hoặc một hệ thống content release mới.

### Ngôn ngữ giao diện và nội dung

- `uiLocale` điều khiển ARB/MaterialApp qua `AppStore.locale`; `contentLocale` điều khiển query, cache, tên danh mục và đề. Phase 2–11 dùng `contentLocale = vi`, kể cả khi phase 11 cho đổi UI sang EN.
- Phase 12 cho chọn content locale từ `content_languages`, theo `sort_order`, rồi `code`; không biến mã nội dung mới thành ngôn ngữ UI khi chưa có ARB tương ứng. Danh sách này không có cờ active/status hoặc bảo đảm đủ bản dịch.
- Không tự dịch, sao chép hay fallback nội dung VI↔EN; ngôn ngữ có trong danh sách nhưng chưa có đề hợp lệ là trạng thái rỗng. Offline chỉ dùng cache của locale được chọn, hiển thị rõ ngôn ngữ và tình trạng dữ liệu cũ.
- Lưu độc lập hai lựa chọn. Đổi content locale chỉ ở ngoài ván; giữ nguyên snapshot của session đang chơi. Nội dung tùy chỉnh có locale lúc tạo, không tự đổi ngôn ngữ theo nhãn UI.

### Thiết lập và session

- Thiết lập chứa người chơi có ID ổn định, game type, mode, category IDs, `contentLocale` (ban đầu `vi`) và các tùy chọn. Chỉ thêm trường khi phase đó bắt đầu dùng; UI locale không phải luật chơi và không được preset ghi đè.
- Session chụp một bản thiết lập, locale, tên danh mục và prompt đã dịch tại thời điểm bắt đầu, gồm vai, người bắt đầu, tiến độ đã xem/trả lời và stage hiện tại. Không random hay đổi bản dịch khi rebuild, quay lại, refresh hoặc resume app.
- `Chơi lại` tạo session mới và random lại từ tập hợp lệ, giữ thiết lập/người chơi. Có thể trùng prompt khi tập nhỏ; không thêm lịch sử chống lặp ở bản đầu.
- Session sống xuyên các màn của ván, không bị dispose theo màn reveal. Khi kết thúc/rời ván có xác nhận thì hủy session; quay lại không mở được bí mật đã xác nhận xong.
- Tên người chơi, vai, câu trả lời và kết quả bầu chọn chỉ nằm trên thiết bị, không gửi vào Supabase hoặc log. Thiết lập và danh sách đã lưu tồn tại qua lần mở app; ván đang chơi không bắt buộc khôi phục sau khi hệ điều hành đóng tiến trình.
- Khi app ra nền hoặc chuyển người chơi, che nội dung bí mật trước khi hiển thị lại. Không hứa chặn screenshot ở cấp hệ điều hành trong phạm vi này.
- Settings/locale và nội dung cache có dữ liệu lưu riêng; lỗi đọc không được âm thầm ghi đè dữ liệu người dùng. Lưu thất bại phải giữ form và có đường thử lại.

### Cấu trúc code dự kiến

- Giữ `app/lib/features/<feature>/` với screen/store theo code hiện có; nhóm nhiều màn khi cùng một luồng và cùng session.
- DI và các dịch vụ dùng chung vào `base/dependency/`; đăng ký store theo hạ tầng `base/store/` hiện có. Session dùng chung có vòng đời riêng, không đăng ký lại ở từng route.
- Chỉ tạo `app/lib/data/` cho content/local storage và `app/lib/models/` cho model thực sự dùng chung khi phase tương ứng cần. Không tạo sẵn mọi file của các phase sau.
- Tái sử dụng constants, Signals, Riverpod và l10n hiện có. Khi cần plugin đọc/lưu file, lấy ảnh hoặc mở liên kết, chọn plugin tối thiểu lúc triển khai và commit lockfile; không thêm trước toàn bộ dependency.

## 5. Tổng quan phase và dependency

| Phase / PR | Kết quả có thể demo sau merge | Phụ thuộc |
| --- | --- | --- |
| 1. Khung ứng dụng và hướng dẫn | Mở app tiếng Việt, xem Cách chơi, điều hướng/quay lại đúng; đã có trong source | — |
| 2. Thiết lập word và danh mục từ backend | Chọn số người, mode, nhiều danh mục từ bản dịch `vi` qua API/cache; thấy đúng số đề | 1; backend đích đã có schema translations |
| 3. Một ván word hoàn chỉnh | Thiết lập → chuyển máy xem từ/vai → thảo luận → công bố → chơi lại | 2 |
| 4. Người chơi và luật nâng cao | Đổi tên/thứ tự người chơi; fixed/random imposters, không đi trước, biết nhau | 3 |
| 5. Một ván question hoàn chỉnh | Nhập câu trả lời riêng → câu hỏi chung → thảo luận → công bố → chơi lại | 4 |
| 6. Danh sách người chơi đã lưu | Lưu/nạp/đổi tên/xóa bộ người chơi và thiết lập liên quan | 4 |
| 7. Hoàn thiện đồng bộ content và ảnh | Refresh từ setup, ảnh word từ Storage; phục hồi lỗi đồng bộ và cache | 5 |
| 8. Tùy chỉnh word bằng văn bản | Tạo danh mục/từ, nhập nhiều, dùng ngay trong ván word | 4 |
| 9. Tùy chỉnh question bằng văn bản | Tạo cặp câu hỏi tùy chỉnh và chơi trọn ván question | 5, 8 |
| 10. Ảnh cho nội dung tùy chỉnh | Chọn/chụp/thay/xóa ảnh, hiện đúng cho người có quyền xem | 9 |
| 11. Cài đặt và hỗ trợ | Đổi/lưu ngôn ngữ giao diện VI/EN, xem phiên bản/ID, đánh giá và phản hồi | 5 |
| 12. Tích hợp ngôn ngữ nội dung | Chọn ngôn ngữ từ DB, chơi cả hai game bằng bản dịch đúng locale, cache/offline tách ngôn ngữ | 6, 7, 10, 11 |
| 13. Hoàn thiện bản phát hành | Hai game và mọi tính năng đã chọn chạy trên Android/iOS release | 1–12 |

Thứ tự mặc định là 1 → 13. Giữ số phase 1–11; phase 12 mới dành cho ngôn ngữ nội dung, phase phát hành cũ chuyển thành 13. Sau phase 4, phase 6 và 8 có thể làm trước phase 5 nếu ưu tiên sản phẩm thay đổi. Phase 7 không phải điều kiện để chơi: phase 2 đã đọc bản dịch `vi` đầy đủ từ backend và cache. Phase 12 mở rộng repository có sẵn sang nhiều locale, không duy trì hai bộ game logic.

Đối chiếu phạm vi layout:

| Mục trong layout | Phase chịu trách nhiệm |
| --- | --- |
| 1–2: bắt đầu, cách chơi | 1; cập nhật hướng dẫn theo luật mới ở 4–5 |
| 3–4: setup, picker và bottom sheet imposter | 2, 4; bật question ở 5, hoàn thiện sync/ảnh ở 7, đổi content locale ở 12 |
| 5: tạo tùy chỉnh | 8–10 |
| 6–9: luồng word và kết quả | 3–4 |
| 10–14: luồng question và kết quả | 5 |
| 15: người chơi và danh sách đã lưu | 4, 6 |
| 16: cài đặt | 11; thêm ngôn ngữ nội dung ở 12 sau khi chốt tách hai lựa chọn |
| 17–19: bố cục chung, điều hướng, ảnh/trạng thái còn thiếu | Áp dụng trong từng PR; đối chiếu tổng thể ở 13 |

## 6. Chi tiết từng phase

### Phase 1 — Khung ứng dụng và hướng dẫn

**PR đề xuất:** `feat(app): replace demo entry with game onboarding`

**Trạng thái nghiệm thu 24/10/2026:** landing, Cách chơi, theme, VI/EN, routing và test onboarding đã có từ commit `c77108b`; README/docs đã đổi sang Signals/Store. Giữ code hiện có, mở rộng test và nghiệm thu hành vi bên dưới; không dựng lại tính năng.

- Phạm vi: màn 1, 2 và quy tắc chung ở mục 17; theme cơ bản, SafeArea, nội dung cuộn và nút chính cuối màn.
- Chuyển entry sang màn bắt đầu; thêm màn Cách chơi và back về đúng màn gọi. Bỏ bottom navigation khỏi luồng sản phẩm, giữ RouterService; xóa code demo chỉ sau khi hết caller.
- Thêm ARB tiếng Việt, cập nhật chuỗi tiếng Anh hiện có và hướng dẫn Signals/Store trong `app/README.md`, `app/docs/`. Không sửa tay file localization generated.
- Điểm chạm: `main.dart`, `features/landing`, `features/how_to_play`, router/utils, ARB, constants/theme, test onboarding hiện có.
- **Nghiệm thu:** cold start mở đúng trang; Cách chơi cuộn được; back hệ thống và back UI hoạt động. `Bắt đầu` có trạng thái chưa khả dụng rõ trong PR nền, chưa mở một trang setup giả.
- **Kiểm tra:** giữ widget test entry → hướng dẫn → back, đổi VI/EN và màn nhỏ/text scale lớn trong `app/test/features/onboarding_test.dart`.

**Kết quả nghiệm thu:**

- `flutter analyze --no-pub`: không có lỗi; `flutter test --no-pub`: 27/27 test pass, gồm 5 test onboarding. Test xác nhận thông báo `Sắp ra mắt`/`Coming soon` và nút Bắt đầu disabled; luồng hướng dẫn tiếng Anh cuộn tới mẹo rồi back; màn 320×568, text scale 2 cuộn tới tiêu đề mẹo trong vùng hiển thị mà không overflow. Back UI và back hệ thống được kiểm tra bằng widget test.
- Smoke debug trên iPhone 17 Pro Simulator, iOS 26.5, `APP_ENV=local`: dùng script tạm ngoài repository gọi `main()` thật, kiểm tra widget tree và gọi callback điều hướng. Khởi động với config local → landing VI → Bắt đầu disabled → Cách chơi → cuộn tới mẹo → `Navigator.maybePop()` về landing đều pass, không có lỗi Flutter framework. Script không thêm dependency hay thay đổi code sản phẩm; đây là kiểm tra tự động, không phải thao tác tay trên thiết bị thật.
- Theo phạm vi nghiệm thu đã chốt: không chụp hoặc kiểm tra ảnh, không yêu cầu ảnh/video demo cho phase 1. Chưa kiểm tra Android, thiết bị thật, release hoặc gọi API; không đánh giá độ khớp thiết kế qua hình ảnh. Minh họa hiện tại được giữ nguyên, theme tối dùng palette sáng và locale chỉ lưu trong bộ nhớ.

### Phase 2 — Thiết lập word và danh mục từ backend

**Trạng thái triển khai 24/10/2026:** đã có setup Word, chọn 3–100 người,
Classic/Family, picker hai cột với bản chọn tạm, load content nền dùng chung,
snapshot và thiết lập JSON riêng trong Application Support theo backend/locale.
Lỗi refresh không thay cache; lỗi đọc thiết lập chặn ghi cho tới retry/reset có
xác nhận. Nút bắt đầu ván vẫn chưa khả dụng cho tới phase 3.

**Bằng chứng kiểm tra phase 2:**

- `flutter gen-l10n` và `flutter analyze`: thành công, không có issue.
- `flutter test`: **63 tests passed**, gồm phân trang, eligibility, translation
  validation, duplicate ID, empty replacement, cache/settings failures, serialized
  writes, picker confirm/back, retry và màn 320×568 với text scale 2.
- `flutter build ios --simulator --debug --dart-define=APP_ENV=local`: thành công.
- `flutter test integration_test/setup_smoke_test.dart -d <iPhone-17-Pro-simulator-id>
  --dart-define=APP_ENV=local`: **1 test passed** trên iOS 26.5 Simulator. Test
  đọc Local Supabase bằng publishable key, kiểm tra không có auth session, mở setup,
  chọn danh mục/số người rồi khởi tạo lại repository/store từ file thật và giả lập
  nguồn mạng offline. Không phải kiểm thử kill/relaunch tiến trình hoặc máy bay thật.
- Read-only `supabase db query --local`: `Đồ ăn Việt Nam` có **1 Classic / 0 Family**;
  `Nhân vật hư cấu` có **0 / 0** và bị ẩn. UI integration khớp **1 / 0**; Family
  có dữ liệu và nhiều trang dùng fixture, không seed/sửa database.
- `flutter build apk --debug --dart-define=APP_ENV=local`: thành công,
  tạo `app/build/app/outputs/flutter-apk/app-debug.apk`. Đã cập nhật Kotlin 2.3.0,
  AGP 8.13.2 và Gradle 8.13 để tương thích plugin native mới; lần build đầu với
  Kotlin 1.8.10 cũ lỗi tại `shared_preferences_android`.
- `flutter run` thông thường trên iOS Simulator: startup và tải nền thành công,
  mở setup với 4 người mặc định và 1 từ phù hợp.
- Chưa nghiệm thu Dev/Production, thiết bị thật, Android runtime hoặc gameplay.
  Không tải ảnh, sửa tên người chơi, thêm luật nâng cao hay manual refresh trong phase này.

**PR đề xuất:** `feat(app): add word setup with remote content`

- Phạm vi: phần word của màn 3–4; chọn 3–100 người với tên mặc định, 1 kẻ mạo danh cố định, Cổ điển/Gia đình, tất cả hoặc nhiều danh mục.
- Tái sử dụng `AppConfig.current` và `APP_ENV`; khởi tạo client bằng URL/publishable key đã validate, dùng quyền đọc anon hiện có, không đăng nhập admin hoặc nhúng service-role key. Xác minh backend đích đã áp dụng schema translations trước khi tích hợp.
- Thêm model/repository theo bảng ở mục 4: đọc category active + bản dịch category published `vi`, đề gốc + bản dịch word/question published `vi`; chỉ select trường game cần. Lọc bản dịch tại API, validate liên kết/cùng locale, lấy đủ các trang theo thứ tự ổn định rồi thay cache local nguyên tử. Không gọi RPC quản trị; không query các cột đã bị drop. Dữ liệu có cặp question để phase 5 tái sử dụng, nhưng chưa hiện lựa chọn question.
- Tải content nền ngay khi mở app (từ landing/Cách chơi), không chờ vào setup, để cache có sẵn trước khi nhóm chơi ở nơi mạng yếu. Một lần tải tại một thời điểm; setup dùng lại kết quả đang tải thay vì gọi lặp.
- Mất mạng/lỗi API dùng cache gần nhất cùng backend/locale; chưa có cache thì hiện lỗi và nút thử lại, không có content dự phòng trong build. Lỗi giữa các trang không ghi cache một phần; response thành công nhưng rỗng thay snapshot cũ. Setup có trạng thái loading/lỗi/rỗng và thể hiện nội dung tiếng Việt cho tới phase 12.
- Bật `Bắt đầu` ở landing để vào setup; picker dùng bản chọn tạm, `Xác nhận` mới áp dụng, back hủy chỉnh sửa. Lưu thiết lập cơ bản local và xử lý lỗi đọc/ghi.
- Điểm chạm: feature setup/categories, data/content, DI/config, local cache/settings, router, ARB, Android internet permission, `pubspec.yaml`/lockfile khi cần.
- **Nghiệm thu:** số lượng category và đề `vi` khớp bộ lọc trên backend đã có schema mới, kể cả dữ liệu vượt một trang; đổi mode không giữ ID không hợp lệ; nhớ thiết lập sau mở lại; mất mạng sau lần tải đầu vẫn cấu hình được. Nút bắt đầu ván ghi rõ chưa khả dụng cho tới phase 3; mọi thao tác cấu hình khác dùng được.
- **Kiểm tra:** unit test loại/mode/status/category active, nhiều category, nhiều trang và tập rỗng. Fixture có cùng ID gốc với VI published/EN draft và ngược lại; category VI ẩn nhưng EN public; thiếu translation; không đếm trùng ID hoặc lọt EN vào tập VI. Payload lỗi/không tương thích và lỗi trang giữa không ghi đè cache; simulation HTTP cho lỗi mạng/không có cache; read-only check backend local/dev xác minh anon đọc cả bảng gốc lẫn translation đúng quyền. Widget test xác nhận/hủy picker, thử lại và khôi phục thiết lập.

### Phase 3 — Ván word hoàn chỉnh đầu tiên

**PR đề xuất:** `feat(app): ship playable word game loop`

- Phạm vi: màn 6–9; dùng setup ở phase 2 và một kẻ mạo danh. Nâng nút bắt đầu từ chưa khả dụng thành tạo session thực.
- Chọn ngẫu nhiên prompt và vai một lần; danh sách tên mặc định → thẻ che → xem từ hoặc vai → `Hiểu rồi!`. Chỉ người thường được xem từ và ảnh word nếu có; tùy chọn hiển thị danh mục không được rò qua heading khi đang che.
- Khi tất cả hoàn tất mới sang hướng dẫn thảo luận; hiện người bắt đầu. `Thông báo kết quả` mở sheet chọn đúng một người nhóm đã bầu, xác nhận rồi mới công bố vai thật/từ và bên thắng. Không thu từng phiếu; sheet là phần bổ sung cần chốt vào layout theo mục 3.
- `Chơi lại` giữ setup và thay session. Back trong ván chỉ trở về danh sách khi an toàn hoặc hỏi kết thúc ván; không pop về một reveal đã hoàn tất. App ra nền che bí mật khi trở lại.
- Điểm chạm: feature word_game, session dùng chung, content repository, routes, ARB; không thêm bảng lưu ván backend.
- **Nghiệm thu:** 3 người trở lên chơi được từ đầu đến cuối, kể cả ở chế độ máy bay sau khi đã tải content thành công ít nhất một lần; không mở lại thẻ đã xong; rebuild không đổi vai/từ; chạm nhanh không xác nhận hai người hoặc tạo hai ván.
- **Kiểm tra:** unit test gán đúng một vai, chặn chuyển stage sớm và xác định thắng khi bầu đúng/sai bằng random có seed/fake; widget/integration test trọn ván, hủy sheet bầu chọn, back, pause/resume, giữ setup khi chơi lại. Không kiểm tra phân phối random bằng test xác suất dễ chập chờn.

### Phase 4 — Tên người chơi và các luật cấu hình

**PR đề xuất:** `feat(app): add roster editing and imposter options`

- Phạm vi: màn 15 phần danh sách hiện tại và phần còn lại của màn 3/bottom sheet, chưa gồm danh sách đã lưu.
- Đổi tên, thêm/xóa, sắp xếp người chơi; 3–100 người, trim tên, tên trống không được lưu. Dùng ID riêng để tên trùng không làm gán nhầm vai/câu trả lời; thêm người sinh tên mặc định theo danh sách hiện tại.
- Fixed/random số kẻ mạo danh, validation theo N, cập nhật lại cấu hình khi giảm người chơi; tùy chọn không đi trước, hiển thị danh mục, biết nhau. `Biết nhau` chỉ hiện tên đồng vai sau khi mở thẻ và không lộ từ/ảnh.
- Chốt xử lý công tắc hint và luật nhiều kẻ mạo danh trước khi bật UI; cập nhật Cách chơi cho đúng luật đã duyệt. Mở rộng sheet ghi nhận người bị bầu và kết quả theo số imposter; không bỏ tính thắng/thua của phase 3.
- Điểm chạm: setup, player_names, session assignment, local settings, word reveal, ARB và test phase 3.
- **Nghiệm thu:** đổi cấu hình rồi chơi trọn ván; người bắt đầu được hiển thị đúng và không là imposter khi bật ràng buộc; cấu hình không thể tạo ván không hợp lệ.
- **Kiểm tra:** unit test biên 3/100 người, fixed/random, giảm N, tên trùng, thứ tự, không đi trước và tập người bị bầu đúng/sai/thiếu theo luật đã chốt; widget test thêm/xóa/sửa, hiển thị đồng vai đúng thời điểm.

### Phase 5 — Ván question hoàn chỉnh

**PR đề xuất:** `feat(app): add private question game loop`

- Phạm vi: màn 10–14; bật chọn question ở setup và picker đúng loại/mode. Tái sử dụng roster, session, random và lớp nội dung hiện có.
- Chọn một cặp câu hỏi từ cùng hàng `question_prompt_translations` của content locale đang dùng, đã ghép đề gốc qua repository; người thường nhận `civilian_question`, imposter nhận `imposter_question`. Thẻ bí mật che trước khi mở, form trả lời chỉ thuộc người hiện tại, submit trim và chặn rỗng/gửi lặp.
- Gửi xong khóa người chơi đó, tăng counter, không cho sửa hoặc xem lại; chỉ khi đủ câu trả lời mới hiện câu hỏi chung.
- Thảo luận công khai tên/câu trả lời nhưng giữ kín câu hỏi khác; công bố mới đánh dấu mọi imposter và hiện câu hỏi riêng. Chơi lại tạo câu trả lời và vai mới.
- Điểm chạm: feature question_game, setup/category mapping, session stages, ARB, local content fixtures; không gửi câu trả lời lên backend.
- **Nghiệm thu:** cả Cổ điển/Gia đình chơi được từ setup tới replay; chưa gửi đủ không thể vào thảo luận; đổi loại game không mang theo câu trả lời/session cũ.
- **Kiểm tra:** unit test assignment/stage, answer validation; widget/integration test chuyển máy nhiều người, pause che câu hỏi, double submit, riêng tư trước công bố và reset khi replay.

### Phase 6 — Danh sách người chơi đã lưu

**PR đề xuất:** `feat(app): persist and manage player presets`

- Phạm vi: phần Danh sách đã lưu, Lưu thành danh sách mới, Quản lý, Chi tiết và Đổi tên/Xóa của màn 15.
- Lưu ID/tên danh sách, roster và các tùy chọn liên quan theo layout; bản đầu không gắn category tùy chỉnh tạm thời vào preset. Chốt trường hiển thị số imposter trước khi hoàn thành chi tiết.
- Chọn preset nạp dữ liệu và validate lại; thay đổi lúc đang dùng tự lưu đúng như ghi chú layout. `Trò chơi chưa lưu` không bị ghi đè sang preset đang có.
- Hủy modal không làm đổi dữ liệu; tên trống/trùng báo rõ, xóa có xác nhận; xóa preset đang dùng giữ roster hiện tại thành trò chơi chưa lưu. Lưu lỗi giữ nội dung và báo chưa lưu thành công.
- Điểm chạm: player_names, feature player_presets, local storage, setup/store, ARB; không thêm đồng bộ tài khoản.
- **Nghiệm thu:** lưu/nạp/đổi tên/xóa hoạt động qua lần mở lại app; chi tiết khớp setup và không mất các danh sách khác.
- **Kiểm tra:** unit test serialize/validate, auto-save và lỗi lưu; widget test các sheet/modal, hủy/xóa danh sách hiện tại, khôi phục dữ liệu hỏng mà không ghi đè bản cũ.

### Phase 7 — Hoàn thiện đồng bộ content và ảnh

**PR đề xuất:** `feat(app): harden content sync and word images`

- Phạm vi: hoàn thiện repository API/cache có từ phase 2; không thay UI hoặc luật của hai game. Chỉ lấy trường cần cho game, không lấy thông tin người tạo/quản trị.
- Giữ hợp đồng gốc + translation published cùng content locale ở phase 2; kiểm tra hồi quy phân trang đầy đủ trước khi tính số lượng/random. Đồng bộ lại không được khôi phục query theo schema cũ hoặc lấy thêm locale ngoài yêu cầu.
- Lỗi mạng, timeout, lỗi trang giữa hoặc payload lỗi không được ghi đè cache tốt; fallback cache gần nhất, chưa có cache thì báo lỗi và thử lại. Không có content đóng gói trong build. Một kết quả hợp lệ nhưng rỗng được xử lý là rỗng, không đánh đồng với lỗi mạng.
- Cập nhật khi mở app/refresh từ setup; đang chơi giữ nguyên session, locale, tên category và prompt. Bản dịch bị archive/xóa/category bị tắt hoặc bản dịch category không còn published biến mất khỏi cache mới của locale đó cho các ván sau. Locale khác còn published không làm bản dịch đã ẩn tiếp tục hợp lệ. Nội dung offline có thể cũ cho tới lần đồng bộ thành công; không hứa thu hồi ngay trên máy mất mạng.
- Ảnh word: bucket private `word-prompt-images`; quyền public dựa trên đề có ít nhất một bản dịch published cùng category public ở locale đó, không chỉ `status` trên đề gốc. Ảnh dùng chung mọi locale; đọc được ảnh không chứng minh nội dung của locale đang chọn đủ điều kiện chơi.
- Không dùng signed URL làm cache key. Sau khi đồng bộ content hợp lệ, app xin signed URL và tải ảnh về vùng lưu của app, định danh theo backend + `image_path` (path đổi khi thay ảnh). Ảnh đã có file thì không tải lại; chỉ dọn file không còn được bất kỳ cache locale hoặc session hiện tại tham chiếu. Signed URL hết hạn thì xin lại khi online; không coi archive là thu hồi được ngay URL đã cấp hoặc bytes offline.
- Tải ảnh chạy nền, lỗi từng ảnh không làm hỏng đồng bộ content. Thiếu file khi chơi thì hiện placeholder; không bắt tải đủ ảnh mới cho bắt đầu ván.
- Điểm chạm: data/content, local cache, setup refresh/error/retry, hiển thị ảnh word. Không tự sửa RLS nếu quyền đọc hiện có đã đủ.
- **Nghiệm thu:** hai game dùng content thật `vi`; không lọt bản dịch draft/archived/sai locale/mode/category inactive; mất mạng vẫn chơi bằng cache; không gán vai hoặc đổi prompt lại khi dữ liệu cập nhật.
- **Kiểm tra:** test repository với nhiều trang, lỗi một phần, cache hỏng/rỗng, ẩn bản dịch/đề/category và ảnh lỗi; ảnh còn tham chiếu bởi session không bị dọn. Dùng simulation cho HTTP khi kiểm tra lỗi; chạy thêm read-only check trên backend local/dev xác minh quyền anonymous và bộ lọc, kể cả ảnh còn public nhờ locale khác. Không dùng production để tạo/xóa fixture.

### Phase 8 — Tùy chỉnh word bằng văn bản

**PR đề xuất:** `feat(app): create local custom word categories`

- Phạm vi: màn 5 phần văn bản cho word; bật thẻ `Tạo tùy chỉnh` khi đang chọn word. Ghi `contentLocale` lúc tạo (hiện là `vi`) cho category/prompt local; không coi nội dung tự nhập là bản dịch dùng cho mọi ngôn ngữ.
- Tên category, thêm/xóa từ, nhập nhiều dòng; trim, bỏ dòng trống, chống trùng theo giá trị trim/không phân biệt hoa thường, giữ nguyên nội dung hiển thị. Chặn tên trùng thay vì ghi đè và chặn lưu nếu không còn từ hợp lệ.
- Form có draft, rời khi thay đổi phải xác nhận; lưu thành công mới đưa vào picker và chọn category mới. Luật chọn một/nhiều category và random áp dụng cả nguồn remote/cache lẫn nguồn tùy chỉnh mà không trộn trùng ID.
- Áp dụng vòng đời và kiểm tra Gia đình sau khi chốt mục 3; không đưa nội dung tự nhập lên backend. Chưa hiện thao tác ảnh.
- Điểm chạm: feature custom_content, picker, repository/local session content, ARB, word reveal/replay.
- **Nghiệm thu:** tạo category và chơi ngay một ván word, replay giữ đúng nội dung theo vòng đời đã chốt; hủy form không thêm category nửa chừng.
- **Kiểm tra:** unit test nhập nhiều, trùng/trim/tên, category IDs và lọc Gia đình; widget test unsaved guard, lỗi lưu, picker chọn sau lưu, category chỉ có một từ.

### Phase 9 — Tùy chỉnh question bằng văn bản

**PR đề xuất:** `feat(app): create local custom question pairs`

- Phạm vi: mở rộng form phase 8 cho question, giữ chung tên category/validation/draft; chưa có ảnh.
- Nhập hai câu hỏi bắt buộc khác nhau sau trim/so sánh không phân biệt hoa thường; không dùng một câu hỏi cho cả hai vai hoặc tự sinh câu còn lại.
- Sau khi duyệt UX ở mục 3, nhập nhiều bằng hai ô nhiều dòng ghép theo chỉ số; số dòng không bằng nhau hoặc có cặp không hợp lệ phải báo dòng lỗi và không lưu một phần âm thầm.
- Giữ cùng vòng đời/category selection/Gia đình như phase 8; kết nối vào ván question và màn kết quả đang có.
- Điểm chạm: custom_content, model cặp câu hỏi, picker, question assignment/reveal, ARB. Không thêm cột backend cho dữ liệu local.
- **Nghiệm thu:** category question tùy chỉnh không xuất hiện trong word; cả hai nhóm nhận đúng câu hỏi; kết quả hiện đúng câu hỏi khác sau công bố.
- **Kiểm tra:** unit test cặp rỗng/trùng, batch thiếu dòng/dòng trống/trùng cặp; widget test form → lưu → chơi hết ván → replay, hồi quy word tùy chỉnh.

### Phase 10 — Ảnh cho nội dung tùy chỉnh

**PR đề xuất:** `feat(app): attach local images to custom prompts`

- Phạm vi: thumbnail từng item, thêm/thay/xóa ảnh, chọn thư viện và chụp mới cho cả hai loại game; nhập nhiều chỉ tạo văn bản.
- Sao chép ảnh đã chọn vào vùng lưu do app quản lý, không chỉ giữ URI/file tạm; hủy picker không đổi ảnh. Xử lý quyền bị từ chối, camera không khả dụng, file lỗi/quá lớn và preview lỗi.
- Gắn ảnh sau khi lưu thành công; thay/xóa/hủy draft chỉ dọn file thuộc app khi không còn tham chiếu. Lỗi ghi giữ bản cũ. Dọn file hết vòng đời category tùy chỉnh theo quyết định phase 8.
- Word: ảnh chỉ đi cùng từ cho người thường. Question: ảnh chỉ hiện cho người đang trả lời và chỉ công khai sau mốc đã duyệt; mặc định không thêm ảnh vào danh sách thảo luận. Không để ảnh lộ bí mật qua màn chuyển người, heading hoặc semantics khi thẻ còn che.
- Điểm chạm: custom_content, local file handling, word/question reveal, native permissions iOS/Android, plugin và lockfile. Không upload ảnh vào Supabase, không mở rộng schema question remote.
- **Nghiệm thu:** chọn/chụp/thay/xóa ảnh rồi chơi được; từ/câu hỏi không có ảnh vẫn hoạt động; ảnh còn đúng trong suốt vòng đời nội dung.
- **Kiểm tra:** test file save/replace thất bại không mất ảnh cũ; kiểm tra quyền, thư viện và camera trên thiết bị thật của hai nền tảng. Widget test placeholder và che ảnh; simulator không đủ để xác nhận camera.

### Phase 11 — Cài đặt, ngôn ngữ giao diện và hỗ trợ

**PR đề xuất:** `feat(app): add settings and support actions`

- Phạm vi: màn 16 và màn chọn ngôn ngữ; mở từ setup, tái sử dụng Cách chơi từ cả landing/settings.
- Cho chọn VI/EN từ `AppLocalizations.supportedLocales`, cập nhật `AppStore.locale`, MaterialApp và strings ngay, lưu/khôi phục lựa chọn local; không sửa generated l10n thủ công. Đây là `Ngôn ngữ giao diện`; nội dung game vẫn `vi` cho tới phase 12 và được ghi rõ ở setup. Không dùng locale UI làm filter API/cache.
- Hiện phiên bản/build thực tế; tạo ID cài đặt ẩn danh local một lần, hiển thị rút gọn và copy toàn bộ. Không tạo tài khoản hay thu thập định danh thiết bị.
- Dùng store URL/app ID và kênh phản hồi đã được cung cấp; mở ứng dụng ngoài có xử lý lỗi/không có app nhận. Chưa có cấu hình thì ẩn hành động hoặc giải thích rõ, không gắn URL giả.
- Điểm chạm: settings, i18n, `main.dart`, local settings, app metadata, nền tảng/link config, ARB. Không thay đổi cấu hình của session đang chơi.
- **Nghiệm thu:** đổi ngôn ngữ giao diện tồn tại qua mở lại, Cách chơi back đúng màn gọi, ID ổn định và clipboard đủ giá trị; link mở đúng đích trên từng nền tảng. UI tiếng Anh vẫn chơi đề tiếng Việt với nhãn nội dung rõ ràng.
- **Kiểm tra:** widget test locale/restart/copy với service giả; kiểm tra thiết bị thật việc mở store/kênh phản hồi; đổi UI không làm query/cache/session đổi content locale.

### Phase 12 — Tích hợp ngôn ngữ nội dung với DB đa ngôn ngữ

**PR đề xuất:** `feat(app): integrate content languages and localized game content`

- Phạm vi: bổ sung `Ngôn ngữ nội dung` trong settings bên cạnh `Ngôn ngữ giao diện` sau khi chốt mục 3; hiển thị locale nội dung tại setup/picker. Dùng repository, cache, hai game và nội dung tùy chỉnh hiện có; không mở thêm API quản trị hoặc đổi schema DB.
- Đọc `content_languages(code, display_name, sort_order)` qua quyền anon, sắp theo `sort_order`, rồi `code`; cache danh sách cùng backend để picker dùng offline. Có mã ngôn ngữ không bảo đảm đã có content; không hardcode danh sách nội dung bằng `supportedLocales` của Flutter, không giả định chỉ có VI/EN hoặc có cờ active trong bảng.
- Lưu `contentLocale` độc lập với UI locale. Thiết lập/preset cũ thiếu trường này được đọc là `vi`; preset mới lưu content locale, validate lại khi nạp và không đổi UI locale. Mã locale không còn trong danh sách sau lần tải thành công phải hiện trạng thái không khả dụng và yêu cầu chọn lại; không âm thầm đổi ngôn ngữ hoặc xóa thiết lập cũ.
- Đổi content locale ngoài ván: chuyển repository sang snapshot của locale mới, tải/validate đủ trước khi cho bắt đầu; có cache đúng locale thì dùng khi offline. Lỗi tải không hiển thị dữ liệu của locale cũ dưới nhãn mới; không có cache thì báo lỗi/thử lại. Ngôn ngữ hợp lệ nhưng chưa có đề published hiện trạng thái rỗng/chặn bắt đầu, cho đổi ngôn ngữ; không tự fallback sang VI/EN.
- Scope request và kết quả theo backend + content locale; nếu người dùng đổi nhanh VI→EN→VI, kết quả về trễ chỉ được cập nhật cache tương ứng, không ghi đè danh mục/count hiện đang xem. Picker đang mở phải hủy lựa chọn tạm khi đổi locale; validate lại category IDs và tên hiển thị bằng bộ lọc chung ở mục 4.
- Word reveal/kết quả dùng `word_prompt_translations.text` đã ghép; question lấy nguyên cặp cùng hàng translation. Session giữ locale, tên category và prompt đã chụp; refresh hoặc đổi UI không làm đổi nội dung ván. `Chơi lại` dùng locale của bộ thiết lập hiện tại và tạo session mới theo quy tắc chung.
- Nội dung tùy chỉnh chỉ hiện trong locale lúc tạo; đổi locale không xóa draft/category/ảnh đang còn vòng đời. Không nhân đôi hoặc tự dịch nội dung người chơi nhập. File ảnh remote dùng chung theo backend + `image_path`, chỉ dọn khi mọi cache locale và session đều hết tham chiếu; đổi locale không tải lại ảnh đã có.
- Điểm chạm: settings/language picker, `AppStore`/local settings, setup/category picker, data/content/cache keys, preset serialization, custom content, session/reveal/kết quả, ARB và fixtures. Không thêm ARB cho mọi mã ngôn ngữ nội dung hoặc thay cấu trúc state/DI.
- **Nghiệm thu:** đổi nội dung VI↔EN và chơi trọn cả hai game, hai mode; UI EN + content VI và ngược lại hoạt động đúng. Tên/count/random đều cùng locale, không đếm nhiều bản dịch thành nhiều đề; thiếu bản dịch/đề thì rỗng; khởi động lại nhớ lựa chọn; offline chỉ chơi bằng cache đúng locale. Backend kiểm thử phải có bản dịch published cho từng tổ hợp cần nghiệm thu; mã trong `content_languages` đơn thuần không đủ.
- **Kiểm tra:** unit test bản dịch VI published/EN draft và ngược lại, category translation thiếu/ẩn, hai câu hỏi cùng locale, nhiều trang, cache tách backend/locale, response về sai thứ tự, lỗi/rỗng và preset cũ. Widget/integration test đổi hai locale độc lập → chọn danh mục → chơi → replay → restart/offline, custom content không bị gắn lại locale, ảnh dùng chung không bị dọn nhầm. Read-only check trên backend local/dev xác minh anon không fallback khi bản dịch bị ẩn; dùng fixture trong test để thêm mã nội dung thứ ba mà không cần thêm ARB UI.

### Phase 13 — Hoàn thiện và kiểm tra bản phát hành

**PR đề xuất:** `chore(app): prepare mobile release and verify game flows`

- Đối chiếu toàn bộ màn/trạng thái đã chốt với layout; rà soát từ ngữ thống nhất, SafeArea, cuộn, bàn phím, focus, screen reader, text scale và nút cuối màn. Các phase trước vẫn phải có accessibility cơ bản, không dồn toàn bộ tới đây.
- Thay nhãn `untitled`/nhận diện demo bằng tên và assets được duyệt; cấu hình application/bundle ID, version/build và môi trường release. Nếu đổi package ID thì cập nhật Kotlin package/MainActivity, Gradle và iOS settings liên quan cùng PR.
- Build Android/iOS release, kiểm tra network permission/TLS với backend mục tiêu, plugin ảnh/link hoạt động trong release và không vô tình để cấu hình HTTP dev trong bản phát hành.
- Kiểm tra không có khóa đặc quyền trong source/bundle, không log vai/đáp án; build không chứa content và trỏ đúng backend release. Giữ dữ liệu local khi nâng version, đặc biệt preset và thiết lập.
- Điểm chạm: lỗi tích hợp thực tế, native config/assets, test/integration_test và hướng dẫn build/UAT. Không dùng PR cuối để chứa tính năng còn thiếu của phase trước.
- **Nghiệm thu:** UI VI/EN và lựa chọn ngôn ngữ nội dung theo DB; hai game, cả hai mode, preset, tùy chỉnh, ảnh, replay, offline/cập nhật content đều qua checklist trên Android/iOS. Kiểm tra backend release đã có schema translations và đủ bản dịch published; không còn route/nút demo trong luồng sản phẩm.
- **Kiểm tra:** `flutter analyze`, `flutter test`, integration smoke và cài release build trên thiết bị. Nếu thiếu signing/tài khoản, ghi rõ bước chưa xác minh; build unsigned không thay thế kiểm tra cài/phân phối. Upload store/phát hành là bước vận hành sau PR, không được coi là đã làm.

## 7. Điều kiện hoàn thành cho mỗi PR

1. Ghi rõ phase, dependency đã merge, chức năng mới nhìn thấy từ đâu và cách demo với dữ liệu nào.
2. Có test nhỏ cho luật mới; thao tác nhập/lưu có validation và giữ dữ liệu khi lỗi. Test regression tập trung vào phần đã đổi, không tạo lại mọi test ở mọi phase.
3. Chạy `flutter analyze` và `flutter test` trong `app/`; chạy codegen/l10n khi nguồn tương ứng thay đổi. PR đụng native/plugin phải có build/check đúng nền tảng.
4. Mỗi luồng đã mở cho người dùng có back/cancel/loading/empty/error/retry thích hợp; nút chưa làm không dẫn vào đường cụt.
5. Không lộ thông tin người chơi trước thời điểm cho phép; xác nhận khi thao tác làm mất form/danh sách hoặc kết thúc ván.
6. Có ảnh/video demo và kết quả kiểm tra thực tế trong PR; phân biệt unit/widget, simulation, backend local/dev và thiết bị thật.
7. Cập nhật tài liệu nếu chốt một điểm khác layout. Mỗi PR tự hoạt động sau merge; rollback code không yêu cầu xóa dữ liệu local của người dùng. PR đọc content phải giữ hợp đồng translation cùng locale, cache tách backend/locale và không thay snapshot session đang chơi.

## 8. Mốc bàn giao và phần không tự mở rộng

- **Sau phase 3:** bản thử nội bộ game word, nội dung từ backend Dev, một imposter.
- **Sau phase 5:** cả hai game chơi trọn ván, cấu hình và người chơi cơ bản đầy đủ.
- **Sau phase 7:** refresh content, ảnh word và cache offline ổn định; phân trang đã bắt buộc từ phase 2.
- **Sau phase 10:** hoàn tất nhóm tùy chỉnh văn bản/ảnh đã chốt.
- **Sau phase 11:** đổi/lưu ngôn ngữ giao diện VI/EN và dùng các hành động hỗ trợ.
- **Sau phase 12:** chọn ngôn ngữ nội dung theo DB, hai game dùng đúng bản dịch, cache/offline và dữ liệu tùy chỉnh giữ đúng locale.
- **Sau phase 13:** ứng viên phát hành, kèm bằng chứng kiểm tra và các giới hạn còn lại.

Không tự thêm Premium, thanh toán, quảng cáo, đăng nhập người chơi, chơi online, đồng bộ danh sách nhiều thiết bị, bảng xếp hạng, timer, AI sinh nội dung, thư viện tùy chỉnh vĩnh viễn hoặc hệ thống thu từng phiếu/loại người nhiều vòng. Vẫn ghi nhận lựa chọn chung của nhóm và tính bên thắng trong game word. Nếu luật bầu chọn/thắng hoặc vòng đời nội dung được chốt khác đề xuất, điều chỉnh phase liên quan trước khi triển khai.

Ngoài kết quả analyze/test và smoke iOS Simulator của phase 1 ghi ở trên, phần xác minh hiện tại là đọc repository và đối chiếu tài liệu. Chưa gọi API thật, xác minh dữ liệu Dev/Production hoặc kiểm tra thiết bị thật. Kế hoạch không đưa ước lượng ngày khi thiết kế và các quyết định ở mục 3 còn chưa chốt.

Tham chiếu cho phase backend: quyền Data API cần cả grants và RLS theo [hướng dẫn bảo vệ API của Supabase](https://supabase.com/docs/guides/api/securing-your-api). Trước triển khai phase 2/7/12 và phát hành, kiểm tra lại [changelog](https://supabase.com/changelog) và khả năng kết nối trên các phiên bản hệ điều hành mục tiêu.
