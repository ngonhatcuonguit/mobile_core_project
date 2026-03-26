# Work Schedule Setup — Logic & Data Structure (v2)

## 1. Thay đổi so với v1

| | v1 | v2 |
|---|---|---|
| Ngày áp dụng | Global `working_days` cho toàn bộ lịch | Mỗi ca tự mang `applied_days` riêng |
| Tần suất | Global `frequency_type` | Mỗi ca tự mang `repeat_type` riêng |
| Mỗi ngày có nhiều ca | ❌ | ✅ |
| Một ca áp dụng nhiều ngày | ❌ | ✅ |
| Weekly summary view | ❌ | ✅ Auto-render từ data ca |

---

## 2. Luồng nghiệp vụ

```
[Home Quick Menu → "Thông tin"]
        │
        ▼
[WorkScheduleSetupPage]
        │
        ├─ "+ Thêm ca" (top bar / empty state)
        │        │
        │        ▼
        │   [_ShiftEditorSheet bottom sheet]
        │        ├─ Tên ca
        │        ├─ Giờ check-in / check-out (TimePicker)
        │        ├─ Checkbox ca qua đêm (+1 ngày)
        │        ├─ Tần suất: [Hàng tuần | Hàng ngày | Tuỳ chỉnh]
        │        └─ Chọn ngày áp dụng (T2–CN, ẩn khi "Hàng ngày")
        │                 → Confirm → WorkShiftEntry
        │
        ├─ [CA LÀM VIỆC] - danh sách ca, mỗi ca hiện:
        │       • Tên + giờ checkin/out
        │       • 7 chip ngày (highlight ngày đang áp dụng)
        │       • Badge tần suất
        │       • Nút Edit / Delete
        │
        ├─ [TÓM TẮT LỊCH TUẦN] - tự render:
        │       T2 → [Ca A 08:00–17:30] [Ca B 22:00–06:00+1]
        │       T3 → [Ca A 08:00–17:30]
        │       T7 → Không có ca
        │       CN → Không có ca
        │
        ├─ [NHẮC NHỞ & CẢNH BÁO]
        │
        └─ Lưu → WorkScheduleModel.toJsonString()
                        → SharedPreferences 'work_schedule'
                        → (API) POST /api/v1/work-schedules
```

---

## 3. Cấu trúc JSON payload (v2)

```jsonc
{
  "employee_id":   "EMP001",
  "employee_name": "Ngô Nhật Cường",
  "department":    "IT Technical Development",
  "schedule_id":   "SCH_1711432800000",
  "schedule_name": "Lịch làm việc",

  "shifts": [
    {
      "id":              "shift_1",
      "name":            "Ca ngày",
      "check_in_time":   "08:00",
      "check_out_time":  "17:30",
      "crosses_midnight": false,
      "applied_days":    [1, 2, 3, 4, 5],   // T2–T6
      "repeat_type":     "weekly"
    },
    {
      "id":              "shift_2",
      "name":            "Ca đêm",
      "check_in_time":   "22:00",
      "check_out_time":  "06:00",
      "crosses_midnight": true,
      "applied_days":    [5, 6],             // T6 + T7
      "repeat_type":     "weekly"
    },
    {
      "id":              "shift_3",
      "name":            "Trực 24/7",
      "check_in_time":   "07:00",
      "check_out_time":  "07:00",
      "crosses_midnight": true,
      "applied_days":    [],                 // empty = mọi ngày
      "repeat_type":     "daily"
    }
  ],

  "reminder": {
    "check_in_enabled":          true,
    "check_in_minutes_before":   15,
    "check_out_enabled":         false,
    "check_out_minutes_before":  10,
    "late_alert_enabled":        true,
    "overtime_alert_enabled":    false
  },

  "created_at": "2026-03-26T08:00:00.000Z",
  "updated_at": "2026-03-26T08:00:00.000Z"
}
```

---

## 4. Mô tả fields key

| Field | Kiểu | Mô tả |
|-------|------|-------|
| `shifts[].applied_days` | `List<int>` | ISO weekday 1=T2…7=CN. **Empty = mọi ngày** khi `repeat_type=daily` |
| `shifts[].repeat_type` | `string` | `daily` / `weekly` / `custom` |
| `shifts[].crosses_midnight` | `bool` | Checkout thuộc ngày D+1 |

### Helper (server side)
```
shiftsForDay(isoWeekday) = shifts.where(
  s.repeat_type == 'daily' OR s.applied_days.contains(isoWeekday)
).sortBy(check_in_time)
```

---

## 5. Logic server

| Scenario | Điều kiện | Hành động |
|----------|-----------|-----------|
| Nhắc check-in | `check_in_enabled=true` | Bắn noti tại `check_in_time - X phút` cho từng ca của ngày đó |
| Nhắc check-out | `check_out_enabled=true` | Bắn noti tại `check_out_time - X phút` |
| Cảnh báo trễ | `late_alert_enabled=true` | Nếu không có check-in sau `check_in_time + 5'` → noti cho NV + quản lý |
| Cảnh báo tăng ca | `overtime_alert_enabled=true` | Nếu không có check-out sau `check_out_time + 15'` → noti cho NV |
| Ca đêm | `crosses_midnight=true` | Tính checkout = `check_out_time` của ngày D+1 |
| Nhiều ca/ngày | — | Server gọi `shiftsForDay(day)` để lấy toàn bộ ca, xử lý từng ca độc lập |

---

## 6. Files

| File | Mô tả |
|------|-------|
| `lib/data/models/work_schedule/work_schedule_model.dart` | `WorkShiftEntry` + `WorkScheduleModel` + `WorkScheduleReminder` |
| `lib/presentation/pages/work_schedule/work_schedule_setup_page.dart` | UI + Bottom sheet editor |
| `lib/l10n/vi.json` / `en.json` | i18n keys `ws_*` |
| `lib/presentation/pages/home/widgets/home_quick_menu_widget.dart` | Entry point navigation |
