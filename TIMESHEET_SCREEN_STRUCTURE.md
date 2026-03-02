# 📱 Timesheet Screen Structure

```
┌────────────────────────────────────────┐
│  ←  Bảng Công                    🔔 NC │  ← AppBar
├────────────────────────────────────────┤
│                                        │
│  ┌──────────────────────────────────┐ │
│  │    ←    THÁNG 12    →            │ │  ← Month Selector
│  │          2025                     │ │
│  └──────────────────────────────────┘ │
│                                        │
│  Tổng quan tháng         Chi tiết →   │  ← Section Header
│  ┌─────┐  ┌─────┐  ┌─────┐           │
│  │Ngày │  │Phép │  │Tăng │           │  ← Summary Cards
│  │công │  │năm  │  │ca   │           │
│  │22.0 │  │1.0  │  │4.5h │           │
│  │══   │  │══   │  │══   │           │
│  └─────┘  └─────┘  └─────┘           │
│                                        │
│  ┌──────────────────────────────────┐ │
│  │ T2  T3  T4  T5  T6  T7  CN      │ │  ← Weekday Headers
│  ├──────────────────────────────────┤ │
│  │              1   2   3   4   5  │ │
│  │                  8   8   8   HT │ │
│  │  6   7   8   9  ┌───┐ 11  12   │ │  ← Calendar Grid
│  │  8   8   8   8  │10 │  P   HT  │ │    (Selected: 10)
│  │                  │ 9 │           │ │
│  │ 13  14  15  16  └───┘ 18  19   │ │
│  │ ... ... ... ... ...  ...  ...  │ │
│  └──────────────────────────────────┘ │
│                                        │
│  ┌──────────────────────────────────┐ │
│  │ ✓ Chi tiết: 10-12-2025  Đủ công │ │  ← Day Details
│  ├──────────────────────────────────┤ │
│  │ Giờ vào (In)  │ Giờ ra (Out)    │ │
│  │    07:59      │     17:16       │ │
│  ├──────────────────────────────────┤ │
│  │ Phép năm (P)  │ Nghỉ lễ (NL)    │ │
│  │       0       │        0        │ │
│  ├──────────────────────────────────┤ │
│  │ TỔng ca...    │ Ngày làm việc   │ │
│  │       0       │        1        │ │
│  └──────────────────────────────────┘ │
│                                        │
│  ┌──────────┐  ┌──────────┐          │
│  │ 🔧       │  │ 📝       │          │  ← Action Buttons
│  │Xin Phép  │  │Báo cáo   │          │
│  │Trễ/Sớm   │  │điều chỉnh│          │
│  └──────────┘  └──────────┘          │
│                                        │
│  ┌──────────┐  ┌──────────┐          │
│  │ ⏰       │  │ 👆       │          │
│  │Xin Phép  │  │Điểm Chỉnh│          │
│  │Dự Kiến   │  │Quét Nhạn │          │
│  └──────────┘  └──────────┘          │
│                                        │
├────────────────────────────────────────┤
│  ▦    📅    📰    👤                  │  ← Bottom Navigation
│ Home Bảng  Daily Profile              │
│      Công  News                       │
└────────────────────────────────────────┘
```

## 🎨 Visual Elements

### 1. AppBar
- Back button (←)
- Title: "Bảng Công"
- Notification icon (🔔)
- User initial badge (NC)

### 2. Month Selector
- Left arrow (←) - Previous month
- Center: "THÁNG 12" and "2025"
- Right arrow (→) - Next month
- White card with shadow

### 3. Summary Cards (3 cards in row)
```
┌─────────────┐
│ Ngày công   │ ← Label (gray)
│   22.0      │ ← Value (green/bold)
│   ══        │ ← Progress bar (green)
└─────────────┘
```
- Card 1: Ngày công (Green #42C83C)
- Card 2: Phép năm (Blue #2196F3)
- Card 3: Tăng ca (Orange #FF9800)

### 4. Calendar Grid (7 columns × weeks)
```
Header Row: T2  T3  T4  T5  T6  T7  CN
           (Mon)(Tue)(Wed)(Thu)(Fri)(Sat)(Sun)

Cell Types:
┌───┐  ┌───┐  ┌───┐  ┌───┐  ┌───┐
│ 1 │  │ 2 │  │10 │  │ 5 │  │12 │
│ 8 │  │ 8 │  │ 9 │  │HT │  │ P │
└───┘  └───┘  └───┘  └───┘  └───┘
Normal  Normal Selected Weekend Leave

Colors:
- Working day: Light green bg, green text, shows hours
- Weekend (HT): Gray bg, red text
- Leave (P): Yellow bg, orange text
- Holiday (NL): White bg, red text
- Selected: Green bg, white text
- Today: Green border
```

### 5. Day Details Card
```
┌────────────────────────────────────┐
│ ✓ Chi tiết: 10-12-2025   [Đủ công]│ ← Header with badge
├──────────────┬─────────────────────┤
│ Label        │ Value               │ ← 2-column layout
├──────────────┼─────────────────────┤
│ Giờ vào (In) │ Giờ ra (Out)        │
│   07:59      │   17:16             │
├──────────────┼─────────────────────┤
│ Phép năm (P) │ Nghỉ lễ (NL)        │
│      0       │      0              │
├──────────────┼─────────────────────┤
│ TỔng ca      │ Ngày làm việc (Wd)  │
│      0       │      1              │
└──────────────┴─────────────────────┘
```
Badge colors:
- Đủ công: Green background
- Vắng: Gray background

### 6. Action Buttons (2×2 grid)
```
Row 1:
┌─────────────────┐  ┌─────────────────┐
│ 🔧 Icon         │  │ 📝 Icon         │
│ Xin Phép Trễ/Sớm│  │ Báo cáo         │
│ (Bổ Sung)       │  │ điều chỉnh Công │
└─────────────────┘  └─────────────────┘
  Teal (#00BCD4)       Blue (#2196F3)

Row 2:
┌─────────────────┐  ┌─────────────────┐
│ ⏰ Icon         │  │ 👆 Icon         │
│ Xin Phép Trễ/Sớm│  │ Điểm Chỉnh      │
│ (Dự Kiến)       │  │ Quét Nhạn       │
└─────────────────┘  └─────────────────┘
  Red (#F44336)        Orange (#FF9800)
```

### 7. Bottom Navigation
```
┌────┬────┬────┬────┐
│ 🏠 │ 📅 │ 📰 │ 👤 │
│Home│Bảng│News│Pro │
│    │Công│    │file│
└────┴────┴────┴────┘
      ↑ Active (Green circle)
```

## 📏 Spacing & Sizing

- **Padding**: 16px around screen edges
- **Card radius**: 12px
- **Card shadow**: Subtle (0,2) offset, 10px blur
- **Gap between cards**: 12px
- **Calendar cell**: Square with 8px margin
- **Font sizes**:
  - Title: 18px
  - Month: 24px (bold)
  - Summary values: 20px (bold)
  - Calendar numbers: 16px
  - Labels: 11-12px
  - Details: 16px

## 🎯 Interactive Elements

**Tappable:**
- ← → Month arrows
- Calendar day cells
- Action buttons (4)
- Chi tiết link (optional)

**States:**
- Normal
- Selected (green background)
- Today (green border)
- Hover (on web)
- Disabled (future dates)

## 📊 Data Flow

```
User Action → Event → BLoC → State → UI Update

Examples:
Tap "→" → ChangeMonth(2026,1) → Loading → Loaded → Render Jan 2026
Tap Day → SelectDay(date) → Loaded(selected) → Show details
```

---

**This structure ensures:**
✅ Clear visual hierarchy
✅ Easy navigation
✅ Quick data scanning
✅ Intuitive interactions
✅ Professional appearance
✅ Consistent with design

