# Kế hoạch triển khai ứng dụng

> Nguồn yêu cầu: [Bố cục màn hình ứng dụng](layout/screen-layout.md). Đối chiếu code và migration trong repository ngày 22/10/2026. Đây là kế hoạch, chưa phải xác nhận các tính năng đã triển khai.

## 1. Mục tiêu và cách chia PR

Triển khai app Flutter chơi chung trên một thiết bị, gồm game từ ngữ và game câu hỏi. Ưu tiên có một ván chơi hoàn chỉnh sớm, sau đó thêm các khả năng cấu hình và quản lý nội dung.

**Một phase tương ứng một PR.** Mỗi PR có đầu ra sử dụng được, đường vào từ giao diện, kiểm thử riêng và không cần merge một PR đang dở để chạy. Các phase có thể phụ thuộc những PR **đã merge**; độc lập không có nghĩa là tất cả PR đều làm từ cùng một baseline hoặc merge theo thứ tự bất kỳ.

- Mỗi PR gồm UI, store, dữ liệu/validation, route, bản dịch và test cần cho chính tính năng đó.
- Các chức năng chưa triển khai được ẩn hoặc có trạng thái chưa khả dụng rõ ràng; không có nút dẫn tới màn trống hay route không tồn tại.
- Phase 1–2 tạo nền và luồng thiết lập sử dụng được; **phase 3 là mốc đầu tiên chơi trọn một ván**.
- Tính năng đang hoạt động phải tiếp tục chạy sau mỗi lần merge. Không tách một tính năng thành PR UI chỉ có mock và PR logic bắt buộc phải merge cùng lúc.
- Không đưa thay đổi kiến trúc toàn app, làm lại admin hoặc dịch vụ backend mới vào PR tính năng nếu chưa cần.

## 2. Baseline đã kiểm tra

| Khu vực | Hiện trạng trong repository | Hệ quả với kế hoạch |
| --- | --- | --- |
| App | `app/lib/main.dart`; Home, Counter, Settings demo và shell bottom navigation | Chưa có màn hình hay luật chơi trong layout. Thay luồng demo bằng luồng game. |
| State và DI | `StoreBase`, `StoreProvider`, Signals, `AutoDisposeManager`, Riverpod | Tái sử dụng code hiện tại; không đưa thêm một cơ chế state management. |
| Điều hướng | `RouterService`, `RouteName`, `RouteInput`, `RoutePage`, `RouteScreen` | Dùng Navigator/service hiện có; layout không yêu cầu bottom navigation. |
| Tài liệu app | README và `app/docs/` còn mô tả RxDart/BLoC, khác code Signals/Store | Sửa các hướng dẫn liên quan trong PR nền để tránh triển khai theo pattern đã cũ. |
| Ngôn ngữ | Có hạ tầng localization và ARB tiếng Anh; chưa có ARB tiếng Việt | Thêm tiếng Việt ngay phase 1; mọi màn sau bổ sung chuỗi vào ARB. |
| Backend nội dung | Có `game_categories`, `word_prompts`, `question_prompts`, quản trị và RLS đọc published | Tái sử dụng schema và API đọc hiện có; không tạo API quản trị cho mobile. |
| Schema hiện tại | Word dùng `text`, `image_path`; question có `civilian_question`, `imposter_question`; các cột hint đã bị bỏ | Không dùng `civilian_text`, `imposter_text`, `imposter_hint` từ migration lịch sử. Question chưa có trường ảnh. |
| Dữ liệu trên thiết bị | Chưa có repository content, lưu thiết lập/danh sách, ảnh tùy chỉnh hoặc session game | Thêm khi phase sử dụng tới; không giả định những phần này đã có. |
| Kiểm thử | Có test Signals, demo navigation và auto-dispose | Giữ test nền còn phù hợp, thay assertion demo khi đổi luồng; thêm test luật chơi theo từng PR. |

Nguồn kỹ thuật chính: [pubspec](../app/pubspec.yaml), [store mẫu](../app/lib/features/counter/counter_store.dart), [routing](../app/lib/base/dependency/router/utils/route_page.dart), [schema](database-schema.dbml), [RLS](../supabase/migrations/20261003072909_rls_and_policies.sql), [đổi tên trường word](../supabase/migrations/20261021032252_rename_word_prompt_text.sql), [question hiện tại](../supabase/migrations/20261021045906_question_prompt_management.sql).

Các nhận định backend ở đây dựa trên file trong repo; chưa xác minh migration hoặc nội dung trên môi trường đang chạy.

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
| Chưa có thiết kế màu/font, ảnh cho mọi trạng thái, danh sách ngôn ngữ, store URL và kênh phản hồi | Dùng theme tối thiểu nhất quán từ phase 1; không hứa khớp pixel. Đề xuất giao diện VI/EN; nội dung game vẫn theo locale dữ liệu, không tự dịch. URL/ID phát hành phải được cung cấp trước phase 11–12. | Theo phase tương ứng |

Nếu một quyết định chưa được chốt, giữ chức năng liên quan chưa khả dụng và ghi rõ trong PR; không báo phase đó hoàn tất toàn bộ đặc tả.

## 4. Quy tắc dữ liệu và vòng đời dùng xuyên suốt

### Nội dung game

- Dùng một repository nội dung cho cả picker, số lượng content và random. Giao diện không tự lọc lại bằng một bộ luật khác.
- Content hợp lệ phải đúng loại game/locale, `status = published`, thuộc category `is_active = true`; Gia đình thêm `is_family_friendly = true`. Cổ điển lấy cả content phù hợp và không phù hợp gia đình.
- Không chọn category nghĩa là tất cả content hợp lệ; chọn nhiều category là hợp của chúng. Mỗi prompt có cơ hội được chọn như nhau trong tập hợp đó; không random category trước khiến category ít đề được ưu tiên.
- Picker chỉ hiện category có content hợp lệ và hiển thị số lượng từ cùng tập dữ liệu dùng để bắt đầu ván.
- Đổi loại/mode phải loại lựa chọn category không còn hợp lệ và thông báo; nếu không còn category nào thì về `Tất cả danh mục`. Không có content hợp lệ thì chặn bắt đầu, chỉ rõ cách sửa.
- Phase 2 dùng snapshot JSON đóng gói theo schema hiện tại. Bản build cho người dùng chỉ chứa content đã duyệt/published; fixture chứa draft/archived chỉ nằm trong test.
- Phase 7 thêm đọc backend và cache. Chưa cần manifest, delta sync, RPC random, Realtime hoặc một hệ thống content release mới.

### Thiết lập và session

- Thiết lập chứa người chơi có ID ổn định, game type, mode, category IDs và các tùy chọn. Chỉ thêm trường khi phase đó bắt đầu dùng.
- Session chụp một bản thiết lập và prompt tại thời điểm bắt đầu, gồm vai, người bắt đầu, tiến độ đã xem/trả lời và stage hiện tại. Không random lại khi rebuild, quay lại hoặc resume app.
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
| 1. Khung ứng dụng và hướng dẫn | Mở app tiếng Việt, xem Cách chơi, điều hướng/quay lại đúng | — |
| 2. Thiết lập word và danh mục offline | Chọn số người, mode, nhiều danh mục từ snapshot; thấy đúng số đề | 1 |
| 3. Một ván word hoàn chỉnh | Thiết lập → chuyển máy xem từ/vai → thảo luận → công bố → chơi lại | 2 |
| 4. Người chơi và luật nâng cao | Đổi tên/thứ tự người chơi; fixed/random imposters, không đi trước, biết nhau | 3 |
| 5. Một ván question hoàn chỉnh | Nhập câu trả lời riêng → câu hỏi chung → thảo luận → công bố → chơi lại | 4 |
| 6. Danh sách người chơi đã lưu | Lưu/nạp/đổi tên/xóa bộ người chơi và thiết lập liên quan | 4 |
| 7. Nội dung thật và cache | Lấy content published từ backend; lỗi mạng vẫn dùng bản hợp lệ trước đó | 5 |
| 8. Tùy chỉnh word bằng văn bản | Tạo danh mục/từ, nhập nhiều, dùng ngay trong ván word | 4 |
| 9. Tùy chỉnh question bằng văn bản | Tạo cặp câu hỏi tùy chỉnh và chơi trọn ván question | 5, 8 |
| 10. Ảnh cho nội dung tùy chỉnh | Chọn/chụp/thay/xóa ảnh, hiện đúng cho người có quyền xem | 9 |
| 11. Cài đặt và hỗ trợ | Đổi ngôn ngữ, lưu lựa chọn, xem phiên bản/ID, đánh giá và phản hồi | 5 |
| 12. Hoàn thiện bản phát hành | Hai game và mọi tính năng đã chọn chạy trên Android/iOS release | 1–11 |

Thứ tự mặc định là 1 → 12. Sau phase 4, phase 6 và 8 có thể làm trước phase 5 nếu ưu tiên sản phẩm thay đổi. Phase 7 không phải điều kiện để chơi: phase 2 đã cung cấp nội dung đóng gói. Các nhánh đều đi qua cùng giao diện repository/session, không duy trì hai bộ game logic.

Đối chiếu phạm vi layout:

| Mục trong layout | Phase chịu trách nhiệm |
| --- | --- |
| 1–2: bắt đầu, cách chơi | 1; cập nhật hướng dẫn theo luật mới ở 4–5 |
| 3–4: setup, picker và bottom sheet imposter | 2, 4; bật question ở 5 và content backend ở 7 |
| 5: tạo tùy chỉnh | 8–10 |
| 6–9: luồng word và kết quả | 3–4 |
| 10–14: luồng question và kết quả | 5 |
| 15: người chơi và danh sách đã lưu | 4, 6 |
| 16: cài đặt | 11 |
| 17–19: bố cục chung, điều hướng, ảnh/trạng thái còn thiếu | Áp dụng trong từng PR; đối chiếu tổng thể ở 12 |

## 6. Chi tiết từng phase

### Phase 1 — Khung ứng dụng và hướng dẫn

**PR đề xuất:** `feat(app): replace demo entry with game onboarding`

- Phạm vi: màn 1, 2 và quy tắc chung ở mục 17; theme cơ bản, SafeArea, nội dung cuộn và nút chính cuối màn.
- Chuyển entry sang màn bắt đầu; thêm màn Cách chơi và back về đúng màn gọi. Bỏ bottom navigation khỏi luồng sản phẩm, giữ RouterService; xóa code demo chỉ sau khi hết caller.
- Thêm ARB tiếng Việt, cập nhật chuỗi tiếng Anh hiện có và hướng dẫn Signals/Store trong `app/README.md`, `app/docs/`. Không sửa tay file localization generated.
- Điểm chạm: `main.dart`, `features/home`, `features/root`, router/utils, ARB, constants/theme nếu cần, test navigation hiện có.
- **Nghiệm thu:** cold start mở đúng trang; Cách chơi cuộn được; back hệ thống và back UI hoạt động. `Bắt đầu` có trạng thái chưa khả dụng rõ trong PR nền, chưa mở một trang setup giả.
- **Kiểm tra:** widget test entry → hướng dẫn → back; màn nhỏ và text scale lớn không che nút. PR cập nhật các test cũ đang phụ thuộc `Home Screen`/bottom bar.

### Phase 2 — Thiết lập word và danh mục offline

**PR đề xuất:** `feat(app): add word setup and local content selection`

- Phạm vi: phần word của màn 3–4; chọn 3–100 người với tên mặc định, 1 kẻ mạo danh cố định, Cổ điển/Gia đình, tất cả hoặc nhiều danh mục.
- Thêm model đúng schema hiện tại, repository đọc snapshot JSON đóng gói và kiểm tra dữ liệu lúc nạp. Snapshot có word và cặp question để phase 5 tái sử dụng, nhưng chưa hiện lựa chọn question.
- Bật `Bắt đầu` ở landing để vào setup; picker dùng bản chọn tạm, `Xác nhận` mới áp dụng, back hủy chỉnh sửa. Lưu thiết lập cơ bản local và xử lý lỗi đọc/ghi.
- Điểm chạm: feature setup/categories, data/content, local settings, DI, router, ARB, `pubspec.yaml`/lockfile/assets khi cần.
- **Nghiệm thu:** số lượng category và content khớp bộ lọc; đổi mode không giữ ID không hợp lệ; nhớ thiết lập sau mở lại. Nút bắt đầu ván ghi rõ chưa khả dụng cho tới phase 3; mọi thao tác cấu hình khác dùng được.
- **Kiểm tra:** unit test ma trận loại/mode/locale/status/category active, nhiều category và tập rỗng; JSON lỗi/không tương thích báo lỗi; widget test xác nhận/hủy picker và khôi phục thiết lập.

### Phase 3 — Ván word hoàn chỉnh đầu tiên

**PR đề xuất:** `feat(app): ship playable word game loop`

- Phạm vi: màn 6–9; dùng setup ở phase 2 và một kẻ mạo danh. Nâng nút bắt đầu từ chưa khả dụng thành tạo session thực.
- Chọn ngẫu nhiên prompt và vai một lần; danh sách tên mặc định → thẻ che → xem từ hoặc vai → `Hiểu rồi!`. Chỉ người thường được xem từ và ảnh word nếu có; tùy chọn hiển thị danh mục không được rò qua heading khi đang che.
- Khi tất cả hoàn tất mới sang hướng dẫn thảo luận; hiện người bắt đầu. `Thông báo kết quả` mở sheet chọn đúng một người nhóm đã bầu, xác nhận rồi mới công bố vai thật/từ và bên thắng. Không thu từng phiếu; sheet là phần bổ sung cần chốt vào layout theo mục 3.
- `Chơi lại` giữ setup và thay session. Back trong ván chỉ trở về danh sách khi an toàn hoặc hỏi kết thúc ván; không pop về một reveal đã hoàn tất. App ra nền che bí mật khi trở lại.
- Điểm chạm: feature word_game, session dùng chung, content repository, routes, ARB; không thêm bảng lưu ván backend.
- **Nghiệm thu:** 3 người trở lên chơi được từ đầu đến cuối ở chế độ máy bay; không mở lại thẻ đã xong; rebuild không đổi vai/từ; chạm nhanh không xác nhận hai người hoặc tạo hai ván.
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
- Chọn một cặp câu hỏi; người thường nhận `civilian_question`, imposter nhận `imposter_question`. Thẻ bí mật che trước khi mở, form trả lời chỉ thuộc người hiện tại, submit trim và chặn rỗng/gửi lặp.
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

### Phase 7 — Nội dung backend và cache local

**PR đề xuất:** `feat(app): load published content with offline fallback`

- Phạm vi: thay nguồn content sau repository; không thay UI hoặc luật của hai game.
- Cấu hình URL/publishable key theo môi trường; dùng quyền đọc công khai hiện có, không đăng nhập admin hoặc nhúng service-role key. Chỉ lấy trường cần cho game, không lấy thông tin người tạo/quản trị.
- Đọc category active và content published đúng locale; lấy đủ các trang theo thứ tự ổn định trước khi tính số lượng/random, không coi giới hạn trang API là toàn bộ dữ liệu.
- Khi nạp thành công, validate liên kết category/prompt rồi thay snapshot cache nguyên tử. Lỗi mạng, timeout, lỗi trang giữa hoặc payload lỗi không được ghi đè cache tốt; fallback cache gần nhất, sau đó bundled content. Một snapshot hợp lệ nhưng rỗng được xử lý là rỗng, không đánh đồng với lỗi mạng.
- Cập nhật khi mở app/refresh từ setup; đang chơi giữ nguyên session và prompt. Content bị archive/category bị tắt biến mất khỏi snapshot mới cho các ván sau. Nội dung offline có thể cũ cho tới lần đồng bộ thành công; không hứa thu hồi ngay trên máy mất mạng.
- Ảnh word từ nguồn Storage hiện có, có placeholder khi offline/404. Không bắt tải đủ ảnh mới cho bắt đầu ván.
- Điểm chạm: data/content, DI/config, local cache, setup loading/error/retry; Android internet permission và cấu hình mạng dev cần thiết. Không tự sửa RLS nếu quyền đọc hiện có đã đủ.
- **Nghiệm thu:** hai game dùng content thật; không lọt draft/archived/sai mode/category inactive; mất mạng vẫn chơi bằng nguồn fallback; không gán vai hoặc đổi prompt lại khi dữ liệu cập nhật.
- **Kiểm tra:** test repository với nhiều trang, lỗi một phần, cache hỏng/rỗng, xóa/archive và ảnh lỗi. Dùng simulation cho HTTP khi kiểm tra lỗi; chạy thêm read-only check trên backend local/dev để xác minh quyền anonymous và bộ lọc. Không dùng production để tạo/xóa fixture.

### Phase 8 — Tùy chỉnh word bằng văn bản

**PR đề xuất:** `feat(app): create local custom word categories`

- Phạm vi: màn 5 phần văn bản cho word; bật thẻ `Tạo tùy chỉnh` khi đang chọn word.
- Tên category, thêm/xóa từ, nhập nhiều dòng; trim, bỏ dòng trống, chống trùng theo giá trị trim/không phân biệt hoa thường, giữ nguyên nội dung hiển thị. Chặn tên trùng thay vì ghi đè và chặn lưu nếu không còn từ hợp lệ.
- Form có draft, rời khi thay đổi phải xác nhận; lưu thành công mới đưa vào picker và chọn category mới. Luật chọn một/nhiều category và random áp dụng cả nguồn đóng gói/remote lẫn nguồn tùy chỉnh mà không trộn trùng ID.
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

### Phase 11 — Cài đặt, ngôn ngữ và hỗ trợ

**PR đề xuất:** `feat(app): add settings and support actions`

- Phạm vi: màn 16 và màn chọn ngôn ngữ; mở từ setup, tái sử dụng Cách chơi từ cả landing/settings.
- Cho chọn VI/EN sau khi chốt danh sách ngôn ngữ, cập nhật MaterialApp và strings ngay, lưu lựa chọn local; không sửa generated l10n thủ công. Chọn ngôn ngữ UI không tự dịch content: nếu chưa có content cùng locale, phải hiển thị rõ nguồn ngôn ngữ đang dùng hoặc trạng thái không có dữ liệu theo quyết định sản phẩm.
- Hiện phiên bản/build thực tế; tạo ID cài đặt ẩn danh local một lần, hiển thị rút gọn và copy toàn bộ. Không tạo tài khoản hay thu thập định danh thiết bị.
- Dùng store URL/app ID và kênh phản hồi đã được cung cấp; mở ứng dụng ngoài có xử lý lỗi/không có app nhận. Chưa có cấu hình thì ẩn hành động hoặc giải thích rõ, không gắn URL giả.
- Điểm chạm: settings, i18n, `main.dart`, local settings, app metadata, nền tảng/link config, ARB. Không thay đổi cấu hình của session đang chơi.
- **Nghiệm thu:** đổi ngôn ngữ tồn tại qua mở lại, Cách chơi back đúng màn gọi, ID ổn định và clipboard đủ giá trị; link mở đúng đích trên từng nền tảng.
- **Kiểm tra:** widget test locale/restart/copy với service giả; kiểm tra thiết bị thật việc mở store/kênh phản hồi; nguồn content không bị đổi ngầm sang sai locale.

### Phase 12 — Hoàn thiện và kiểm tra bản phát hành

**PR đề xuất:** `chore(app): prepare mobile release and verify game flows`

- Đối chiếu toàn bộ màn/trạng thái đã chốt với layout; rà soát từ ngữ thống nhất, SafeArea, cuộn, bàn phím, focus, screen reader, text scale và nút cuối màn. Các phase trước vẫn phải có accessibility cơ bản, không dồn toàn bộ tới đây.
- Thay nhãn `untitled`/nhận diện demo bằng tên và assets được duyệt; cấu hình application/bundle ID, version/build và môi trường release. Nếu đổi package ID thì cập nhật Kotlin package/MainActivity, Gradle và iOS settings liên quan cùng PR.
- Build Android/iOS release, kiểm tra network permission/TLS với backend mục tiêu, plugin ảnh/link hoạt động trong release và không vô tình để cấu hình HTTP dev trong bản phát hành.
- Kiểm tra không có khóa đặc quyền trong source/bundle, không log vai/đáp án; chỉ đóng gói snapshot nội dung được phép phát hành. Giữ dữ liệu local khi nâng version, đặc biệt preset và thiết lập.
- Điểm chạm: lỗi tích hợp thực tế, native config/assets, test/integration_test và hướng dẫn build/UAT. Không dùng PR cuối để chứa tính năng còn thiếu của phase trước.
- **Nghiệm thu:** VI/EN theo phạm vi đã chốt; hai game, cả hai mode, preset, tùy chỉnh, ảnh, replay, offline/cập nhật content đều qua checklist trên Android/iOS. Không còn route/nút demo trong luồng sản phẩm.
- **Kiểm tra:** `flutter analyze`, `flutter test`, integration smoke và cài release build trên thiết bị. Nếu thiếu signing/tài khoản, ghi rõ bước chưa xác minh; build unsigned không thay thế kiểm tra cài/phân phối. Upload store/phát hành là bước vận hành sau PR, không được coi là đã làm.

## 7. Điều kiện hoàn thành cho mỗi PR

1. Ghi rõ phase, dependency đã merge, chức năng mới nhìn thấy từ đâu và cách demo với dữ liệu nào.
2. Có test nhỏ cho luật mới; thao tác nhập/lưu có validation và giữ dữ liệu khi lỗi. Test regression tập trung vào phần đã đổi, không tạo lại mọi test ở mọi phase.
3. Chạy `flutter analyze` và `flutter test` trong `app/`; chạy codegen/l10n khi nguồn tương ứng thay đổi. PR đụng native/plugin phải có build/check đúng nền tảng.
4. Mỗi luồng đã mở cho người dùng có back/cancel/loading/empty/error/retry thích hợp; nút chưa làm không dẫn vào đường cụt.
5. Không lộ thông tin người chơi trước thời điểm cho phép; xác nhận khi thao tác làm mất form/danh sách hoặc kết thúc ván.
6. Có ảnh/video demo và kết quả kiểm tra thực tế trong PR; phân biệt unit/widget, simulation, backend local/dev và thiết bị thật.
7. Cập nhật tài liệu nếu chốt một điểm khác layout. Mỗi PR tự hoạt động sau merge; rollback code không yêu cầu xóa dữ liệu local của người dùng.

## 8. Mốc bàn giao và phần không tự mở rộng

- **Sau phase 3:** bản thử nội bộ game word, nội dung đóng gói, một imposter.
- **Sau phase 5:** cả hai game chơi trọn ván, cấu hình và người chơi cơ bản đầy đủ.
- **Sau phase 7:** nội dung được quản lý từ admin đi tới app, có fallback offline.
- **Sau phase 10:** hoàn tất nhóm tùy chỉnh văn bản/ảnh đã chốt.
- **Sau phase 12:** ứng viên phát hành, kèm bằng chứng kiểm tra và các giới hạn còn lại.

Không tự thêm Premium, thanh toán, quảng cáo, đăng nhập người chơi, chơi online, đồng bộ danh sách nhiều thiết bị, bảng xếp hạng, timer, AI sinh nội dung, thư viện tùy chỉnh vĩnh viễn hoặc hệ thống thu từng phiếu/loại người nhiều vòng. Vẫn ghi nhận lựa chọn chung của nhóm và tính bên thắng trong game word. Nếu luật bầu chọn/thắng hoặc vòng đời nội dung được chốt khác đề xuất, điều chỉnh phase liên quan trước khi triển khai.

Phần xác minh hiện tại chỉ là đọc repository và đối chiếu tài liệu. Chưa chạy app/test, gọi API thật, xác minh dữ liệu Dev/Production hoặc kiểm tra thiết bị. Kế hoạch không đưa ước lượng ngày khi thiết kế và các quyết định ở mục 3 còn chưa chốt.

Tham chiếu cho phase backend: quyền Data API cần cả grants và RLS theo [hướng dẫn bảo vệ API của Supabase](https://supabase.com/docs/guides/api/securing-your-api). Trước triển khai phase 7 và phát hành, kiểm tra lại [changelog](https://supabase.com/changelog) và khả năng kết nối trên các phiên bản hệ điều hành mục tiêu.
