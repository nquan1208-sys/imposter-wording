# Kế hoạch UX/UI Flutter — CrazyGames inspired

Ngày lập: 2026-11-02. Trạng thái: đã triển khai; gap smoke setup live do backend local chưa chạy.

Nguồn thiết kế: [CrazyGames](../www.crazygames.com-DESIGN.md).
Phạm vi: toàn bộ `app/` Flutter; không bao gồm `admin/`.
Kế hoạch này thay hướng Bumble cho đợt redesign tiếp theo. Giữ
[checkpoint cũ](flutter-ui-refresh.md) làm lịch sử, không sửa kết quả đã ghi.

## 1. Mục tiêu và quyết định thiết kế

- Tạo cảm giác party game: nền tối, tiêu đề nổi bật, card rõ nhóm, CTA xanh lime.
- Người dùng quét nhanh cấu hình, biết bước tiếp theo và trạng thái đã hoàn thành.
- Thiết kế lại phân cấp thông tin và tương tác, không chỉ đổi bảng màu.
- Giữ luật chơi, route/input, lưu trữ, nội dung offline, validation và retry hiện có.
- Dùng dark theme làm giao diện mặc định trên cả thiết bị đang bật light mode.
  Không thêm công tắc theme hoặc thiết kế light theme trong đợt này.
- Tái sử dụng component hiện có, Material icons và font BeVietnamPro đã bundle.
  Dùng weight thật 400/500/600 đang có; chưa thêm font mới hoặc giả lập 900.
- Không thêm package, backend/schema, tính năng tìm kiếm, tài khoản, leaderboard
  hoặc danh mục game kiểu portal.

Các quyết định trên là phương án mặc định của kế hoạch; yêu cầu mới của người dùng
được ưu tiên khi triển khai.

## 2. Hiện trạng và điểm phải xử lý

| Hiện trạng từ code | Hướng sửa |
| --- | --- |
| `AppTheme.dark = light`; `main.dart` chưa đặt `themeMode` | Tạo palette dark thật, dùng `ThemeMode.dark`; bỏ giả định dark bằng light trong test |
| `AppColors` đặt tên theo màu Bumble, nhiều screen tham chiếu trực tiếp | Chuyển sang token theo vai trò, cập nhật tất cả nơi dùng; không đổi giá trị `white` thành màu tối để lách migration |
| Theme, hero, selection, footer có gradient/shadow riêng | Đồng bộ theo bảng màu và vai trò; gradient dành cho hero/section, CTA lime đặc |
| `app/DESIGN_RULES.md` vẫn mô tả Bumble và cấm gradient, khác code hiện tại | Cập nhật contract cùng phase nền tảng để người triển khai có một nguồn quy tắc |
| `AppRadii.card = 24`, `hero = 28` | Card 16, hero/sheet 22, button dạng pill; input nhiều dòng giữ góc vừa phải |
| `AppContent` giới hạn 640; grid đã hỗ trợ chữ lớn và hai cột | Giữ nền tảng responsive, tránh sao chép grid web tám cột |
| Test theme đang assert vàng, light và contrast trên nền trắng | Thay bằng contract dark và contrast đúng bề mặt/gradient; giữ test hành vi |
| README có mô tả font/theme cũ | Đồng bộ tài liệu sau triển khai; không coi số test lịch sử là baseline mới |

## 3. Chuyển tài liệu tham chiếu thành contract mobile

Tài liệu nguồn là bản trích xuất alpha từ một trang, có stylesheet bị chặn và
thiếu trạng thái. Bảng dưới là quyết định cho app, không phải tất cả đều là token
đã đo từ CrazyGames.

| Vai trò | Giá trị / quy tắc dự kiến |
| --- | --- |
| Canvas | `#0C0D14` |
| Surface / surface raised | `#1F2026` / `#2F3148`; phân tầng card, input, sheet |
| Text chính / body / muted | `#FFFFFF` / `#E5E6EE` / `#BDBFCE` |
| CTA / chữ trên CTA | `#C7FF5B` / `#0F1A00` |
| Accent / accent text | `#7361FF` / `#A48EFF`; dùng text sáng trên nền tối, kiểm tra contrast trước khi dùng tím làm nền chữ |
| Selection | Surface nhuộm tím + viền rõ + check/radio + selected semantics |
| Secondary action | Surface trắng alpha 10%, chữ sáng; phải đo trên nền đã blend |
| Border / focus | Border trung tính; focus 2 logical px sáng, không xóa focus ring |
| Error / warning / success | Token riêng cho dark, chốt giá trị bằng contrast test; luôn có nhãn/icon, giữ retry và nội dung giải thích |
| Gradient | Chọn tối đa hai gradient tím/teal từ nguồn cho hero/section; đặt chữ trên vùng nền bảo đảm contrast |
| Spacing | Tái sử dụng thang 4/8/12/16/24/32 hiện có; gutter 16 trên màn hẹp, 24 khi đủ rộng |
| Typography | Heading 24/28/32, title 18/20, body 16, phụ 14; line-height 1.4–1.5, cho phép wrap và text scaling |
| Controls | CTA tối thiểu cao 50, icon hit area tối thiểu 48×48; chiều cao tăng theo nội dung |
| Motion | Tái sử dụng `AppEffects` và reduced-motion; phản hồi nhấn nhẹ, không phóng card 1.1–1.2× trên mobile |

Các ngoại lệ chủ động so với bản trích xuất:

- Không dùng icon hit area 28 hoặc nút 34–40 cho thao tác mobile.
- Không áp `outline: none`, `active opacity: 0`, hay làm cả control mờ đến khó đọc.
- Không áp tám cột, zero gutter, hoặc cỡ chữ cố định vào màn hình điện thoại.
- Không ép APK Protocol/Artex khi repo không có font; giữ font hỗ trợ tiếng Việt.
- Bổ sung semantic status vì app có lỗi lưu, lỗi mạng và trạng thái hoàn thành;
  sự thiếu dữ liệu trong nguồn không phải lý do loại bỏ phản hồi lỗi.
- Không sao chép logo/brand CrazyGames. Không thêm hover làm điều kiện để dùng app.

## 4. UX theo màn hình

| Nhóm | Thay đổi cần làm | Điều phải giữ |
| --- | --- | --- |
| Landing, hướng dẫn | Hero gradient gọn; tên app → mô tả → ba bước chơi; một CTA lime “Bắt đầu”, hướng dẫn là action phụ | Nội dung VI/EN và điều hướng hiện có |
| Setup | Nhóm theo thứ tự: người chơi/imposter → loại game và luật liên quan → nội dung/chế độ/danh mục → trạng thái tải; CTA bắt đầu cố định cuối màn | Hai cột trên điện thoại thường; tùy chọn hiện danh mục ngay dưới loại game, chỉ word; know-each-other cho cả hai; hint tiếp tục ẩn |
| Imposter sheet | Fixed/random rõ lựa chọn; count và never-start trong cùng draft; giải thích giới hạn sát control | Confirm mới commit; back/cancel bỏ draft; cảnh báo nhóm 3–4 người |
| Danh mục, Family/All | Card/chip có selected state rõ, nhãn wrap; tóm tắt lựa chọn và xác nhận rõ | Phân biệt chọn tất cả/chọn riêng, lọc eligibility và back bỏ thay đổi |
| Người chơi, preset | Danh sách tên dễ sửa, số thứ tự rõ; phân cấp chọn danh sách/lưu/quản lý; thao tác xóa tách khỏi action chính | Draft, autosave, rename/delete identity, cảnh báo mất thay đổi và retry |
| Custom content, ảnh | Chia tên danh mục/nội dung/ảnh thành nhóm; empty state có hướng dẫn; lỗi sát field; dialog cuộn khi mở keyboard | Thêm/sửa/xóa word và question, ảnh local, recovery, validation và dữ liệu nháp |
| Word game | Phân biệt chọn người → chuyển máy → mở thẻ → thảo luận → vote → kết quả bằng tiêu đề, tiến độ và một action chính; hoàn thành có check/nhãn | Quyền mở thẻ, luật vote/scoring, ảnh chỉ trong vùng được phép, replay và exit confirmation |
| Question game | Cùng ngôn ngữ card với word; khu vực nhập câu trả lời có label và trạng thái gửi; public answers dễ đọc sau khi hoàn tất | Không mở lại câu trả lời đã khóa, draft theo ID, reveal kết quả và luật riêng của question |
| Settings, ngôn ngữ, fallback | Group tile rõ; selection/focus nhất quán; lỗi có retry, màn không tìm thấy có đường quay lại | Locale/content-language hiện có, ID chỉ copy khi yêu cầu, action chưa cấu hình vẫn disabled |

Không gộp hay bỏ bước chuyển máy/mở thẻ để rút ngắn luồng. Thẻ đang ẩn phải
giống nhau giữa các vai trò; trạng thái công khai không tiết lộ imposter sớm.

## 5. Các phase triển khai

Thực hiện tuần tự. Mỗi phase cập nhật trạng thái và ghi kết quả kiểm tra thực tế
vào kế hoạch này; không ghi “pass” cho việc chưa chạy.

### Phase 1 — Contract, token, Material theme

File: `app/DESIGN_RULES.md`, `app/lib/theme/{app_colors,app_theme,app_effects}.dart`,
`app/lib/constants/{app_radii,app_spacing,app_edge_insets}.dart`, `app/lib/main.dart`.

- Chốt semantic token và contrast; kiểm kê tất cả caller `AppColors` trước khi đổi tên.
- Định nghĩa dark `ColorScheme`, text, app bar, button, input, sheet/dialog,
  chip, list tile, switch/check/radio, tab, progress, snackbar và system bar.
- Chọn dark tường minh trong `MaterialApp`; bỏ alias dark=light. Rà caller/test
  dùng `AppTheme.light`, giữ tương thích tạm thời nếu cần để từng phase vẫn chạy.
- Giữ tất cả luồng chọn ngôn ngữ hiện tại; không sửa locale behavior ngoài scope.
- Đạt khi theme tests xác nhận dark thật, chữ/CTA/error đủ contrast, focus và
  disabled phân biệt rõ; static analysis không có tham chiếu token hỏng.

### Phase 2 — Component dùng chung

File: `app/lib/widgets/{app_content,app_action_bar,app_hero_card,app_selection_card,
app_card_grid,app_notice,player_cards}.dart`.

- Đồng bộ surface, spacing, radius, gradient và state; giữ API đang dùng nếu có thể.
- Giữ content max-width 640, lazy player rows, hai cột khi content width ≥280
  và text scale ≤1.5; fallback một cột, card cao theo nội dung.
- Footer không cộng keyboard/safe inset hai lần; notice có message và action rõ.
- Đạt khi component tests bao phủ tap/focus/disabled/selected semantics,
  reduced-motion, text scale 2 và layout hẹp; không có overflow/hit-test warning.

### Phase 3 — Landing, hướng dẫn, setup, danh mục

File: `features/landing/`, `how_to_play/`, `setup/` và các test tương ứng.

- Áp cấu trúc UX ở mục 4; thu gọn trang trí để cấu hình và CTA là nội dung chính.
- Giữ nút bắt đầu loading/disabled chống mở hai game; thông báo lỗi đọc/lưu và
  content cũ vẫn có trạng thái/retry đúng.
- Đạt khi navigation, chọn mode/danh mục, imposter draft, category word-only,
  offline/loading/empty/error và hai cột 360/375/430 vẫn đúng.

### Phase 4 — Player editor, preset, custom content

File: `features/player_names/`, `player_presets/`, `custom_content/`.

- Áp các nhóm form, action hierarchy, selection và dialog dark.
- Giữ bàn phím không che field/action; back/cancel/delete có hành vi như trước.
- Đạt khi test roster/preset/custom word/custom question và ảnh local pass,
  bao gồm lưu thất bại, giữ draft, landscape + keyboard và text scale 2.

### Phase 5 — Word game và question game

File: `features/word_game/`, `question_game/`, `widgets/player_cards.dart` nếu cần.

- Áp ngôn ngữ card/progress/action thống nhất cho từng stage và kết quả.
- Không dùng animation giữ widget bí mật cũ khi conceal; không dựng nội dung
  bí mật rồi che bằng opacity/offstage. Conceal phải loại cả widget và semantics.
- Đạt khi full flow hai game pass, có test lifecycle/background, thẻ chưa mở,
  teammate/category visibility, câu trả lời khóa/draft, vote/result/replay,
  ảnh word và danh sách đến 100 người.

### Phase 6 — Settings, locale và fallback

File: `features/settings/`, `unknown/`, `app/lib/l10n/arb/app_{vi,en}.arb` nếu đổi copy.

- Đồng bộ tiles, language picker và trạng thái unavailable; kiểm tra bản dịch
  ở mọi label mới, không hardcode copy tiếng Việt vào widget.
- Đạt khi language selection, lỗi đọc/ghi/retry, copy ID và navigation pass;
  nội dung dài VI/EN không bị cắt mất thông tin cần thao tác.

### Phase 7 — Regression và tài liệu bàn giao

- Rà toàn bộ `app/lib` và test/fixture/harness: bỏ token Bumble còn dùng,
  cập nhật theme fixture sang dark; không đổi expected behavior để che regression.
- Đồng bộ `app/README.md`, `app/DESIGN_RULES.md` và test mô tả theo giao diện mới.
- Chạy kiểm tra mục 6, ghi số test pass/skip và gap thực tế.
- Đạt khi toàn bộ app dùng contract mới, analyzer sạch, full suite pass,
  không thay dependency, route contract, store/model hoặc dữ liệu đã lưu.

## 6. Chiến lược kiểm chứng

Trước khi sửa, ghi baseline mới bằng analyzer và test suite; kết quả cũ chỉ là
lịch sử. Trong mỗi phase chạy test đúng vùng ảnh hưởng; cuối đợt chạy full suite.

Từ `app/` (các env asset cần tồn tại theo README, không in giá trị credential):

```sh
rtk proxy flutter gen-l10n
rtk proxy flutter analyze --no-pub
rtk proxy flutter test --no-pub
```

Từ repo root: `rtk git diff --check`.

Ma trận widget tests: 320/360/375/430 logical px, tablet 768, landscape có keyboard;
text scale 1 và 2; VI/EN; loading/empty/error/offline/selected/disabled; reduced
motion. Dùng test hiện có và bổ sung ca thiếu, không nhân toàn bộ suite theo mọi
tổ hợp. Contrast test kiểm tra alpha compositing và vùng gradient đặt chữ;
control thiết yếu có focus/label và vùng chạm tối thiểu 48×48.

Rà các suite trong `app/integration_test/`; chạy smoke setup/word/question offline
trên iOS Simulator và Android emulator khi môi trường sẵn sàng. Ghi rõ nếu chưa
chạy được. Backend HTTP/live checks giữ opt-in hiện có; redesign không cần đổi
backend để đạt tiêu chí UI. Không thêm screenshot, golden hoặc kiểm chứng bằng ảnh.

## 7. Rủi ro và cách giới hạn

- Đổi palette trung tâm không tự sửa mọi màu inline: rà toàn bộ caller, kể cả
  dialog, ảnh placeholder, foreground trên lime và semantics của thẻ riêng tư.
- Nguồn không cung cấp đầy đủ pressed/error/focus: contract mobile và contrast
  tests là căn cứ cho phần bổ sung; không tuyên bố khớp pixel với website.
- Font chỉ có weight đến 600: tạo phân cấp bằng size/spacing; nếu sau này cần
  font khác thì xử lý thành yêu cầu riêng sau khi có asset phù hợp.
- Test widget không chứng minh cảm nhận thị giác trên máy thật. Ghi gap thiết bị
  thực tế trong bàn giao; không tự bổ sung kiểm chứng bằng ảnh.

## 8. Theo dõi

| Phase | Trạng thái | Bằng chứng |
| --- | --- | --- |
| 1. Contract/theme | Hoàn tất | Theme tests: 3 passed; contrast trên surface/alpha/gradient, focus, disabled và kích thước control |
| 2. Components | Hoàn tất | 14 component tests passed: focus/keyboard/semantics/reduced-motion/text/keyboard layouts |
| 3. Onboarding/setup | Hoàn tất | 54 focused tests passed; final suite không còn cảnh báo hit-test; giữ hai cột 360/375/430 |
| 4. Editors/content | Hoàn tất | 28 tests passed: preset, word/question form, ảnh local, draft/error, keyboard và text scale 2 |
| 5. Gameplay | Hoàn tất | Full suite pass: flow hai game, lifecycle/semantics, word images, question draft/locked và 100 người cho cả hai |
| 6. Settings/fallback | Hoàn tất | Settings/language tests pass, retry gắn notice; dark trên light device và fallback về landing pass |
| 7. Regression/docs | Hoàn tất, có gap môi trường | gen-l10n/analyzer/diff-check sạch; 305 passed / 12 skipped; 4 offline smoke pass mỗi nền tảng, live setup fail vì backend |

### Baseline thực tế — 2026-11-02

- `flutter analyze --no-pub`: No issues found (2.9s).
- `flutter test --no-pub`: 298 passed, 12 skipped (backend opt-in).
- Working tree sạch trước triển khai. Counter demo không còn trong repo;
  đối chiếu store/provider/router hiện có và skill, không tạo lại demo.

### Regression thực tế — 2026-11-02

- `flutter gen-l10n`: thành công; chỉ sửa ARB, file generated do Flutter sinh.
- `flutter analyze --no-pub`: No issues found (7.0s).
- `flutter test --no-pub`: **305 passed, 12 skipped** (28s ở lần cuối).
  Không có overflow/hit-test warning trong log full suite.
- Bổ sung 7 widget cases: 5 adaptive-gutter widths 320/360/375/430/768,
  dark trên thiết bị light + fallback navigation, question lazy/private 100 người.
  Theme assertions kiểm tra alpha blending, gradient nội suy 11 điểm, focus,
  disabled và control size; fixture form dùng dark ở cả hai system appearances.
- Không thêm package, không sửa store/model, route names/arguments, backend/schema
  hay định dạng lưu. Thêm typed `RouteInput.landing()` cho fallback đã có route.
- Counter demo không có trong checkout hiện tại: đối chiếu provider/router hiện
  hành; giữ lifecycle store hiện có, không tạo lại demo hay đổi state management.
- Không screenshot/golden/image verification. Chưa thử máy vật lý hoặc
  TalkBack/VoiceOver; widget semantics không thay thế kiểm tra screen reader thật.

### Simulator/emulator và bàn giao — 2026-11-02

Đã chạy `flutter test --no-pub integration_test -d <device>
--dart-define=APP_ENV=local` trên cả hai nền tảng, không chụp ảnh:

| Thiết bị | Offline question | Offline word | Setup có bước backend live |
| --- | --- | --- | --- |
| iPhone 17 Pro, iOS 26.5 Simulator | 2 passed | 2 passed | 1 failed: repository loadFailed trước khi vào UI |
| Android Sm_Phone_test, API 36 emulator | 2 passed | 2 passed | 1 failed cùng precondition |

- Mỗi lệnh integration tổng kết **4 passed / 1 failed**, không báo full integration
  suite pass. Live setup thất bại ở `setup_smoke_test.dart:60`, xác nhận endpoint
  local cấu hình trả `ConnectionRefusedError` khi kiểm tra TCP từ host. Android
  đang dùng cấu hình loopback hiện có; chưa đổi env hay giả định host routing đã sẵn.
- Cả hai offline suites bao gồm setup → start, khôi phục disk/cache khi offline,
  các bước riêng tư, vote/reveal, replay và trở lại setup.
- Không khởi động/thay backend hoặc sửa expectation để làm live setup xanh. Cần
  backend local đang chạy, dataset có nội dung và host mapping đúng để chạy lại
  smoke setup live; 12 HTTP/backend unit checks vẫn opt-in như baseline.
- Sau full suite, bổ sung system-bar annotation cho landing không có AppBar;
  chạy lại 9 onboarding tests: passed. Analyzer cuối: sạch.
- `rtk git diff --check`: passed. README và design contract đã đồng bộ.
- Chưa kiểm tra máy vật lý, TalkBack/VoiceOver hay cảm nhận thị giác bằng ảnh.
  Đây là gap kiểm chứng, không phải xác nhận pixel-match với CrazyGames.
