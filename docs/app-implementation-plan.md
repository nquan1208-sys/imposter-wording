# Kế hoạch triển khai ứng dụng

> Nguồn yêu cầu: [Bố cục màn hình ứng dụng](layout/screen-layout.md). Đối chiếu code và migration trong repository ngày 24/10/2026, gồm schema nội dung đa ngôn ngữ mới. Trạng thái và bằng chứng kiểm tra được ghi riêng theo từng phase bên dưới; Phase 1–5 đã có analyze/test và smoke iOS Simulator. Chưa nghiệm thu backend Dev/Production.

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
| Mục 3 có `Hiển thị gợi ý`, nhưng mục 7 cấm lộ hint và backend đã bỏ hint | **Đã chốt Phase 4:** chỉ giữ `Hiển thị danh mục cho kẻ mạo danh`; không dựng một nguồn hint mới. Nếu cần gợi ý khác danh mục, phải có đặc tả nội dung và dữ liệu riêng. | Phase 4 |
| Phạm vi số kẻ mạo danh chưa có công thức; `1–4` chỉ là ví dụ | **Đã chốt Phase 4:** với N người, dùng 1…floor((N−1)/2), bảo đảm phe thường chiếm đa số; random đều trong phạm vi đó. Với tùy chọn không đi trước, chọn người bắt đầu trước rồi loại người đó khỏi tập gán vai. | Phase 4; phase 3 chỉ dùng 1 kẻ mạo danh |
| Layout vừa nói không đi trước theo người chơi đầu tiên, vừa nói chọn người bắt đầu | **Đã chốt Phase 4:** dùng một `startingPlayerId` làm nguồn duy nhất cho luật gán vai và tên người bắt đầu trên màn thảo luận. | Phase 4 |
| Chưa có UI ghi nhận người bị bầu, xử lý hòa hoặc luật thắng khi có nhiều kẻ mạo danh | Nhóm bầu bằng lời nói; nút công bố mở sheet chọn người bị nhóm bầu rồi xác nhận. Một imposter: chọn đúng thì nhóm thắng, sai thì imposter thắng. **Đã chốt Phase 4:** nhiều imposter chọn đúng K người và nhóm chỉ thắng khi chọn đúng toàn bộ tập imposter. Nếu hòa, nhóm bầu lại trước khi xác nhận; chưa làm hệ thống thu từng phiếu. | Phase 3 đã chốt chọn một người, đúng thì nhóm thắng/sai thì imposter thắng; luật nhiều imposter đã chốt ở Phase 4 |
| Game câu hỏi chưa rõ có báo vai cho người nhận câu hỏi khác hay không | **Đã chốt Phase 5:** chỉ hiện câu hỏi riêng, không báo vai; thẻ khóa giống nhau cho mọi người. **Bổ sung Phase 6:** mở `Kẻ mạo danh biết nhau` cho question; khi bật và có ít nhất hai imposter, chỉ imposter đã mở thẻ riêng mới thấy tên đồng vai. Khi tắt hoặc chỉ có một imposter, giữ hành vi Phase 5. Question vẫn giữ bản nháp riêng trong bộ nhớ và công bố trực tiếp, không ghi nhận bầu/tính bên thắng; `showCategory` cũng áp dụng cho question theo cập nhật Phase 6. | Phase 5; mở rộng ở Phase 6 |
| Tùy chỉnh chỉ dùng cho ván hiện tại nhưng cũng nói lưu local và các ván; sau lưu lại về tab `Cổ điển` không tồn tại ở màn danh mục | Giữ nội dung tùy chỉnh cho bộ thiết lập hiện tại và `Chơi lại`, không làm thư viện lâu dài. Sau lưu trở về picker theo đúng loại game/mode hiện tại. Không tự đổi từ Gia đình sang Cổ điển. | Phase 8 |
| Một field `Câu hỏi` không đủ tạo game với hai nhóm nhận câu hỏi khác nhau | Form question tùy chỉnh phải nhập một cặp câu hỏi khác nhau. Nhập nhiều dùng hai ô nhiều dòng, ghép cặp theo dòng, kiểm tra số dòng bằng nhau. | Phase 9 |
| Tùy chỉnh chưa có thuộc tính phù hợp gia đình | Khi tạo trong mode Gia đình, yêu cầu người tạo xác nhận nội dung phù hợp; không mặc định mọi nội dung tự nhập là phù hợp gia đình. | Phase 8–9 |
| Chi tiết danh sách đã lưu có `Hiển thị số kẻ mạo danh`, nhưng setup chưa có công tắc tương ứng | **Đã chốt Phase 6:** bỏ dòng này; chi tiết chỉ hiển thị luật đã có, số imposter cố định hoặc chế độ ngẫu nhiên. Không thêm setting hay luật chơi mới. | Phase 6 |
| Mục 16 chỉ có một dòng Ngôn ngữ, trong khi DB đã hỗ trợ bản dịch nội dung riêng | Đề xuất tách `Ngôn ngữ giao diện` (VI/EN từ ARB) và `Ngôn ngữ nội dung` (từ `content_languages`), mặc định đều `vi`. Đổi UI không tự đổi đề; thiếu bản dịch nội dung thì báo rỗng, không fallback sang ngôn ngữ khác. Cập nhật layout khi chốt. | Phase 11–12 |
| Chưa có ảnh cho mọi trạng thái, store URL và kênh phản hồi | Tái sử dụng theme hiện có; không hứa khớp pixel. URL/ID phát hành phải được cung cấp trước phase 11/13. | Theo phase tương ứng |

Nếu một quyết định chưa được chốt, giữ chức năng liên quan chưa khả dụng và ghi rõ trong PR; không báo phase đó hoàn tất toàn bộ đặc tả.

## 4. Quy tắc dữ liệu và vòng đời dùng xuyên suốt

### Nội dung game

Hợp đồng đọc theo schema mới, áp dụng ngay từ phase 2 dù lúc đầu chỉ dùng nội dung `vi`:

| Nguồn | Trường dùng cho app | Quy tắc |
| --- | --- | --- |
| `content_languages` | `code`, `display_name`, `sort_order` | Danh mục ngôn ngữ nội dung; có mã ngôn ngữ không đồng nghĩa đã có đề published. Phase 12 dùng cho picker. |
| `game_categories` + `game_category_translations` | Gốc: `id`, `game_type`, `sort_order`, `is_active`, `is_family_friendly`; bản dịch: `category_id`, `locale`, `name`, `description`, `status` | Ghép theo `category_id = id`; chỉ nhận bản dịch published đúng content locale và category active. `slug` unique theo `(game_type, slug)`, không phải theo locale; chọn/lưu bằng ID. |
| `word_prompts` + `word_prompt_translations` | Gốc: `id`, `category_id`, `difficulty`, `image_path`; bản dịch: `prompt_id`, `locale`, `text`, `status` | Một bản dịch cho mỗi `(prompt_id, locale)`; ảnh thuộc đề gốc, dùng chung giữa các locale. |
| `question_prompts` + `question_prompt_translations` | Gốc: `id`, `category_id`, `difficulty`; bản dịch: `prompt_id`, `locale`, `civilian_question`, `imposter_question`, `status` | Hai câu hỏi phải lấy từ cùng một hàng bản dịch; không ghép hai locale hoặc tự tạo câu còn thiếu. |

- Dùng một repository nội dung cho cả picker, số lượng content và random; model sau ghép phải giữ ID gốc và `contentLocale`. Giao diện không tự lọc lại bằng một bộ luật khác.
- Content hợp lệ phải đúng loại game, có **bản dịch prompt và bản dịch category cùng locale đều `status = published`**, category `is_active = true`; Gia đình chỉ áp dụng cho từ ngữ và yêu cầu `game_categories.is_family_friendly = true`; lấy toàn bộ từ hợp lệ trong danh mục. Cổ điển lấy cả content phù hợp và không phù hợp gia đình. Không còn `locale`/`status` trên bảng prompt gốc hay các cột hint từ schema lịch sử.
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
- `Chơi lại` kết thúc session và quay về màn thiết lập, giữ thiết lập/người chơi để chỉnh trước ván kế tiếp. Chỉ khi nhấn bắt đầu tại setup mới tạo session và random lại từ tập hợp lệ. Có thể trùng prompt khi tập nhỏ; không thêm lịch sử chống lặp ở bản đầu.
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
| 6. Danh sách người chơi đã lưu và tùy chọn kẻ mạo danh | Lưu/chọn/xem chi tiết/đổi tên/xóa nhóm; modal chọn imposter; question có tùy chọn biết nhau; giữ mode, danh mục và ngôn ngữ hiện tại | 4, 5 |
| 7. Hoàn thiện đồng bộ content và ảnh | Refresh từ setup, ảnh word từ Storage; phục hồi lỗi đồng bộ và cache | 5 |
| 8. Tùy chỉnh word bằng văn bản | Tạo danh mục/từ, nhập nhiều, dùng ngay trong ván word | 4 |
| 9. Tùy chỉnh question bằng văn bản | Tạo cặp câu hỏi tùy chỉnh và chơi trọn ván question | 5, 8 |
| 10. Ảnh cho nội dung tùy chỉnh | Chọn/chụp/thay/xóa ảnh, hiện đúng cho người có quyền xem | 9 |
| 11. Cài đặt và hỗ trợ | Đổi/lưu ngôn ngữ giao diện VI/EN, xem phiên bản/ID, đánh giá và phản hồi | 5 |
| 12. Tích hợp ngôn ngữ nội dung | Chọn ngôn ngữ từ DB, chơi cả hai game bằng bản dịch đúng locale, cache/offline tách ngôn ngữ | 6, 7, 10, 11 |
| 13. Hoàn thiện bản phát hành | Hai game và mọi tính năng đã chọn chạy trên Android/iOS release | 1–12 |

Thứ tự mặc định là 1 → 13. Giữ số phase 1–11; phase 12 mới dành cho ngôn ngữ nội dung, phase phát hành cũ chuyển thành 13. Sau phase 4, phase 8 có thể làm trước phase 5 nếu ưu tiên sản phẩm thay đổi; phase 6 cần phase 5 để mở tùy chọn biết nhau cho question. Phase 7 không phải điều kiện để chơi: phase 2 đã đọc bản dịch `vi` đầy đủ từ backend và cache. Phase 12 mở rộng repository có sẵn sang nhiều locale, không duy trì hai bộ game logic.

Đối chiếu phạm vi layout:

| Mục trong layout | Phase chịu trách nhiệm |
| --- | --- |
| 1–2: bắt đầu, cách chơi | 1; cập nhật hướng dẫn theo luật mới ở 4–5 |
| 3–4: setup, picker và bottom sheet imposter | 2, 4; bật question ở 5; hoàn thiện modal imposter và biết nhau cho question ở 6; hoàn thiện sync/ảnh ở 7, đổi content locale ở 12 |
| 5: tạo tùy chỉnh | 8–10 |
| 6–9: luồng word và kết quả | 3–4 |
| 10–14: luồng question và kết quả | 5; bổ sung hiển thị đồng vai riêng tư ở 6 |
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
hai tab Tất cả danh mục/Chế độ gia đình trong picker từ ngữ với bản chọn tạm, load content nền dùng chung,
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

### Cập nhật lưu trữ local — Hive CE (25/10/2026)

- Setup/người chơi và snapshot nội dung hiện lưu trong hai box `settings` và
  `content_cache` tại `<ApplicationSupport>/hive/`. Mỗi bản ghi là chuỗi JSON
  có `version: 1`, `scope`, `data`; key scope giữ môi trường + URL backend chuẩn
  hóa + locale nội dung hiện tại (`vi`). Signals giữ state, Riverpod cấp một
  `HiveLocalStorage` dùng chung; không thêm adapter, generator hoặc bước mở box
  chặn `runApp`.
- `SetupStore` và `ContentRepository` dùng `LocalJsonStore`. Storage mở box khi
  cần, chia sẻ lần mở, cho thử lại sau lỗi, tuần tự hóa thao tác và chờ `put()`
  hoàn tất. Khi Riverpod dispose, hàng đợi ghi setup được bàn giao cho storage;
  storage chờ ghi xong rồi đóng box. Lỗi đọc cache có thể thử lại ngay khi offline.
- Khi chưa có key Hive, đọc `content/<scope-base64>/setup.json` hoặc
  `snapshot.json` cũ, kiểm tra version/scope và `GameSetup.fromJson` hoặc
  `ContentSnapshot.fromJson`, rồi ghi Hive. Chỉ key đã ghi thành công mới xác
  nhận migration; không tạo marker. Bản ghi Hive tồn tại luôn được ưu tiên;
  Hive hỏng báo lỗi theo luồng hiện có, không fallback sang JSON. Lỗi đọc/ghi
  không tự xóa/reset dữ liệu.
- File JSON cũ được giữ nguyên để phục hồi thủ công và không cập nhật sau
  migration. Rollback sang app chỉ đọc JSON sẽ thấy dữ liệu tại thời điểm
  migration, không thấy thay đổi mới trong Hive. Không thêm nhiều danh sách
  người chơi, lưu ván, UI locale, tài khoản, đồng bộ hoặc mã hóa.
- Fake test đã chuyển thành `MemoryStorage` theo interface. Test Hive thật trong
  thư mục tạm kiểm tra restart, scope, lỗi mở/thử lại, migration hợp lệ/thiếu/
  sai version/scope/data/JSON, lỗi `put()` rồi restart, ưu tiên Hive mới hơn JSON,
  Hive hỏng, đóng storage chờ ghi và lifecycle Riverpod.
- Kiểm tra: `flutter analyze` sạch; **110/110 unit/widget test pass**. Smoke `word_game_smoke_test.dart` **2/2 pass** trên iPhone 17
  Pro Simulator iOS 26.5: nhập cả hai JSON cũ, đóng/mở storage, khôi phục người
  chơi/luật, chơi offline, vote/replay/back ở cấu hình thường và nâng cao.
  Không có cảnh báo đọc signal sau dispose trong lần chạy cuối.
- `setup_smoke_test.dart` đã đổi sang Hive, có migration setup và đóng/mở lại
  trước khôi phục offline; chưa chạy lại smoke này vì chưa xác nhận fixture
  backend local đúng yêu cầu của test (1 từ Classic, 0 Family, tên danh mục
  cố định). Không seed hoặc sửa backend. Các bằng chứng JSON/smoke phase 2–4
  bên dưới là lịch sử trước thay đổi Hive.
- Giữ nguyên thay đổi gộp ô “Người chơi” đang có. Không chụp ảnh UI; chưa kiểm
  tra thiết bị thật, Android runtime, release, kill/relaunch tiến trình hoặc
  chế độ máy bay thật.

### Phase 3 — Ván word hoàn chỉnh đầu tiên

**Trạng thái triển khai 24/10/2026:** đã nối setup → danh sách người chơi → thẻ
bí mật → thảo luận → sheet bầu chọn → kết quả → chơi lại. Session sống trong một
route, giữ bản sao setup/content, đúng một imposter và người bắt đầu random một
lần từ toàn bộ người chơi. Không bật hiển thị danh mục cho imposter ở phase này.

**Quyết định đã chốt:** nhóm bầu bằng lời; sheet ghi nhận đúng một người. Đúng
imposter thì nhóm thắng, sai thì imposter thắng; hòa thì nhóm bầu lại trước khi
xác nhận. Hủy sheet không công bố vai. Layout và hướng dẫn VI/EN đã cập nhật.

Back từ thẻ về danh sách mà chưa đánh dấu hoàn tất; back trong ván hỏi kết thúc,
back từ kết quả về setup. App ra nền che thẻ và yêu cầu mở lại. `Chơi lại` hủy
session và quay về setup, giữ nguyên thiết lập; nhấn bắt đầu tại setup mới tạo
ván tiếp theo từ content hợp lệ hiện tại.
Không lưu session xuống đĩa; ảnh word vẫn thuộc Phase 7.

**Bằng chứng kiểm tra Phase 3:**

- `flutter gen-l10n`, `flutter analyze`: thành công, không có issue.
- `flutter test`: **72 tests passed**. Bao gồm gán vai/seed, snapshot bất biến,
  stage guards, bầu đúng/sai, hủy sheet, back/cancel, nhấn bắt đầu lặp,
  chơi lại về setup cả khi content rỗng, lifecycle/semantics, UI VI/EN, 100 người và màn 320×568
  với text scale 2 qua cả bước bầu chọn/kết quả.
- `flutter test integration_test/word_game_smoke_test.dart -d <iPhone-17-Pro-simulator-id>
  --dart-define=APP_ENV=local`: **1 test passed** trên iOS 26.5 Simulator.
  Fixture được ghi vào cache JSON thật ở thư mục test, repository tải lại với
  nguồn mạng giả lập offline, rồi chơi hết ván → bầu → kết quả → chơi lại về setup
  → nhấn bắt đầu tạo ván mới → kết thúc về setup.
  Không gọi backend, không seed DB và không kiểm thử máy bay/kill-relaunch thật.
- `flutter build apk --debug --dart-define=APP_ENV=local` và
  `flutter build ios --simulator --debug --dart-define=APP_ENV=local`: thành công.
- Không chụp hoặc kiểm tra ảnh UI theo hướng dẫn project. Chưa nghiệm thu
  gameplay trên thiết bị thật, Android runtime hoặc bản release; các quyết định
  nhiều imposter/luật nâng cao vẫn để Phase 4.

**PR đề xuất:** `feat(app): ship playable word game loop`

- Phạm vi: màn 6–9; dùng setup ở phase 2 và một kẻ mạo danh. Nâng nút bắt đầu từ chưa khả dụng thành tạo session thực.
- Chọn ngẫu nhiên prompt và vai một lần; danh sách tên mặc định → thẻ che → xem từ hoặc vai → `Hiểu rồi!`. Chỉ người thường được xem từ và danh mục sau khi mở thẻ; không rò bí mật qua heading/semantics khi đang che. Ảnh word bổ sung ở phase 7.
- Khi tất cả hoàn tất mới sang hướng dẫn thảo luận; hiện người bắt đầu. `Thông báo kết quả` mở sheet chọn đúng một người nhóm đã bầu, xác nhận rồi mới công bố vai thật/từ và bên thắng. Không thu từng phiếu; sheet và luật thắng một imposter đã chốt vào layout theo mục 3.
- `Chơi lại` hủy session và về setup, giữ nguyên cấu hình; chỉ nhấn bắt đầu tại setup mới tạo session tiếp theo. Back trong ván chỉ trở về danh sách khi an toàn hoặc hỏi kết thúc ván; không pop về một reveal đã hoàn tất. App ra nền che bí mật khi trở lại.
- Điểm chạm: feature word_game, session dùng chung, content repository, routes, ARB; không thêm bảng lưu ván backend.
- **Nghiệm thu:** 3 người trở lên chơi được từ đầu đến cuối, kể cả ở chế độ máy bay sau khi đã tải content thành công ít nhất một lần; không mở lại thẻ đã xong; rebuild không đổi vai/từ; chạm nhanh không xác nhận hai người hoặc tạo hai ván.
- **Kiểm tra:** unit test gán đúng một vai, chặn chuyển stage sớm và xác định thắng khi bầu đúng/sai bằng random có seed/fake; widget/integration test trọn ván, hủy sheet bầu chọn, back, pause/resume, giữ setup khi chơi lại. Không kiểm tra phân phối random bằng test xác suất dễ chập chờn.

### Phase 4 — Tên người chơi và các luật cấu hình

**Trạng thái triển khai 25/10/2026:** đã thêm editor danh sách hiện tại (tên/trim,
thêm/xóa/sắp xếp bằng nút lên/xuống, draft và xác nhận bỏ thay đổi), ID ổn định,
lưu thiết lập và tương thích dữ liệu Phase 2–3. Chưa mở danh sách đã lưu (Phase 6).

**Quyết định đã chốt với người dùng:** không có hint riêng; fixed/random đều trong
1…floor((N−1)/2); chọn người bắt đầu trước và loại khỏi tập vai khi bật không đi
trước; nhóm chỉ thắng nếu chọn đủ và đúng toàn bộ K imposter. Tiết lộ danh mục và
tên đồng vai chỉ sau khi imposter mở thẻ. Cách chơi VI/EN và layout đã cập nhật.

**Bằng chứng kiểm tra Phase 4:**

- `flutter gen-l10n`, `flutter analyze`: thành công, không có issue.
- `flutter test`: **89 tests passed**. Có kiểm tra fixed/random ở biên 3/100,
  giảm N, dữ liệu cũ/hỏng, tên trùng/trim/ID/thứ tự, draft hủy/xác nhận,
  không đi trước, bầu thiếu/đúng/sai toàn tập và quyền riêng tư của tên đồng vai.
- Widget test editor và sheet cấu hình trên 320×568, 844×390, 1024×768 với
  text scale 2; hồi quy ván một imposter và chơi hết ván hai imposter.
- `flutter test integration_test/word_game_smoke_test.dart -d <iPhone-17-Pro-simulator-id>
  --dart-define=APP_ENV=local`: **2 tests passed**, iOS 26.5 Simulator.
  Một imposter và hai imposter (không đi trước, hiển thị danh mục, biết nhau)
  đều đi hết ván → bầu → kết quả → replay → tạo ván mới → kết thúc về setup.
  Đọc cache JSON thật trong thư mục test với nguồn mạng giả lập offline;
  không gọi backend, seed DB, kill/relaunch hoặc dùng chế độ máy bay thật.
- Không chụp hoặc kiểm tra ảnh UI. Chưa kiểm tra thiết bị thật, Android runtime
  hoặc bản release; Phase 4 không thay schema, plugin hoặc cấu hình native.
- Sau khi gộp thao tác người chơi: `flutter analyze` không có issue,
  `flutter test` **90 tests passed**; đã cập nhật integration test setup sang
  màn chỉnh danh sách nhưng chưa chạy lại trên simulator.

**PR đề xuất:** `feat(app): add roster editing and imposter options`

- Phạm vi: màn 15 phần danh sách hiện tại và phần còn lại của màn 3/bottom sheet, chưa gồm danh sách đã lưu.
- Ô **Người chơi** trên setup mở thẳng màn chỉnh danh sách hiện tại; bỏ nút **Chỉnh sửa người chơi** riêng và sheet tăng/giảm số lượng. Số hiển thị lấy từ danh sách đã xác nhận; hủy draft giữ nguyên số cũ. Khi giảm người, tự giới hạn lại số kẻ mạo danh theo N.
- Đổi tên, thêm/xóa, sắp xếp người chơi; 3–100 người, trim tên, tên trống không được lưu. Dùng ID riêng để tên trùng không làm gán nhầm vai/câu trả lời; thêm người sinh tên mặc định theo danh sách hiện tại.
- Fixed/random số kẻ mạo danh, validation theo N, cập nhật lại cấu hình khi giảm người chơi; tùy chọn không đi trước, hiển thị danh mục, biết nhau. `Biết nhau` chỉ hiện tên đồng vai sau khi mở thẻ và không lộ từ/ảnh.
- Chốt xử lý công tắc hint và luật nhiều kẻ mạo danh trước khi bật UI; cập nhật Cách chơi cho đúng luật đã duyệt. Mở rộng sheet ghi nhận người bị bầu và kết quả theo số imposter; không bỏ tính thắng/thua của phase 3.
- Điểm chạm: setup, player_names, session assignment, local settings, word reveal, ARB và test phase 3.
- **Nghiệm thu:** đổi cấu hình rồi chơi trọn ván; người bắt đầu được hiển thị đúng và không là imposter khi bật ràng buộc; cấu hình không thể tạo ván không hợp lệ.
- **Kiểm tra:** unit test biên 3/100 người, fixed/random, giảm N, tên trùng, thứ tự, không đi trước và tập người bị bầu đúng/sai/thiếu theo luật đã chốt; widget test thêm/xóa/sửa, hiển thị đồng vai đúng thời điểm.

### Phase 5 — Ván question hoàn chỉnh

**Trạng thái triển khai 27/10/2026:** đã mở question trong setup/picker, dùng cặp
câu hỏi từ repository/cache hiện có, giữ game type trong thiết lập Hive và chơi
trọn luồng người chơi → câu hỏi riêng/trả lời → câu hỏi chung → thảo luận →
công bố → chơi lại. Roster, số imposter cố định/ngẫu nhiên và không đi trước dùng
chung luật Phase 4; word giữ luồng bầu/thắng hiện tại.

**Quyết định đã chốt trong phạm vi Phase 5:** không báo vai hoặc đồng vai; thẻ khóa giống nhau cho tất
cả. Back trước gửi giữ draft riêng theo ID trong RAM, chỉ hiện lại khi mở đúng
thẻ; gửi trim/chặn rỗng và khóa người đã gửi. App ra nền che cả câu hỏi/ô nhập
và bỏ focus. Question công bố trực tiếp mọi imposter và câu hỏi khác, không có
sheet bầu hoặc tính bên thắng. Không gửi câu trả lời lên backend, không lưu
session/draft xuống đĩa. Thiết lập word cũ được giữ nguyên; loại game mặc định
là word.

**Mở rộng đã lên kế hoạch ở Phase 6:** thêm tùy chọn `Kẻ mạo danh biết nhau` cho question và hiển thị đồng vai sau khi mở thẻ riêng theo điều kiện bên dưới. Bằng chứng Phase 5 không xác nhận phần mở rộng này.

**Bằng chứng kiểm tra Phase 5:**

- `flutter gen-l10n`, `flutter analyze`: thành công, không có issue.
- `flutter test`: **118 tests passed**. Có kiểm tra loại game/thiết lập cũ,
  filter/count/category theo loại và mode, gán vai fixed/random ở biên 3/100,
  ID/tên trùng, snapshot, draft riêng, trim/chặn rỗng, gửi lặp và stage guards.
- Widget test chơi hết question ở Cổ điển/Gia đình, UI VI/EN, theme sáng/tối,
  màn 320×568 và 844×390 với text scale 2; kiểm tra keyboard inset, semantics,
  pause/resume che cả câu hỏi/ô nhập, giữ draft đúng người, khóa sau gửi,
  công bố nhiều imposter, back/hủy/kết thúc, replay và đổi về word.
- iOS 26.5 Simulator (iPhone 17 Pro):
  `flutter test integration_test/question_game_smoke_test.dart -d <simulator-id>
  --dart-define=APP_ENV=local`: **2 tests passed**, cả hai mode từ cache Hive
  thật qua đóng/mở storage, mạng giả lập offline → trả lời → thảo luận →
  công bố → replay → tạo session mới → kết thúc về setup.
- Hồi quy `integration_test/word_game_smoke_test.dart` trên cùng simulator:
  **2 tests passed**, word một/nhiều imposter, bầu/thắng và replay giữ nguyên.
- Không chụp hoặc kiểm tra ảnh UI; không đổi schema, plugin hoặc cấu hình native.
  Chưa nghiệm thu backend Dev/Production, thiết bị thật, Android runtime hoặc
  bản release. Mạng offline trong smoke là giả lập, không phải chế độ máy bay
  hoặc kill/relaunch tiến trình thật. Cần dữ liệu question tiếng Việt published
  trên backend đích để nghiệm thu nội dung thực tế.

**PR đề xuất:** `feat(app): add private question game loop`

- Phạm vi: màn 10–14; bật chọn question ở setup và picker đúng loại/mode. Tái sử dụng roster, session, random và lớp nội dung hiện có.
- Chọn một cặp câu hỏi từ cùng hàng `question_prompt_translations` của content locale đang dùng, đã ghép đề gốc qua repository; người thường nhận `civilian_question`, imposter nhận `imposter_question`. Thẻ bí mật che trước khi mở, form trả lời chỉ thuộc người hiện tại, submit trim và chặn rỗng/gửi lặp.
- Gửi xong khóa người chơi đó, tăng counter, không cho sửa hoặc xem lại; chỉ khi đủ câu trả lời mới hiện câu hỏi chung.
- Thảo luận công khai tên/câu trả lời nhưng giữ kín câu hỏi khác; công bố mới đánh dấu mọi imposter và hiện câu hỏi riêng. Chơi lại về setup, giữ cấu hình; bắt đầu ván mới mới tạo câu trả lời và vai mới.
- Điểm chạm: feature question_game, setup/category mapping, session stages, ARB, local content fixtures; không gửi câu trả lời lên backend.
- **Nghiệm thu:** cả Cổ điển/Gia đình chơi được từ setup tới replay; chưa gửi đủ không thể vào thảo luận; đổi loại game không mang theo câu trả lời/session cũ.
- **Kiểm tra:** unit test assignment/stage, answer validation; widget/integration test chuyển máy nhiều người, pause che câu hỏi, double submit, riêng tư trước công bố và reset khi replay.

### Phase 6 — Danh sách người chơi đã lưu và tùy chọn kẻ mạo danh

**PR đề xuất:** `feat(app): manage player presets and imposter options`

**Đã triển khai 27/10/2026; bằng chứng kiểm tra bên dưới:** giữ nguyên số Phase 6, phụ thuộc Phase 4–5; không thêm Phase 4.1 hoặc đổi số các phase khác. Phạm vi là màn 15 và đường vào quản lý nhóm, modal chọn kẻ mạo danh ở setup cho cả hai game, cùng tùy chọn biết nhau trong luồng question. Ảnh tham khảo cung cấp cấu trúc/tương tác; màu sắc, typography, component và code tiếp tục theo rules hiện tại của app.

#### Modal chọn kẻ mạo danh và tùy chọn question

- **Style theo rules của app:** ảnh chỉ tham khảo bố cục và tương tác. Màu sắc, typography, spacing, bo góc, biểu tượng, trạng thái chọn, lớp phủ modal và theme sáng/tối phải dùng `AppTheme`/`AppColors`, constants và component hiện có; không sao chép style từ ảnh hoặc tạo bộ style riêng.
- Chạm ô `Có bao nhiêu kẻ mạo danh?` ở setup mở modal dạng bottom sheet `Chọn kẻ mạo danh`, nền phía sau được làm mờ tối, phần đầu có biểu tượng và tiêu đề như ảnh `IMG_2987.PNG`. Tái sử dụng điểm mở sheet hiện có cho word/question, không thêm route riêng.
- Thay công tắc chọn ngẫu nhiên bằng hai thẻ chọn loại trừ nhau, có radio/trạng thái chọn rõ: `Cố định` — `Chọn số kẻ mạo danh chính xác`; `Ngẫu nhiên` — `Số kẻ mạo danh ngẫu nhiên mỗi ván`.
- Thẻ `Cố định` khi được chọn hiện nút `−`, số lớn ở giữa, nút `+` và dòng phạm vi. Dùng giới hạn hiện có 1…floor((N−1)/2); khóa nút tại biên, không dùng cứng `1–3` từ ảnh. Với 3–4 người, thêm card cảnh báo cần ít nhất 5 người để chọn nhiều hơn 1 imposter. Đánh dấu `1` là `Được khuyến nghị`; không thêm công thức đề xuất mới. Chọn `Ngẫu nhiên` thu phần tăng/giảm; giữ số cố định trong draft để quay lại. Số ngẫu nhiên vẫn chỉ được chọn một lần khi bắt đầu ván.
- Đưa công tắc `Kẻ mạo danh không bao giờ đi trước` vào cuối modal như ảnh, bỏ bản trùng ở setup. Tái sử dụng `imposterNotFirst` và luật `startingPlayerId` Phase 4. Cả số lượng, chế độ và công tắc nằm trong một draft: `Xác nhận` áp dụng/lưu cùng nhau; back, kéo đóng hoặc chạm ngoài hủy draft. Khi đang dùng nhóm đã lưu, chỉ cập nhật luật nhóm sau xác nhận và ghi thành công; lỗi giữ draft để thử lại.
- Theo ảnh `IMG_2986.PNG`, hiển thị công tắc `Kẻ mạo danh biết nhau` ở thẻ danh mục/tùy chọn của **cả word và question**, cho cả Cổ điển/Gia đình. Dùng chung trường `knowEachOther`, giữ giá trị khi đổi loại game, nạp nhóm hoặc chơi lại; setup cũ thiếu trường vẫn mặc định `false`. Cập nhật theo yêu cầu 27/10/2026: `Hiển thị danh mục cho kẻ mạo danh` có ở cả word/question. Trong question, người thường vẫn thấy danh mục; imposter chỉ thấy khi bật tùy chọn và mở thẻ riêng. Dùng snapshot khi bắt đầu ván.
- Question khi bật `knowEachOther` và session có ít nhất hai imposter: chỉ imposter đã mở thẻ câu hỏi riêng mới thấy tên các imposter khác, không kèm chính mình; lọc theo ID để tên trùng không làm sai danh sách. Người thường, thẻ đang khóa, danh sách chuyển máy và màn thảo luận không hiện vai/tên đồng vai. Không hiển thị câu hỏi của phe còn lại hoặc câu trả lời riêng của người khác. Khi tắt hoặc chỉ có một imposter, giữ hành vi không báo vai/đồng vai của Phase 5.
- App ra nền, back/chuyển người hoặc gửi câu trả lời phải che cả danh sách đồng vai cùng câu hỏi/ô nhập; mở lại đúng thẻ mới được xem. Session dùng snapshot `knowEachOther`, không đổi theo setup sau khi bắt đầu. Cập nhật Cách chơi VI/EN để nói rõ tùy chọn bật sẽ tiết lộ đồng vai trong thẻ riêng; giữ luồng công bố không bầu/tính thắng của question.

#### Luồng giao diện

- **Màn chỉnh sửa người chơi:** thêm thẻ nhóm trên cùng, trước số lượng và roster. Hiển thị biểu tượng thư mục, tên nhóm đang chọn hoặc `Trò chơi chưa lưu`, cùng dấu hiệu mở sheet. Cả thẻ có thể chạm. Giữ editor Phase 4: sửa tên, thêm/xóa, nút lên/xuống, giới hạn 3–100 và `Xác nhận`.
- **Sheet chọn nhóm:** tiêu đề `Danh sách đã lưu`; mục `Trò chơi chưa lưu` có mô tả chơi nhanh; các nhóm đã lưu có tên, số người và dấu chọn theo lựa chọn trong draft. Cuối sheet có `Lưu thành danh sách…` và `Quản lý danh sách`. Chọn một mục nạp vào draft rồi đóng sheet; đóng sheet không chọn thì giữ nguyên draft.
- **Lưu thành danh sách:** đóng sheet chọn trước khi mở dialog `Lưu thành danh sách mới…`, gồm trường `Tên danh sách`, placeholder `Nhập tên danh sách`, nút `Hủy`/`Lưu`. Tạo nhóm từ roster và luật trong draft, không lấy roster cũ của setup. Trim tên, chặn rỗng và trùng sau khi trim/không phân biệt hoa thường. Roster phải hợp lệ trước khi lưu; báo lỗi để người dùng sửa, không lưu tên người chơi trống.
- **Màn quản lý:** đóng sheet chọn rồi mở route `Quản lý danh sách`; back quay lại editor và giữ draft. Mỗi card có biểu tượng, tên, số người, nhãn `Đang dùng` theo nhóm đã xác nhận ở setup và nút ba chấm dọc. Khi rỗng, hướng dẫn quay về editor để lưu nhóm đầu tiên; không có nút dẫn tới màn trống.
- **Menu ba chấm:** popover neo tại nút gồm `Chi tiết`, `Đổi tên danh sách`, đường phân cách và `Xóa` dùng màu lỗi từ theme. Chạm menu không kích hoạt card. Đóng menu trước khi mở sheet/dialog tiếp theo.
- **Chi tiết:** chạm card hoặc chọn `Chi tiết` mở cùng một bottom sheet chỉ đọc; không chuyển nhóm. Có thẻ tổng quan tên/số người, tên người chơi dạng chip theo đúng thứ tự, phần luật đã lưu và ghi chú về thời điểm tự lưu. Chế độ số imposter hiển thị cố định hoặc `Ngẫu nhiên`, không lấy số đã random trong session.
- **Đổi tên:** dialog điền sẵn tên và dùng cùng validation với tạo nhóm; bỏ qua chính nhóm đang đổi khi kiểm tra trùng. Hủy giữ dữ liệu; thành công cập nhật tên ở editor, sheet chọn, quản lý và chi tiết mà không đổi ID/roster/luật.
- **Xóa:** dialog xác nhận có tên nhóm, nút hủy và nút xóa. Chỉ xóa sau xác nhận và ghi thành công; các nhóm khác giữ nguyên.
- Dùng `AppTheme`/`AppColors`, `AppContent`, constants và các widget Material hiện có; không sao chép palette tím/nền tối trong ảnh hoặc hardcode giao diện riêng. Sheet/modal cuộn được, tránh bàn phím, giữ SafeArea và nhãn truy cập cho nút biểu tượng. Nút cuối sheet xuống hàng khi thiếu chiều rộng; trạng thái chọn/đang dùng có chữ hoặc dấu chọn, không chỉ dựa vào màu.

#### Dữ liệu và thời điểm áp dụng

- Mỗi nhóm lưu ID ổn định, tên, roster có ID/tên/thứ tự, bộ đếm ID người chơi tiếp theo và các luật `imposters`, `randomImposters`, `imposterNotFirst`, `showCategory`, `knowEachOther`. Dùng validation/giới hạn imposter hiện có theo N; giảm số người tiếp tục giới hạn lại số imposter.
- Không lưu game type, mode, category IDs, UI/content locale, nội dung tùy chỉnh hoặc session vào nhóm. Chọn nhóm chỉ thay roster và các luật trên; giữ nguyên loại game, mode, danh mục và ngôn ngữ hiện tại. `knowEachOther` áp dụng cho cả word/question từ Phase 6; `showCategory` áp dụng cho cả word/question.
- Chi tiết hiển thị số imposter cố định/ngẫu nhiên, không đi trước, hiển thị danh mục và biết nhau. Bỏ dòng `Hiển thị số kẻ mạo danh`; không thêm công tắc mới để khớp ảnh.
- Mở editor tạo draft gồm roster, luật và ID nhóm được chọn. Chọn nhóm chỉ nạp dữ liệu/đổi liên kết trong draft, không ghi setup hoặc nhóm cũ. `Xác nhận` mới áp dụng draft vào setup và cập nhật nhóm được chọn nếu còn tồn tại. Back có thay đổi hỏi bỏ draft như Phase 4; bỏ draft giữ setup/nhóm đã xác nhận trước đó.
- Chọn `Trò chơi chưa lưu` giữ roster/luật trong draft và bỏ liên kết nhóm; chỉ có hiệu lực với setup sau `Xác nhận`. Không xóa hoặc ghi đè nhóm vừa rời.
- `Lưu thành danh sách` ghi nhóm mới ngay khi lưu thành công rồi chọn nhóm đó trong draft, chưa đổi nhóm đang dùng tại setup. Nếu bỏ draft sau đó, nhóm mới vẫn tồn tại trong thư viện và setup giữ lựa chọn trước đó.
- Khi setup đang dùng nhóm đã lưu, thay đổi luật tại setup tự cập nhật đúng nhóm đó. Thay đổi người chơi chỉ cập nhật sau `Xác nhận`; không tự lưu từng lần gõ hoặc thao tác thêm/xóa/sắp xếp trong editor.
- Xóa nhóm đang dùng giữ roster/luật hiện tại của setup và chuyển sang `Trò chơi chưa lưu`. Draft đang mở giữ nội dung nhưng bỏ liên kết nếu nhóm được chọn đã bị xóa. Xác nhận draft cũ không được tạo lại nhóm đã xóa. Đổi tên nhóm không làm mất draft.
- Session đang chơi tiếp tục dùng snapshot đã chụp; các thao tác với thư viện không đổi vai, prompt hoặc tiến độ ván.

#### Lưu trữ, lỗi và tích hợp

- Tái sử dụng Hive CE, `LocalJsonStore`, hàng đợi ghi và vòng đời storage hiện có; không thêm dependency, API/backend hoặc một cơ chế state management khác. Model/store nhóm đặt theo cấu trúc feature hiện tại; dùng Signals, Riverpod DI và `RouterService`/route registry hiện có.
- Lưu setup, ID nhóm đang dùng và thư viện nhất quán trong một lần ghi nguyên tử khi thao tác liên quan nhiều phần; không để khởi động lại thấy nhóm đã xóa vẫn đang dùng hoặc setup khác luật của nhóm. Giữ thứ tự ghi để thao tác cũ không ghi đè thao tác mới; storage chờ các lần ghi đang chờ trước khi đóng.
- Dữ liệu setup Phase 2–4 thiếu thư viện/liên kết nhóm được đọc với thư viện rỗng và `Trò chơi chưa lưu`, giữ nguyên roster/luật. Tiếp tục hỗ trợ migration JSON → Hive đã có; không xóa file cũ hoặc reset dữ liệu người dùng để nâng định dạng.
- Loading/read error có trạng thái rõ và nút thử lại; dữ liệu thiếu khác dữ liệu hỏng. Lỗi đọc không âm thầm reset hoặc ghi đè bản lưu. Chưa đọc/validate được dữ liệu thì chặn thao tác ghi liên quan.
- Lỗi ghi giữ form/draft và dữ liệu cần thử lại, không báo thành công/đóng dialog hoặc editor trước khi ghi xong. Chặn gửi lặp khi đang lưu; lỗi tự lưu luật phải báo chưa lưu và cho thử lại, không coi thay đổi trong bộ nhớ là đã bền vững.
- Điểm chạm: `player_names`, feature quản lý nhóm, `setup_screen`/setup store/model, `question_game` (snapshot và hiển thị đồng vai), Hive/local storage và migration, providers/routes, Cách chơi, ARB VI/EN cùng test/fixtures liên quan. Không sửa tay localization generated; giữ layout và hướng dẫn đồng nhất khi triển khai.

#### Nghiệm thu và kiểm tra

- **Nghiệm thu:** từ editor tạo nhóm → xác nhận → sửa luật → chuyển nhóm → xem chi tiết → đổi tên/xóa → đóng/mở storage vẫn giữ đúng dữ liệu. Nạp nhóm không đổi loại game/mode/danh mục/ngôn ngữ; xem chi tiết không chuyển nhóm; không mất nhóm khác hoặc thay session đang chơi.
- **Unit test:** serialize/validate, tên nhóm trim/rỗng/trùng không phân biệt hoa thường, tên người chơi trùng nhưng ID riêng, ID/thứ tự/bộ đếm và biên 3/100. Kiểm tra fixed/random, giảm N, chọn nhóm trong draft, xác nhận/hủy, chọn chưa lưu, tạo nhóm rồi bỏ draft và tự lưu luật đúng nhóm.
- **Lưu trữ:** test tương thích setup cũ và migration JSON → Hive; đóng/mở storage thật để kiểm tra nhóm/liên kết/luật. Test lỗi đọc/ghi, retry, thao tác lặp, ghi tuần tự và dispose; dữ liệu lỗi không bị ghi đè và nhóm đã xóa không bị draft cũ khôi phục.
- **Widget test:** thẻ nhóm → sheet → tạo/chọn/chưa lưu → quản lý → popover → chi tiết/đổi tên/xóa. Có hủy dialog, xóa nhóm đang dùng, đổi tên khi editor còn draft, trạng thái rỗng/lỗi/loading, bàn phím, nhãn truy cập và màn nhỏ/text scale 2. Kiểm tra menu không đồng thời mở chi tiết.
- **Modal:** widget test mở từ ô imposter ở cả hai game, chọn Cố định/Ngẫu nhiên, tăng/giảm tại biên, giảm N, giữ số khi đổi chế độ, công tắc không đi trước, xác nhận/hủy và tự lưu đúng nhóm; màn nhỏ/text scale 2 vẫn cuộn tới nút xác nhận và đọc được trạng thái chọn.
- **Question biết nhau:** unit/widget test bật/tắt, một/nhiều imposter, fixed/random, tên trùng với ID riêng, chỉ thấy đồng vai khi mở đúng thẻ, người thường không thấy; pause/resume, back, gửi/chuyển người đều che danh sách. Kiểm tra lưu/nạp nhóm, đổi loại game, snapshot và replay; chơi trọn ván question ở cả hai mode, VI/EN, không lộ câu hỏi khác trước công bố.
- Khi triển khai chạy `flutter gen-l10n`, `flutter analyze`, `flutter test`; hồi quy ván word và question sau khi nạp nhóm và kiểm tra replay giữ đúng setup. Không yêu cầu chụp ảnh hoặc image-based UI verification cho Phase 6; bằng chứng nghiệm thu dùng kết quả kiểm tra mã, static analysis và automated tests.
- Không mở rộng sang đăng nhập, đồng bộ nhiều thiết bị, luật ngoài các bổ sung nêu trên hoặc lưu ván. Bằng chứng triển khai và kiểm thử được ghi riêng bên dưới.

**Kết quả xác minh Phase 6 (27/10/2026):**

- Đã thêm thư viện nhóm trong cùng record setup, ID/bộ đếm ổn định, draft roster/luật/liên kết, route quản lý, chi tiết, đổi tên/xóa và tự lưu luật nhóm đang dùng.
- Hàng đợi tính thao tác từ bản đã commit, chỉ publish sau khi ghi thành công; read error chỉ cho thử lại, không reset. Hàng đợi vẫn được drain khi dispose; migration JSON giữ file cũ và validation kiểm tra cả thư viện/liên kết.
- Modal Cố định/Ngẫu nhiên giữ draft số lượng/không đi trước; biết nhau và hiển thị danh mục có ở cả hai game. Question chỉ render đồng vai trong thẻ imposter đã mở, lọc theo ID; che khi ra nền/back/gửi và giữ snapshot/replay.
- `flutter gen-l10n`, `flutter analyze` và `flutter test` đã chạy thành công (xem số test hiện tại trong `app/README.md`). Test có luồng nhóm đầy đủ, lỗi/retry/ghi tuần tự/dispose, migration và đóng/mở Hive thật, màn nhỏ/text scale 2/bàn phím, semantics, quyền riêng tư question, hồi quy ván word/question sau nạp nhóm.
- Không chạy kiểm tra bằng ảnh, device smoke hay integration test cần backend thật; automated tests không chứng minh hành vi thiết bị thật.

### Phase 7 — Hoàn thiện đồng bộ content và ảnh

**PR đề xuất:** `feat(app): harden content sync and word images`

**Triển khai và bằng chứng 27/10/2026 (`app-phase-7`):**

- Đã thêm refresh setup dùng chung `load()`, timeout 15 giây/trang, giữ snapshot khi lỗi và đánh dấu stale kể cả sau lần tải thành công. Kết quả rỗng hợp lệ thay cache; lỗi ghi cache chỉ cảnh báo persistence. Cache đọc lại không được thay nội dung memory mới hơn khi lần download tiếp theo thất bại.
- `WordImageCache` dùng Application Support, key backend chuẩn hóa + path, không phụ thuộc locale/không lưu URL ký. Phục hồi ảnh có sẵn trước queue tải thiếu; ký URL 300 giây, timeout, giới hạn 5 MiB, kiểm tra MIME/decode, ghi tạm + rename, renew một lần khi hết hạn/unauthorized. Lỗi ảnh độc lập và đợi startup/refresh sau.
- Hive có inventory read-only cho mọi snapshot cùng backend, kể cả legacy JSON. Cleanup serialize với download, kiểm tra lại inventory/current snapshot/session pin trước khi xóa; inventory lỗi thì không prune. Pin trước navigation và release cả khi route lỗi. Không thay setup/presets/migration/RLS/schema.
- Người thường mở thẻ và kết quả word hiện ảnh local dưới từ; placeholder ổn định khi thiếu/lỗi, prompt không ảnh chỉ hiện chữ. Không có ảnh/semantics ở thẻ che/imposter, chọn người chơi hoặc thảo luận. Refresh không đổi prompt, locale, category, vai hoặc tiến độ của hai game.
- `flutter gen-l10n` thành công, `flutter analyze` không có issue, `flutter test` **175 test qua**, 10 check HTTP/live opt-in được skip trong suite mặc định. Test bao phủ phân trang/lỗi giữa/late response/cache hỏng-rỗng/lỗi ghi/recovery, phân tách backend/chia sẻ locale/restart/cleanup/pin, ảnh đến sau/file-decode lỗi/concealment, route thất bại, refresh/category removal, hai theme và màn nhỏ/text scale 2.
- Postman local HTTP simulation: **8/8 case qua, 57 request được ghi nhận** ở lần chạy cuối. REST nhiều trang (offset 0/2), JSON 500, HTML 502, malformed payload, timeout/late response, ký ảnh 300 giây, GET token expired → ký lại → GET 200 và Storage GET 500 đều đi qua client thật. Mã và hướng dẫn chạy: `postman/simulations/phase-7.context.md`; URL đọc từ `SUPABASE_SIMULATION_URL` trong env, không hardcode địa chỉ backend trong test.
- Anonymous local read-only: **14 category, 52 word, 52 question pair**; snapshot `vi` hợp lệ, các translation anonymous trả về đều published, ký path không tồn tại bị từ chối. Không có image path trong dữ liệu hiện tại nên chưa xác minh tải ảnh hợp lệ hoặc ảnh chỉ eligible qua locale khác trên backend thật. **Dev không truy cập được/bị từ chối**, ghi nhận là chưa kiểm chứng; không ghi dữ liệu lên backend.
- Giới hạn còn lại: chưa chạy thiết bị thật/Release hoặc screenshot. Quyền tải ảnh hợp lệ và tình huống locale khác cần dataset/backend khả dụng. Content offline có thể cũ tới khi sync thành công.

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
- Lưu `contentLocale` độc lập với UI locale. Thiết lập cũ thiếu trường này được đọc là `vi`; nhóm người chơi Phase 6 không lưu hoặc ghi đè locale, nên chọn nhóm giữ nguyên cả UI/content locale hiện tại. Mã locale không còn trong danh sách sau lần tải thành công phải hiện trạng thái không khả dụng và yêu cầu chọn lại; không âm thầm đổi ngôn ngữ hoặc xóa thiết lập cũ.
- Đổi content locale ngoài ván: chuyển repository sang snapshot của locale mới, tải/validate đủ trước khi cho bắt đầu; có cache đúng locale thì dùng khi offline. Lỗi tải không hiển thị dữ liệu của locale cũ dưới nhãn mới; không có cache thì báo lỗi/thử lại. Ngôn ngữ hợp lệ nhưng chưa có đề published hiện trạng thái rỗng/chặn bắt đầu, cho đổi ngôn ngữ; không tự fallback sang VI/EN.
- Scope request và kết quả theo backend + content locale; nếu người dùng đổi nhanh VI→EN→VI, kết quả về trễ chỉ được cập nhật cache tương ứng, không ghi đè danh mục/count hiện đang xem. Picker đang mở phải hủy lựa chọn tạm khi đổi locale; validate lại category IDs và tên hiển thị bằng bộ lọc chung ở mục 4.
- Word reveal/kết quả dùng `word_prompt_translations.text` đã ghép; question lấy nguyên cặp cùng hàng translation. Session giữ locale, tên category và prompt đã chụp; refresh hoặc đổi UI không làm đổi nội dung ván. `Chơi lại` về setup và giữ locale hiện tại; khi bắt đầu ván tiếp theo mới tạo session theo quy tắc chung.
- Nội dung tùy chỉnh chỉ hiện trong locale lúc tạo; đổi locale không xóa draft/category/ảnh đang còn vòng đời. Không nhân đôi hoặc tự dịch nội dung người chơi nhập. File ảnh remote dùng chung theo backend + `image_path`, chỉ dọn khi mọi cache locale và session đều hết tham chiếu; đổi locale không tải lại ảnh đã có.
- Điểm chạm: settings/language picker, `AppStore`/local settings, setup/category picker, data/content/cache keys, kiểm tra nhóm giữ nguyên locale khi nạp, custom content, session/reveal/kết quả, ARB và fixtures. Không thêm ARB cho mọi mã ngôn ngữ nội dung hoặc thay cấu trúc state/DI.
- **Nghiệm thu:** đổi nội dung VI↔EN và chơi trọn cả hai game, hai mode; UI EN + content VI và ngược lại hoạt động đúng. Tên/count/random đều cùng locale, không đếm nhiều bản dịch thành nhiều đề; thiếu bản dịch/đề thì rỗng; khởi động lại nhớ lựa chọn; offline chỉ chơi bằng cache đúng locale. Backend kiểm thử phải có bản dịch published cho từng tổ hợp cần nghiệm thu; mã trong `content_languages` đơn thuần không đủ.
- **Kiểm tra:** unit test bản dịch VI published/EN draft và ngược lại, category translation thiếu/ẩn, hai câu hỏi cùng locale, nhiều trang, cache tách backend/locale, response về sai thứ tự, lỗi/rỗng và thiết lập cũ. Widget/integration test đổi hai locale độc lập → chọn danh mục → nạp nhóm mà không đổi locale → chơi → replay → restart/offline, custom content không bị gắn lại locale, ảnh dùng chung không bị dọn nhầm. Read-only check trên backend local/dev xác minh anon không fallback khi bản dịch bị ẩn; dùng fixture trong test để thêm mã nội dung thứ ba mà không cần thêm ARB UI.

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

Bằng chứng analyze/test, read-only backend local và smoke Simulator được ghi riêng tại từng phase đã triển khai ở trên. Chưa xác minh dữ liệu Dev/Production hoặc kiểm tra thiết bị thật; không coi fixture hay mô phỏng offline là nghiệm thu backend đích hoặc chế độ máy bay thật. Kế hoạch không đưa ước lượng ngày khi thiết kế và các quyết định ở mục 3 còn chưa chốt.

Tham chiếu cho phase backend: quyền Data API cần cả grants và RLS theo [hướng dẫn bảo vệ API của Supabase](https://supabase.com/docs/guides/api/securing-your-api). Trước triển khai phase 2/7/12 và phát hành, kiểm tra lại [changelog](https://supabase.com/changelog) và khả năng kết nối trên các phiên bản hệ điều hành mục tiêu.
