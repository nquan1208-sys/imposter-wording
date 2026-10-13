# Nghiên cứu tích hợp ngôn ngữ cho Admin

Ngày: 2026-10-12. Phạm vi: giao diện admin Vue 3 + Vite + Nuxt UI 4; tài liệu đề xuất, chưa triển khai.

## 1. Phương án

Dùng `vue-i18n@11` cho chữ của ứng dụng và locale có sẵn của `@nuxt/ui/locale` cho chữ nội bộ của Nuxt UI. Đây là cách tích hợp được tài liệu Nuxt UI dành cho Vue hướng dẫn.

Admin hiện không chạy Nuxt: `src/main.js` tạo ứng dụng Vue, dùng Vue Router và plugin `@nuxt/ui/vue-plugin`. Vì vậy dùng hướng dẫn Vue, không thêm module `@nuxtjs/i18n` hay chuyển framework.

Hai file ngôn ngữ:

```text
admin/src/i18n/index.js
admin/src/i18n/locales/vn.json
admin/src/i18n/locales/en.json
```

- `vn.json`: chứa đầy đủ chữ tiếng Việt; mọi key và tên placeholder bằng tiếng Anh.
- `en.json`: ban đầu là `{}` hợp lệ, không phải file JSON trắng hoặc các key có giá trị `""`.
- Mã locale chạy: `vi` và `en`. Tên file `vn.json` ánh xạ vào `messages.vi`; không dùng `vn` làm mã ngôn ngữ cho Nuxt UI, HTML hay Intl.
- Ngôn ngữ mặc định và fallback: `vi`.
- Khi chọn `en` mà thiếu key, chữ ứng dụng dùng tiếng Việt. Chữ nội bộ Nuxt UI dùng locale `en`, nên giao diện có thể trộn hai ngôn ngữ trong thời gian chưa dịch.
- Chưa cần nút đổi ngôn ngữ khi `en.json` còn trống. Kiểm tra locale `en` qua test; chỉ thêm bộ chọn khi có nhu cầu sử dụng.

Nuxt UI locale không thay thế từ điển ứng dụng: `UApp :locale="vi"` hiện có chỉ cung cấp locale cho các component của thư viện, không dịch label do admin tự truyền vào.

## 2. Quy tắc keyword thống nhất

Keyword là đường dẫn ngữ nghĩa: `<namespace>.<group>.<name>`. Có thể ngắn hơn với nhóm dùng chung, ví dụ `common.actions.save`. JSON dùng object lồng nhau, không dùng key phẳng có dấu chấm.

1. Mỗi đoạn dùng chữ tiếng Anh, `lowerCamelCase`, bắt đầu bằng chữ thường: `^[a-z][a-zA-Z0-9]*$`.
2. Không dùng tiếng Việt, dấu cách, dấu gạch ngang, snake_case hay nguyên câu hiển thị làm key.
3. Không gắn mã ngôn ngữ vào key: dùng `auth.login.title`, không dùng `vn.login.title` hoặc `loginTitleVi`.
4. Đặt tên theo ý nghĩa và ngữ cảnh, không theo câu chữ: sửa bản dịch không đổi key.
5. Hai ngôn ngữ dùng cùng đường dẫn key và cùng placeholder. Khi EN chưa hoàn thiện, tập key EN được phép là tập con của VN; không tạo key chỉ có ở EN.
6. Chỉ dùng `common` khi cùng ý nghĩa ở nhiều màn hình. Không gom hai câu khác ngữ cảnh chỉ vì bản tiếng Việt giống nhau.
7. Dùng nguyên câu và placeholder `{name}`, `{count}`, `{page}`, `{pages}`; không ghép các mảnh câu bằng toán tử cộng.
8. Key lỗi mô tả nguyên nhân, ví dụ `slugExists`, `sessionExpired`; không dùng `error1` hoặc toàn bộ câu lỗi backend.
9. Key không chứa ID dữ liệu hay tên danh mục. Các giá trị đó được truyền vào placeholder.

Namespace và nhóm được thống nhất như sau:

| Namespace | Nội dung |
| --- | --- |
| `common` | `actions`, `fields`, `status`, `gameTypes`, `errors`, `confirmations` dùng chung |
| `navigation` | `items`, `accessibility`, `account`, `contentManagement` |
| `auth` | `login`, `logout`, `errors` |
| `dashboard` | `title`, `description` |
| `categories` | `title`, `description`, `fields`, `help`, `actions`, `filters`, `table`, `pagination`, `form`, `deleteDialog`, `messages`, `errors`, `confirmations` |
| `wordPrompts` | `title`, `description`, các nhóm của màn hình khi triển khai |
| `questionPrompts` | `title`, `description`, các nhóm của màn hình khi triển khai |
| `placeholder` | `eyebrow`, `title`, `description` |

Ví dụ một phần của `vn.json`:

```json
{
  "common": {
    "actions": {
      "save": "Lưu",
      "cancel": "Hủy",
      "retry": "Thử lại"
    },
    "gameTypes": {
      "word": "Từ ngữ",
      "question": "Câu hỏi"
    }
  },
  "categories": {
    "title": "Danh mục",
    "fields": {
      "name": "Tên danh mục"
    },
    "pagination": {
      "summary": "{count} danh mục · Trang {page} / {pages}"
    },
    "errors": {
      "slugExists": "Slug đã tồn tại trong loại trò chơi và ngôn ngữ này."
    },
    "confirmations": {
      "deactivateNamed": "Tắt danh mục “{name}”? Nội dung bên trong sẽ được giữ nguyên."
    }
  }
}
```

`en.json` ban đầu chỉ chứa `{}`. Khi bổ sung bản dịch, ví dụ `categories.fields.name` phải vẫn là `categories.fields.name`; không đổi thành một keyword khác để dịch cùng nội dung.

## 3. Cấu hình dự kiến

```js
// admin/src/i18n/index.js
import { createI18n } from 'vue-i18n'
import vn from './locales/vn.json'
import en from './locales/en.json'

export const i18n = createI18n({
  legacy: false,
  locale: 'vi',
  fallbackLocale: 'vi',
  messages: { vi: vn, en },
})
```

Đăng ký `.use(i18n)` trong `main.js` trước khi mount. Component dùng `const { t, locale } = useI18n({ useScope: 'global' })` và `t('categories.fields.name')`.

Trong `App.vue`, import tường minh `{ vi, en }` từ `@nuxt/ui/locale`, tạo `const uiLocales = { vi, en }` rồi truyền `<UApp :locale="uiLocales[locale]">`. Không import toàn bộ các locale. Đồng bộ `<html lang>` với locale bằng Vue watch; giai đoạn đầu đặt HTML mặc định `vi`. Hai ngôn ngữ đều LTR, không cần thêm thư viện quản lý head.

Giữ cảnh báo thiếu bản dịch trong development để tìm key sai. Trong test fallback EN, có thể tắt warning trên instance test riêng; không tắt toàn bộ cảnh báo ứng dụng để che thiếu key VN.

## 4. Phạm vi chuyển đổi trong code hiện tại

| Vị trí | Việc cần làm |
| --- | --- |
| `admin/package.json`, `admin/yarn.lock` | Thêm Vue I18n 11 và cập nhật lockfile bằng Yarn |
| `src/main.js`, `src/App.vue`, `index.html` | Đăng ký plugin, đồng bộ locale Nuxt UI và `lang` HTML |
| `src/router/index.js` | Thay literal `meta.title` / `description` bằng `titleKey` / `descriptionKey`; không dịch ngay lúc định nghĩa route |
| `src/components/admin/AdminShell.vue` | Dịch menu, breadcrumb, tiêu đề, logout, account fallback, tooltip và aria-label |
| `src/views/login/LoginView.vue` | Dịch tiêu đề, hướng dẫn, label, placeholder, footer và lỗi đăng nhập |
| `src/views/shared/AdminPlaceholder.vue` | Dịch placeholder và đọc `route.meta.descriptionKey` |
| `src/views/categories/*.vue` | Dịch toolbar, loading, trạng thái, phân trang, xác nhận tắt, lỗi detail và thông báo thành công |
| `src/components/categories/*.vue` | Dịch form, filter, header bảng, empty/caption, badge, dialog xóa, cảnh báo mất dữ liệu và accessibility |
| `src/utils/categories.js` | Thay label/lỗi Việt bằng key; giữ validation và giá trị enum nguyên trạng |
| `src/utils/adminAuth.js`, `src/api/categories.js` | Lỗi do app tạo dùng key/cause ổn định; không dịch lỗi backend bằng cách sửa nguyên object lỗi |
| `src/utils/unsavedChanges.js` | Truyền chuỗi đã dịch vào `confirmDiscard(message)`; cập nhật cả AdminShell và CategoryFormView |
| `admin/tests/*.test.js` | Đăng ký i18n khi render SSR component; cập nhật assert lỗi nội bộ từ câu Việt sang key/code ổn định |
| `admin/README.md` | Mô tả cấu trúc từ điển, quy tắc key và fallback |

Các lưu ý triển khai:

- Menu, columns của bảng, options của select/radio và date formatter phải tính trong `computed` nếu phụ thuộc locale. Gọi `t()` một lần trong mảng cố định sẽ giữ ngôn ngữ cũ khi đổi locale.
- Thông báo thành công/lỗi đang lưu trong ref nên lưu key cùng params hoặc object lỗi; dịch trong computed/template để không giữ chuỗi của locale cũ.
- `gameTypeLabels` hiện còn được dùng để xác thực `game_type`. Có thể đổi thành map key (`word: 'common.gameTypes.word'`, `question: 'common.gameTypes.question'`) và giữ kiểm tra membership theo `word`/`question`; cập nhật tất cả callers.
- Lỗi validation do ứng dụng tạo có thể dùng `Error('categories.errors.nameRequired')`, hoặc giữ `message` kỹ thuật và thêm `messageKey` nếu cần. Quy ước phải thống nhất trong auth/categories và được test; không gọi `useI18n` trong helper JS ngoài setup.
- `categoryError` và lỗi auth cần map từ code ổn định sang key ở lớp hiển thị. Không truyền tùy ý `error.message` vào `t()`, không dựa vào câu Việt để nhận dạng lỗi.
- Các RPC hiện có lỗi tiếng Việt và một số trường hợp dùng chung code (`23514`, `22023`). Giai đoạn này map thông báo khái quát đúng code; nếu cần giữ chi tiết từng nguyên nhân trong cả hai ngôn ngữ, cần bổ sung identifier lỗi ổn định từ backend ở một thay đổi riêng. Lỗi không nhận diện dùng thông báo chung đã dịch và giữ lỗi gốc để chẩn đoán.
- Ngày cập nhật trong CategoryTable hiện dùng `Intl.DateTimeFormat('vi-VN')`. Tạo formatter theo locale (`vi-VN` / `en-US`), giữ timezone hiện có; không gắn format ngày với fallback của bản dịch.
- Dịch đầy đủ cảnh báo xóa vĩnh viễn, nội dung published và việc giữ file ảnh; không làm yếu điều kiện xác nhận hay guard thay đổi chưa lưu.
- Hộp thoại `beforeunload` và validation HTML gốc có chữ do trình duyệt/OS quyết định. `window.confirm` do app gọi có thể truyền chữ đã dịch; không bảo đảm đổi ngôn ngữ của mọi thông báo trình duyệt bằng Vue I18n.
- Nội dung nhập từ database (tên, mô tả, slug) vẫn là dữ liệu. `game_type`, `locale` của nội dung, URL route, query filter, query cache key và payload không đổi theo ngôn ngữ giao diện. Đặc biệt không thay `locale: 'vi'` trong payload tạo danh mục bằng locale UI.
- Email mẫu có ký tự `@` nên giữ dưới dạng dữ liệu minh họa hoặc dùng literal interpolation đúng cú pháp Vue I18n nếu đưa vào message; kiểm tra render để tránh lỗi compiler message.

## 5. Thứ tự thực hiện và tiêu chí hoàn thành

1. Thêm plugin và hai file JSON; gom bản dịch Việt đầy đủ theo quy tắc trên.
2. Chuyển shell/login/router/placeholder, sau đó toàn bộ categories và helper liên quan.
3. Cập nhật test hiện có, bổ sung kiểm tra contract từ điển và fallback; cập nhật README.
4. Chạy `yarn test` và `yarn build:local` trong `admin`, kiểm tra trực quan các màn hình và dialog.

Các kiểm tra cần có khi triển khai:

- Mỗi đoạn key khớp regex, leaf là string không rỗng trong VN; EN được thiếu key nhưng key đã có không được rỗng.
- Không có key chỉ nằm trong EN; placeholder mỗi bản EN phải khớp bản VN.
- Với `en.json = {}`, dịch `categories.fields.name` ở locale EN trả về `Tên danh mục`, không trả về keyword.
- Duyệt các key literal trong `t(...)`, meta route và map enum/error để phát hiện key không tồn tại; regex không chứng minh được mọi key động, nên key động cần test riêng hoặc map tường minh.
- Chuyển locale trong test component làm menu, options, columns, ngày và thông báo đang hiện cập nhật; dùng một bản EN mẫu trong instance test riêng, không cần điền `en.json` production.
- Test auth, validation payload, unsaved changes và xóa danh mục vẫn giữ hành vi; UI locale EN không thay payload nội dung `vi`.
- Rà soát label, aria-label, tooltip, placeholder, confirm và cảnh báo để không bỏ sót chữ giao diện nằm trong source. Dữ liệu mẫu, brand và thông báo do trình duyệt sinh không bị tính là bản dịch thiếu.

Tài liệu này chưa thêm dependency, chưa đổi runtime, chưa chạy test/build. Không sửa các thay đổi đang có của admin hay migration.

## 6. Tài liệu chính thức

- [Nuxt UI i18n — Nuxt, link tham khảo ban đầu](https://ui.nuxt.com/docs/getting-started/integrations/i18n/nuxt): nhánh Nuxt sử dụng module `@nuxtjs/i18n`.
- [Nuxt UI i18n — Vue, áp dụng cho admin hiện tại](https://ui.nuxt.com/docs/getting-started/integrations/i18n/vue): Vue I18n 11, plugin registration và liên kết locale với UApp.
- [Vue I18n — Composition API](https://vue-i18n.intlify.dev/guide/advanced/composition): `legacy: false`, `useI18n`, global scope và computed translation.
- [Vue I18n — Fallback](https://vue-i18n.intlify.dev/guide/essentials/fallback): `fallbackLocale`, key bị thiếu và cảnh báo development.
