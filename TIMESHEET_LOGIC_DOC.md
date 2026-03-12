# Timesheet Logic & Data Mapping Documentation

## API Response Structure
```
{
  "status": "success",
  "data": {
    "status": "success",
    "data": {
      "YEAR": 2025,
      "MONTH": 4,
      "EMPLOYEE_ID": "34460",
      "DAY_OF_WEEK": 2,           // weekday of first day (1=Mon, 7=Sun)
      "SUM_DAY_OF_MONTH": 30,
      "TIME_SHEET_DATA": [ ... ]
    }
  }
}
```

## TIME_SHEET_DATA Item Fields
| Field        | Type     | Description                                           |
|--------------|----------|-------------------------------------------------------|
| DATE_WORKING | string   | ISO8601 date e.g. "2025-04-01T00:00:00"               |
| Wd           | double   | Working day fraction (1.0 = full day, 0.5 = half day) |
| NUM_HOUR     | double?  | Actual scanned hours                                  |
| NgG          | double?  | Làm ngoài giờ                                         |
| NgG_2        | double?  | Làm ngoài giờ  loại 2                                 |
| NL           | double?  | Nghỉ lễ                                               |
| BL           | double?  | Bù lễ                                                 |
| B            | double?  | Bệnh                                                  |
| P            | double?  | Phép năm                                              |
| Pr           | double?  | Phép riêng                                            |
| Ro           | double?  | Nghỉ không lương                                      |
| SickLeave    | double?  | Nghỉ ốm (other)                                       |
| N            | double?  | Nghỉ không phép                                       |
| TN           | double?  | Tai nạn                                               |
| HT           | double?  | Nghỉ hàng tuần (weekend)                              |
| Ca3          | double?  | Ca 3                                                  |
| CDC          | double?  | Cách điều chỉnh                                       |
| O            | double?  | Nghỉ ốm                                               |
| TS           | double?  | Thai sản loại 2                                       |
| IS_DEFAULT   | bool     | Dữ liệu mặc định                                      |
| CheckingPoint| List     | Danh sách chấm công                                   |

## CheckingPoint Fields
| Field        | Type     | Description |
|--------------|----------|-------------|
| ID           | int      | ID bản ghi |
| WORKING_DATE | string   | ISO8601 date |
| EMPLOYEE_ID  | string   | Mã nhân viên |
| TIME_IN      | string?  | Giờ vào (ISO8601) |
| TIME_OUT     | string?  | Giờ ra (ISO8601) |
| WD           | double   | Số giờ làm trong ngày |
| OT           | double   | Số giờ tăng ca |

## Display Logic for Calendar Cell

### Step 1: Calculate display hours
```
displayHours = Wd * 8
```
(1 ngày chuẩn = 8 giờ, Wd=1.0 → 8h, Wd=0.5 → 4h, nếu không có Wd hoặc Wd =0.0 thì hãy check các loại nghỉ phép hoặc có thể thiếu công ngày đó)

### Step 2: Build leave symbols list
Collect all leave fields with value > 0:
- NL → "NL" (Nghỉ lễ)
- HT → "HT" (Nghỉ hàng tuần)
- P  → "P"  (Phép năm)
- Pr → "Pr" (Phép riêng)
- Ro → "Ro" (Nghỉ không lương)
- SickLeave → "SL" (Nghỉ ốm orther)
- B  → "B"  (Bệnh)
- BL → "BL" (Bù lễ)
- N  → "N"  (Không phép)
- TN → "TN" (Tai nạn)
- Ca3→ "Ca3"(Ca 3)
- CDC→ "CDC"
- O  → "O" (nghỉ ốm)
- TS → "TS" (Thai sản)

### Step 3: Build cell content string
Case A: Pure working day (all leave fields = null/0, Wd > 0)
  → Display: "{Wd*8}h" e.g. "8h" or "9.5h" (use NUM_HOUR if available)
  → Color: GREEN (full day ≥ 8h), ORANGE (< 8h)

Case B: Pure leave/holiday (Wd = 0, has leave symbol)
  → Display: the leave symbol e.g. "HT", "NL", "P"
  → Color: RED for HT/NL, ORANGE for P/Pr, GREY for Ro/N, BLUE for BL/TN

Case C: Mixed (Wd > 0 AND has leave)
  → hours part: displayHours (Wd*8) formatted (drop .0 if whole number)
  → leave part: leaveValue+Symbol e.g. "0.5P"
  → NgG/NgG_2 suffix: "(NgG_val)(NgG_2_val)" only if > 0
  → Full string: "4,0.5P(3.2)(0.5)"
  → Color: ORANGE

Case D: No data / future day
  → Display: empty
  → Color: transparent

### Step 4: Tooltip on tap
Show full detail string even if truncated on cell.
Show TIME_IN and TIME_OUT from best CheckingPoint:
  - Pick CheckingPoint with highest WD value (most complete record)
  - TIME_IN format: HH:mm
  - TIME_OUT format: HH:mm (or "--:--" if null)

### Step 5: Color rules
- FULL_GREEN: Wd >= 1.0, no leave, NUM_HOUR >= 8 → Color(0xFF42C83C) light bg
- PART_ORANGE: Wd > 0, Wd < 1.0, OR has leave symbols → Color(0xFFFF9800) light bg
- HOLIDAY_RED: HT == 1.0 and Wd == 0 → Color(0xFFEF4444) light bg
- LEAVE_RED: NL == 1.0 and Wd == 0 → Color(0xFFEF4444) light bg
- ABSENCE: Ro/N/etc → Color(0xFF9E9E9E) light bg
- SELECTED: Color(0xFF42C83C) solid bg, white text

## Summary Cards Logic
- Ngày công: count of entries where Wd > 0 → show as integer
- Phép năm: count of entries where P > 0 → show as integer  
- Tăng ca: sum of NUM_HOUR_EXTRA where not null → show as "Xh"

## Detail Panel (bottom) when day selected
Show:
- Date: DD-MM-YYYY
- Status badge: "Đủ công" (Wd >= 1.0) / "Nửa ngày" (0 < Wd < 1.0) / "Nghỉ" (Wd == 0)
- Giờ vào (In): TIME_IN from best CheckingPoint (HH:mm)
- Giờ ra (Out): TIME_OUT from best CheckingPoint (HH:mm)
- Phép năm (P): value
- Nghỉ lễ (NL): value  
- Tổng ca (NgG_2): value
- Ngày làm việc (Wd): value

## Field Name Mapping (API → Entity)
| API field   | Entity field  | Note |
|-------------|---------------|------|
| NgG         | ngG           | |
| NgG_2       | ngG2          | NEW field |
| NL          | nL            | |
| BL          | bL            | NEW |
| B           | b             | NEW |
| P           | p             | |
| Pr          | pr            | |
| Ro          | ro            | |
| SickLeave   | sickLeave     | NEW |
| N           | n             | NEW |
| TN          | tN            | NEW |
| HT          | hT            | |
| Ca3         | ca3           | NEW |
| CDC         | cDC           | NEW |
| O           | o             | NEW |
| TS          | tS            | NEW |
| CheckingPoint | checkingPoints | key fix |

