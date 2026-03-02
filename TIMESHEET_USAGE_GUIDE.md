# Quick Start Guide - Timesheet Feature (Bảng Công)

## How to Use

### 1. Accessing the Timesheet
- Launch the app
- Tap the **second icon** (calendar/delivery icon) in the bottom navigation bar
- The timesheet page will load with the current month's data

### 2. Navigation

#### Change Month
- Tap **< (left arrow)** to view previous month
- Tap **> (right arrow)** to view next month
- Current month and year displayed in the center

#### View Day Details
- Tap any day in the calendar
- Selected day will be highlighted in green
- Day details appear below the calendar showing:
  - Check-in and check-out times
  - Leave status
  - Working hours
  - Holiday information

### 3. Understanding the Calendar

#### Color Coding:
- **Green background with hours** (e.g., "8", "9") = Working day with hours worked
- **Gray with "HT"** = Weekend/Holiday (Nghỉ HT)
- **Yellow with "P"** = Annual leave (Phép năm)
- **Red "NL"** = National holiday (Nghỉ lễ)
- **Red "Ro"** = Unpaid leave (Ro)
- **Green border** = Today's date
- **Green fill** = Currently selected day

#### Summary Cards (Top):
1. **Ngày công** (Working Days) - Total days worked
2. **Phép năm** (Annual Leave) - Days of leave taken
3. **Tăng ca** (Overtime) - Total overtime hours

### 4. Action Buttons

Four buttons at the bottom for different actions:
- **Teal Button**: Request late/early leave (補充 - Supplementary)
- **Blue Button**: Report work adjustment
- **Red Button**: Request late/early leave (預計 - Planned)
- **Orange Button**: Fingerprint adjustment

*Note: Action buttons are placeholders. Functionality can be implemented as needed.*

## Example Scenarios

### Scenario 1: Check Attendance for Current Month
1. Open app → Tap Timesheet tab
2. Calendar shows current month with today highlighted
3. Review summary cards at top for overview
4. Tap specific days to see check-in/out details

### Scenario 2: Review Previous Month
1. In Timesheet page
2. Tap left arrow to go to previous month
3. Review attendance records
4. Tap any day for detailed information

### Scenario 3: Check Specific Day Details
1. Navigate to desired month
2. Tap the day you want to check
3. View detailed information:
   - Arrival time
   - Departure time
   - Total hours worked
   - Leave status
   - Attendance status (Complete/Absent)

## Data Fields Explained

### In Day Details Section:

- **Giờ vào (In)**: Check-in time (e.g., 07:59)
- **Giờ ra (Out)**: Check-out time (e.g., 17:16)
- **Phép năm (P)**: Annual leave days used (0 or 1)
- **Nghỉ lễ (NL)**: Holiday/Public holiday (0 or 1)
- **TỔng ca (NgG_2)**: Total shifts count
- **Ngày làm việc (Wd)**: Working days (0 or 1)

### Status Badge:
- **Đủ công** (green) = Full attendance
- **Vắng** (gray) = Absent

## Tips

1. **Current Day Auto-Select**: When viewing the current month, today's date is automatically selected
2. **Month Navigation**: You can navigate to any month to view historical or future timesheet data
3. **Quick Overview**: Use summary cards for a quick snapshot of your monthly attendance
4. **Detailed View**: Tap any day for complete check-in/out information

## Troubleshooting

### Calendar not loading?
- Check your internet connection
- Pull down to refresh (if implemented)
- Restart the app

### Data looks incorrect?
- Currently using mock data for demonstration
- Real data will be loaded once connected to actual API

### Selected day not showing details?
- Make sure the day has data (not a future date or empty day)
- Try selecting a different day with visible status

## Mock Data Information

The current implementation uses **mock data** which includes:
- Realistic check-in/out times (typically 7:50-8:00 AM and 5:00-5:15 PM)
- Various attendance statuses (working days, holidays, leave)
- Automatic weekend detection
- Sample data for any month/year you navigate to

**Note**: Replace the mock data service with real API integration for production use.

---

## Developer Notes

To connect to real API:
1. Update `TimesheetApiService` to make real HTTP calls
2. Configure API endpoint in constants
3. Update authentication/authorization as needed
4. Handle pagination if required
5. Add proper error handling for network issues

Current Architecture:
```
UI (TimesheetPage) 
  ↓
BLoC (RemoteTimesheetBloc)
  ↓
UseCase (GetTimesheetUseCase)
  ↓
Repository (TimesheetRepositoryImpl)
  ↓
API Service (TimesheetApiService)
```

Ready for production with minimal changes!

