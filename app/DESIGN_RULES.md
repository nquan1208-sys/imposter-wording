# App design rules — Bumble inspired

Nguồn chuẩn: [`../docs/support.bumble.com-DESIGN.md`](../docs/support.bumble.com-DESIGN.md).
Áp dụng cho toàn bộ Flutter app, bao gồm landing, hướng dẫn, setup, danh mục,
chọn người chơi, thẻ bí mật, thảo luận, bầu chọn, kết quả và màn không tìm thấy.

## Hướng thiết kế

Ấm áp, dễ đọc, vui vẻ nhưng gọn. Dùng vàng làm điểm nhấn, charcoal cho chữ,
trắng cho nội dung và teal nhạt cho thông tin hỗ trợ/hoàn thành.
Không sao chép logo Bumble. Không dùng gradient, glass, emoji hoặc shadow nặng.
`ui-ux-pro-max` hỗ trợ quy tắc UX và Flutter; palette trong tài liệu Bumble
luôn ưu tiên hơn palette gợi ý tự động.

## Tokens và chữ

Chỉ thêm màu tại `lib/theme/app_colors.dart`, cấu hình Material tại
`lib/theme/app_theme.dart`; bo góc dùng `AppRadii`; không thêm mã màu trực tiếp ở từng màn.

| Vai trò | Token / giá trị |
| --- | --- |
| CTA, hero | yellow `#FFDB5B`, chữ charcoal `#202020` |
| Pressed CTA | amber `#C38F00`, chữ charcoal |
| Chữ phụ | gray `#575656` |
| Nền trang | background `#F8F9F9` |
| Thẻ | white `#FFFFFF`, border `#E4E4E4` |
| Hoàn thành / hỗ trợ | teal `#186146` trên tealSurface `#EDF8F4` |
| Lỗi | error `#B33212` trên trắng, kèm nội dung giải thích |

Coral gốc `#FF6224` chỉ dùng trang trí; dùng error đậm hơn cho chữ lỗi để đủ
contrast. Teal đậm thay xanh nhạt của tài liệu khi cần chữ có contrast 4.5:1.
Không dùng vàng làm chữ trên trắng. Border nhạt chỉ phân nhóm; trạng thái chọn
phải có icon, chữ hoặc viền charcoal rõ ràng.

Dùng system sans-serif hiện có, không tải font mới. Scale mobile: headline 32/28,
title 20/17, body 16, caption 15; weight 400/500/600. Line-height 1.4–1.5.
Dùng `TextTheme`, cho phép chữ xuống dòng và tuân theo text scaling hệ thống.

## Layout và components

- Dùng `AppContent` cho safe area và giới hạn nội dung 640 logical px, căn giữa.
- Padding trang 24; khoảng cách theo `AppSpacing` (4/8/12/16/24/32).
- Nền trắng, thẻ bo 12, hero và sheet bo 20; thẻ phẳng có viền nhẹ.
- CTA chính vàng; action phụ outlined/text, charcoal. Minimum height 50,
  padding 14×24, bo 16. Icon button minimum 48×48.
- Dùng `AppSelectionCard` cho lựa chọn: teal nhạt, viền charcoal và check/radio.
- Dùng `AppNotice` cho thông tin/lỗi; dùng `AppActionBar` cho footer của Scaffold.
  Footer tự xử lý keyboard inset và safe area; caller không thêm inset lần nữa.
  Khi mở bàn phím, giảm padding dọc footer còn 12 để giữ chỗ cho form.
- Mỗi màn một hành động chính. CTA cuối trang phải tôn trọng safe area,
  nội dung phía trên cuộn độc lập và không bị CTA che.
- Danh mục dùng hai cột khi đủ chỗ; chuyển một cột dưới 280 px nội dung
  hoặc khi font 16 được scale lớn hơn 24. Nhãn luôn được xuống dòng.
- Thẻ roster và item trong editor dùng padding 16 để tránh lãng phí chỗ khi
  có nhiều dữ liệu; các thẻ lựa chọn/nội dung khác giữ padding 24.
- Dùng Material vector icons hiện có, size thường 20/24/32; 48/80 cho hero.
  Icon cạnh chữ là trang trí; icon button phải có tooltip/accessible label.
- Hoàn thành có check + nhãn, lựa chọn có selected semantics; không chỉ đổi màu.
- Sheet có drag handle, nội dung cuộn; giữ cancel/back và xác nhận hiện có.
- Thẻ bí mật chỉ dựng nội dung sau khi người chơi mở. Luôn giữ hành vi che khi
  app mất foreground; tuyệt đối không đưa từ bí mật vào semantics khi đang ẩn.
- Không thêm animation trang trí. Giữ phản hồi nhấn Material và navigation hệ thống.

## Theme và kiểm tra

Tài liệu nguồn chỉ có light theme. Hiện `AppTheme.dark` dùng cùng light theme
một cách chủ động; chỉ triển khai dark thực khi có palette riêng và kiểm tra
contrast độc lập. Không coi đây là dark theme đã hoàn thiện.

Kiểm tra bằng `flutter analyze` và `flutter test`; widget tests cần bao phủ
màn nhỏ, chữ lớn, landscape/tablet, trạng thái chọn và luồng chơi/bảo mật thẻ.
Không mặc định chụp screenshot hay dùng kiểm tra ảnh; tuân theo AGENTS.md.

## Cập nhật UX theo yêu cầu

- Điện thoại 360–430 px ưu tiên hai cột cho người chơi/imposter, loại game và
  danh mục. Các thẻ cùng hàng có cùng chiều cao theo nội dung; không khóa height.
- Tùy chọn hiển thị tên danh mục nằm ngay dưới loại game, trước danh mục và
  các thông báo mạng. Chỉ word có tùy chọn này; question không tiết lộ tên
  danh mục cho imposter dù giá trị word đã lưu đang bật.
- Tạm ẩn tùy chọn gợi ý theo yêu cầu; không thêm cờ hoặc dữ liệu hint.
  `Kẻ mạo danh biết nhau` tiếp tục dùng chung cho hai game.

## Components dùng chung

- `AppCardGrid`: hàng hai cột tự cao, thẻ cùng hàng cao bằng nhau; fallback
  một cột khi nội dung <280 hoặc text scale >1.5. Không khóa chiều cao thẻ.
- `PlayerCards`: sliver dựng lazy theo hàng, dùng chung cho word/question;
  người đã hoàn thành có check + nhãn và không mở lại được.
- `AppSelectionCard`: trạng thái chọn/disabled qua semantics, viền focus rõ,
  giữ thao tác bàn phím bằng InkWell.
- Nội dung riêng tư không dùng animation giữ widget cũ trong cây; chỉ dựng
  sau reveal và loại khỏi widget/semantics ngay khi conceal.
