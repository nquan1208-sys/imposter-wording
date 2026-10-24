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
`lib/theme/app_theme.dart`; không thêm mã màu trực tiếp ở từng màn.

| Vai trò | Token / giá trị |
| --- | --- |
| CTA, hero, lựa chọn | yellow `#FFDB5B`, chữ charcoal `#202020` |
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
- Nền trắng, thẻ bo 16, hero và sheet bo 20; thẻ phẳng có viền nhẹ.
- CTA chính vàng; action phụ outlined/text, charcoal. Minimum height 50,
  padding 14×24, bo 16. Icon button minimum 48×48.
- Mỗi màn một hành động chính. CTA cuối trang phải tôn trọng safe area,
  nội dung phía trên cuộn độc lập và không bị CTA che.
- Danh mục dùng hai cột khi đủ chỗ; chuyển một cột dưới 360 px nội dung
  hoặc khi font 16 được scale lớn hơn 24. Nhãn luôn được xuống dòng.
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
