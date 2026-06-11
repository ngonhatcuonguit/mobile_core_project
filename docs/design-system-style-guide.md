# My THP Design System & UI Style Guide

Tài liệu này mô tả hệ thống giao diện đang dùng trong app My THP để có thể áp dụng nhất quán cho các web/app khác.

## 1. Brand Direction

- Phong cách tổng thể: hiện đại, gọn, thân thiện, rõ ràng cho ứng dụng nội bộ/nhân sự.
- Ưu tiên khả năng đọc, thao tác nhanh, phân cấp thông tin rõ.
- UI dùng nhiều khoảng trắng, card trắng trên nền xám nhạt, icon màu theo ngữ nghĩa.
- Hỗ trợ light mode và dark mode.
- Ngôn ngữ chính: tiếng Việt, có hỗ trợ tiếng Anh.

## 2. Color Tokens

### Core Colors

| Token | Hex | Usage |
| --- | --- | --- |
| `primary` | `#42C83C` | CTA chính, trạng thái thành công, điểm nhấn thương hiệu |
| `lightBackground` | `#F2F2F2` | Nền app light mode |
| `darkBackground` | `#1C1B1B` | Nền app dark mode |
| `lightGrey` | `#BEBEBE` | Placeholder, text phụ light/dark |
| `darkGrey` | `#616161` | Text phụ dark mode |

### Extended Neutral Colors

| Token | Hex | Usage |
| --- | --- | --- |
| `surfaceLight` | `#FFFFFF` | Card, menu item, dialog light mode |
| `surfaceDark` | `#2A2A2A` | Card, sheet, input dark mode |
| `pageLightSoft` | `#F5F6FA` | Nền auth hoặc các màn hình cần nền dịu |
| `textPrimaryLight` | `#1A1A1A` | Text chính light mode |
| `textPrimaryAlt` | `#111827` | Text chính trong card/list |
| `textSecondaryLight` | `#6B7280` | Label, mô tả phụ |
| `textTertiaryLight` | `#9CA3AF` | Caption, metadata, text rất phụ |
| `dividerLight` | `#F3F4F6` | Divider, line nhẹ |
| `disabledLight` | `#D1D5DB` | Disabled/empty state |

### Semantic Colors

| Token | Hex | Usage |
| --- | --- | --- |
| `success` | `#10B981` | Thành công, thông tin hồ sơ hợp lệ |
| `successBrand` | `#42C83C` | Thành công gắn với thương hiệu |
| `info` | `#2196F3` | Thông tin, lịch, chi tiết |
| `infoDeep` | `#008BD9` | Link/chính sách/thông tin quan trọng |
| `warning` | `#F59E0B` | Cảnh báo nhẹ, lịch sử/yêu cầu |
| `warningAlt` | `#FF9800` | Cảnh báo nổi bật |
| `danger` | `#F44545` | Đăng xuất, lỗi, destructive action |
| `purple` | `#8B5CF6` | Lịch làm việc, nhóm tính năng phụ |

### Icon Background Pairings

| Icon Color | Light Background | Dark Background | Typical Usage |
| --- | --- | --- | --- |
| `#10B981` | `#ECFDF5` | `#064E3B` | Hồ sơ, thành công |
| `#3B82F6` / `#2196F3` | `#EFF6FF` | `#1E3A8A` | Thông tin, lịch |
| `#F59E0B` | `#FFFBEB` | `#422006` | Lịch sử, cảnh báo |
| `#8B5CF6` | `#F5F3FF` | `#2E1B5E` | Lịch làm việc |
| `#EF4444` | `#FFF1F2` | `#4C0519` | Lỗi, đăng xuất, xem tất cả |
| `#6B7280` | `#F3F4F6` | `#1F2937` | Cài đặt, trung tính |

## 3. Typography

Font chính: `Be Vietnam Pro`

Fallback/legacy font: `Satoshi` chỉ giữ để tránh lỗi nếu còn chỗ dùng cũ.

| Token | Size | Weight | Line Height | Usage |
| --- | ---: | --- | ---: | --- |
| `h1` | 28 | 700 | 1.3 | Tiêu đề màn hình lớn |
| `h2` | 24 | 700 | 1.35 | Tiêu đề section chính |
| `h3` | 20 | 600 | 1.4 | Tiêu đề card/sheet |
| `h4` | 18 | 600 | 1.4 | AppBar title, dialog title |
| `h5` | 16 | 600 | 1.45 | Section header, subtitle |
| `h6` | 14 | 600 | 1.5 | Card title, list item title |
| `bodyLarge` | 16 | 400 | 1.55 | Nội dung chính |
| `bodyMedium` | 14 | 400 | 1.55 | Nội dung mặc định |
| `bodySmall` | 12 | 400 | 1.5 | Caption, metadata |
| `labelMedium` | 13 | 500 | 1.4 | Navigation label, tab label |
| `labelSmall` | 11 | 500 | 1.3 | Badge, chip |
| `labelTiny` | 10 | 700 | 1.2 | Status tag, micro label |
| `button` | 16 | 600 | 1.2 | Button chính |
| `buttonSmall` | 14 | 600 | 1.2 | Button nhỏ/phụ |
| `input` | 14 | 400 | 1.5 | Input text |
| `hint` | 14 | 400 | 1.5 | Placeholder |
| `numberLarge` | 24 | 700 | 1.2 | Số liệu lớn |
| `numberMedium` | 18 | 600 | 1.25 | Số liệu vừa |
| `numberSmall` | 14 | 600 | 1.2 | Counter, badge |

Guidelines:

- Không dùng font quá nhỏ dưới `10sp/10px` trừ badge cực nhỏ.
- Tiêu đề list/card thường dùng `14-16`, weight `600-700`.
- Body text dùng `14`, weight `400-500`.
- Button dùng weight `600-700`.

## 4. Spacing

Base spacing scale:

| Token | Value | Usage |
| --- | ---: | --- |
| `space-2` | 2 | Badge padding nhỏ |
| `space-4` | 4 | Khoảng cách siêu nhỏ |
| `space-6` | 6 | Badge/chip padding |
| `space-8` | 8 | Khoảng cách giữa icon/text nhỏ |
| `space-10` | 10 | Card compact padding |
| `space-12` | 12 | Padding item nhỏ |
| `space-14` | 14 | Input compact |
| `space-16` | 16 | Padding ngang mặc định, card spacing |
| `space-20` | 20 | Section spacing |
| `space-24` | 24 | Page horizontal padding hoặc block lớn |
| `space-32` | 32 | Khoảng cách giữa section lớn |

Layout rules:

- Page mobile thường dùng padding ngang `16` hoặc `24`.
- List/menu item dùng padding ngang `24`, padding dọc `12-16`.
- Quick menu dùng icon box `58x58`, label width khoảng `62`, spacing icon-label `7`.
- Profile menu icon box dùng `48x48`, icon `24`, gap text `16`.

## 5. Radius

| Token | Value | Usage |
| --- | ---: | --- |
| `radius-xs` | 5-6 | Badge, small chip |
| `radius-sm` | 8 | Chip, status tag, small tile |
| `radius-md` | 10 | Menu icon container, compact card |
| `radius-lg` | 12 | Card thường |
| `radius-xl` | 14-16 | Dialog, auth input, quick menu icon |
| `radius-2xl` | 20 | Image/article card |
| `radius-pill` | 30 | Input lớn, primary button |
| `radius-circle` | 999 | Avatar, dot indicator |

## 6. Elevation & Shadow

Shadows được dùng nhẹ, chủ yếu để tách card/icon khỏi nền.

Recommended shadows:

```css
/* Soft card */
box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);

/* Quick menu colored icon */
box-shadow: 0 3px 8px rgba(var(--icon-color-rgb), 0.15);

/* Dark mode colored icon */
box-shadow: 0 3px 8px rgba(var(--icon-color-rgb), 0.25);
```

Guidelines:

- Không dùng shadow quá nặng.
- Card vận hành/nội bộ nên tĩnh, rõ, không quá “marketing”.
- Dark mode dùng surface sáng hơn nền và giảm opacity shadow.

## 7. Components

### AppBar

- Background: transparent.
- Elevation: `0`.
- Title centered.
- Title style: `18`, weight `600`.
- Icon color: black in light mode, white in dark mode.

### Primary Button

- Background: `primary #42C83C`.
- Text: white, `16`, weight `600-700`.
- Radius: `30`.
- Elevation: `0`.
- Minimum height:
  - App-wide legacy button: `80`.
  - Modern compact CTA: `48-56`.

### Input

- Font: `14`, weight `400`.
- Hint color: `#BEBEBE`.
- Padding: large form style uses `30`.
- Border radius: `30`.
- Border width: `0.4`.
- Fill: transparent by default.

### Card

- Light mode: white surface on soft grey background.
- Dark mode: `#2A2A2A` or `#1E1E1E` on `#1C1C1C`.
- Radius: `10-16`.
- Padding: `12-20`.
- Shadow: subtle, `blur 8`, `offset 0 2/3`.

### Menu Item

- Height should feel touch-friendly: around `56-64`.
- Horizontal padding: `24`.
- Icon container: `48x48`, radius `10`.
- Icon size: `24`.
- Icon background: icon color at `10%` opacity.
- Text: `16`, weight `500`.
- Trailing chevron: `16`, grey.

### Quick Menu

- Container: `58x58`, radius `16`.
- Icon size: `26`.
- Label: `10`, weight `500`, max `2` lines.
- Label color:
  - Light: `#374151`.
  - Dark: `#BEBEBE`.
- Use semantic color pairs for icon and background.

### Badge / Status Tag

- Font: `10-11`, weight `600-700`.
- Radius: `6-8`.
- Padding: horizontal `6-8`, vertical `2-4`.
- Use filled soft background with strong text/icon color.

### Dialog

- Radius: `16`.
- Light background: white.
- Dark background: `#2C2C2C`.
- Title: `16-18`, weight `600-700`.
- Body: `13-14`, line height around `1.5`.

## 8. Iconography

- Dùng Material Icons hoặc SVG từ `assets/vectors`.
- Icon trong menu/list nên luôn có container nền nhẹ.
- Icon màu phải truyền tải ngữ nghĩa:
  - Green: cập nhật, thành công, hồ sơ hợp lệ.
  - Blue: thông tin, lịch, chính sách.
  - Amber/orange: lịch sử, yêu cầu, cảnh báo.
  - Red: đăng xuất, lỗi, hành động nguy hiểm.
  - Grey: cài đặt, neutral.
- SVG nên có viewBox vuông `24x24` hoặc tương đương.

## 9. Dark Mode

Dark mode không đảo màu máy móc. Dùng các surface gần đen nhưng vẫn phân cấp rõ.

| Role | Light | Dark |
| --- | --- | --- |
| Page background | `#F2F2F2` / `#FFFFFF` | `#1C1C1C` / `#1C1B1B` |
| Card surface | `#FFFFFF` | `#2A2A2A` / `#1E1E1E` |
| Primary text | `#1A1A1A` / `#111827` | `#FFFFFF` |
| Secondary text | `#6B7280` / `#9CA3AF` | `#B0B0B0` / `rgba(255,255,255,0.54)` |
| Divider | `#F3F4F6` | `rgba(255,255,255,0.10)` |

## 10. Motion & Interaction

- Tap targets tối thiểu `44x44`.
- Ưu tiên feedback đơn giản: ripple/tap highlight mặc định.
- Các trạng thái disabled/coming soon dùng overlay mờ và badge nhỏ.
- Không để text nhảy layout khi hover/tap/loading.

## 11. Content Style

- Text ngắn, trực tiếp, phù hợp app nghiệp vụ.
- Section label dùng tone trung tính, không quá nổi.
- Error message nên rõ hành động người dùng cần làm.
- CTA nên dùng động từ: “Cập nhật”, “Xác nhận”, “Đăng nhập”, “Lưu”.

## 12. Web CSS Token Starter

```css
:root {
  --font-family: "Be Vietnam Pro", system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;

  --color-primary: #42C83C;
  --color-bg-light: #F2F2F2;
  --color-bg-dark: #1C1B1B;
  --color-surface-light: #FFFFFF;
  --color-surface-dark: #2A2A2A;
  --color-text-primary: #1A1A1A;
  --color-text-strong: #111827;
  --color-text-secondary: #6B7280;
  --color-text-tertiary: #9CA3AF;
  --color-divider: #F3F4F6;
  --color-success: #10B981;
  --color-info: #2196F3;
  --color-warning: #F59E0B;
  --color-danger: #F44545;

  --radius-sm: 8px;
  --radius-md: 10px;
  --radius-lg: 12px;
  --radius-xl: 16px;
  --radius-pill: 30px;

  --space-8: 8px;
  --space-12: 12px;
  --space-16: 16px;
  --space-20: 20px;
  --space-24: 24px;
  --space-32: 32px;

  --shadow-card: 0 2px 8px rgba(0, 0, 0, 0.08);
}
```

## 13. Implementation Notes

- Khi port sang web, giữ `Be Vietnam Pro` để tiếng Việt hiển thị chắc và đẹp.
- Với dashboard/web app, dùng nền `#F5F6FA` hoặc `#F2F2F2`, card trắng, border/shadow nhẹ.
- Với mobile app, giữ mật độ UI vừa phải: icon container rõ, label ngắn, khoảng cách section `24-32`.
- Tránh dùng quá nhiều gradient; style hiện tại thiên về flat + soft shadow.
- Tránh palette một màu duy nhất: giữ primary green làm thương hiệu, kết hợp blue/amber/red/purple theo ngữ nghĩa.
