# Timesheet Feature Implementation

## Overview
Complete timesheet (Bảng Công) feature implemented following Clean Architecture with BLoC pattern, matching the design provided.

## Features Implemented

### 1. **Data Layer**
- ✅ `TimeSheetEntity` - Domain entity with all required fields
- ✅ `TimeSheetDataEntity` - Daily timesheet data entity
- ✅ `CheckingPointEntity` - Check-in/out data entity
- ✅ `TimesheetModel` - Data models extending entities with JSON parsing
- ✅ `TimesheetRepository` - Repository interface
- ✅ `TimesheetRepositoryImpl` - Repository implementation
- ✅ `TimesheetApiService` - API service with mock data generator

### 2. **Domain Layer**
- ✅ `GetTimesheetUseCase` - UseCase for fetching timesheet data
- ✅ `GetTimesheetParams` - Parameters for timesheet queries

### 3. **Presentation Layer**
- ✅ `RemoteTimesheetBloc` - BLoC for state management
- ✅ `RemoteTimesheetEvent` - Events (GetTimesheet, ChangeMonth, SelectDay)
- ✅ `RemoteTimesheetState` - States (Loading, Loaded, Error)
- ✅ `TimesheetPage` - Complete UI implementation

### 4. **Dependency Injection**
- ✅ All dependencies registered in `injection_container.dart`
- ✅ BLoC provider added to `main.dart`

## UI Components

### 1. **Month Selector**
- Previous/Next month navigation
- Display current month and year
- Clean, card-based design

### 2. **Summary Cards**
- **Ngày công** (Working Days) - Green indicator
- **Phép năm** (Annual Leave) - Blue indicator  
- **Tăng ca** (Overtime Hours) - Orange indicator
- Real-time calculation from timesheet data

### 3. **Calendar View**
- 7-column grid (Monday-Sunday)
- Color-coded days:
  - 🟢 **Green background** - Working days (shows hours)
  - ⚪ **Gray background** - Weekends (HT)
  - 🟡 **Yellow background** - Leave days (P)
  - 🔴 **Red text** - Holidays (NL), Unpaid leave (Ro)
- **Green border** - Today's date
- **Green fill** - Selected date
- Status indicators on each day

### 4. **Day Details Section**
- Displays when a day is selected
- Shows:
  - Check-in time (Giờ vào)
  - Check-out time (Giờ ra)
  - Leave days (Phép năm)
  - Holidays (Nghỉ lễ)
  - Total shifts (TỔng ca)
  - Working days (Ngày làm việc)
- Status badge: "Đủ công" (Complete) or "Vắng" (Absent)

### 5. **Action Buttons**
Four action buttons at the bottom:
- 🔧 **Xin Phép Trễ/Sớm (Bổ Sung)** - Teal
- 📝 **Báo cáo điều chỉnh Công** - Blue
- ⏰ **Xin Phép Trễ/Sớm (Dự Kiến)** - Red
- 👆 **Điểm Chỉnh Quét Nhạn** - Orange

## Mock Data Generator

The `TimesheetApiService` includes a smart mock data generator that:
- Generates data for any month/year
- Automatically detects weekends
- Simulates various attendance statuses:
  - Working days with 9-hour shifts
  - Weekends (HT status)
  - Leave days (P status)
  - Holidays (NL status)
  - Unpaid leave (Ro status)
- Creates realistic check-in/out times (7:50-8:00 AM, 5:00-5:15 PM)

## Color Scheme

Matching the design:
- **Primary Green**: `#42C83C` - Working days, selected state
- **Background**: `#F5F5F5` - Page background
- **White**: Cards and containers
- **Action Buttons**:
  - Teal: `#00BCD4`
  - Blue: `#2196F3`
  - Red: `#F44336`
  - Orange: `#FF9800`

## Navigation

The timesheet page is integrated into the bottom navigation bar:
- **Index 0**: Home Page
- **Index 1**: Timesheet Page (Bảng Công) ⭐ NEW
- **Index 2**: Daily News
- **Index 3**: Profile Page

## State Management

Using BLoC pattern with events:
- `GetTimesheet(year, month)` - Initial load
- `ChangeMonth(year, month)` - Month navigation
- `SelectDay(date)` - Day selection for details

States:
- `TimesheetLoading` - Show loading indicator
- `TimesheetLoaded` - Display data with optional selected date
- `TimesheetError` - Show error message with retry

## Auto-Selection

- Automatically selects current day when viewing current month
- Highlights today with green border
- Shows day details for selected date

## Testing

To test the feature:
1. Run the app: `flutter run`
2. Navigate to the Timesheet tab (second icon in bottom nav)
3. Test month navigation (< > arrows)
4. Tap any day to see details
5. Verify status badges and colors
6. Check data calculations in summary cards

## Files Created

### Domain Layer
- `lib/domain/entities/timesheet/timesheet_entity.dart`
- `lib/domain/repository/timesheet/timesheet_repository.dart`
- `lib/domain/usecases/get_timesheet.dart`

### Data Layer
- `lib/data/models/timesheet/timesheet_model.dart`
- `lib/data/data_sources/remote/timesheet_api_service.dart`
- `lib/data/repositories/timesheet/timesheet_repository_impl.dart`

### Presentation Layer
- `lib/presentation/bloc/timesheet/remote/remote_timesheet_event.dart`
- `lib/presentation/bloc/timesheet/remote/remote_timesheet_state.dart`
- `lib/presentation/bloc/timesheet/remote/remote_timesheet_bloc.dart`
- `lib/presentation/pages/timesheet/timesheet_page.dart`

### Modified Files
- `lib/injection_container.dart` - Added DI for timesheet
- `lib/main.dart` - Added BLoC provider
- `lib/presentation/pages/main/main_screen.dart` - Added to navigation

## Future Enhancements

Potential improvements:
1. Connect to real API endpoint
2. Implement action button functionalities
3. Add filtering and search
4. Export timesheet to PDF/Excel
5. Push notifications for missing check-ins
6. Attendance statistics dashboard
7. Multi-language support for labels

## Notes

- All code follows the existing project architecture
- Uses the same design patterns as Daily News feature
- Includes comprehensive error handling
- Responsive to different screen sizes
- Supports both light and dark themes
- Mock data allows immediate testing without backend

---
**Status**: ✅ Complete and Ready to Use
**Last Updated**: March 2, 2026

