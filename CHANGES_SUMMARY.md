# Tóm tắt các thay đổi

## 1. ✅ Tạo Shared Component cho Popup "Chức năng đang được phát triển"

**File:** `/lib/presentation/widgets/dialogs/under_development_dialog.dart`

- Tạo function `showUnderDevelopmentDialog(BuildContext context)` để hiển thị popup
- Popup hiển thị icon xây dựng, tiêu đề, và message thân thiện
- Sử dụng lại được cho tất cả các chức năng đang phát triển

---

## 2. ✅ Màn hình Home - Banner

**File:** `/lib/presentation/pages/home/widgets/home_banner_widget.dart`

### Thay đổi:
- ✅ Thêm import `under_development_dialog.dart`
- ✅ Cập nhật `_BannerCard` để nhận callback `onTap`
- ✅ Khi user click vào bất kì banner nào → show popup "Chức năng đang được phát triển"

---

## 3. ✅ Màn hình Home - Dịch vụ Phòng ban

**File:** `/lib/presentation/pages/home/widgets/home_department_widget.dart`

### Thay đổi:
- ✅ **Ẩn item BOM** bằng cách thêm `isHidden: true`
- ✅ **Tất cả item khác** (IT, HR, Logistics, Consumer, Legal) → đặt `isComingSoon: true`
- ✅ Cập nhật GridView để filter và chỉ hiển thị item không bị ẩn
- ✅ Thêm parameter `isHidden` vào class `_DepartmentItem`

---

## 4. ✅ Màn hình Home - Bottom Sheet "Tất cả chức năng"

**File:** `/lib/presentation/pages/home/widgets/home_all_menu_sheet.dart`

### Thay đổi:
- ✅ Thêm import `UserInfoPage` từ `profile/user_info_page.dart`
- ✅ Item **"Thông tin"** → khi click, đóng bottom sheet và navigate tới `UserInfoPage`

---

## 5. ✅ Màn hình "Yêu cầu Nghỉ phép Mới"

**File:** `/lib/presentation/pages/leave_request/leave_request_page.dart`

### Thay đổi:
- ✅ Thêm import `under_development_dialog.dart`
- ✅ Button **"Lưu nháp"** → show popup "Chức năng đang được phát triển"
- ✅ Button **"Gửi yêu cầu"** → show popup "Chức năng đang được phát triển"

---

## 6. ✅ Màn hình Dịch vụ (Service)

**File:** `/lib/presentation/pages/service/service_page.dart`

### Thay đổi:
- ✅ Thêm import `TimesheetPage` từ `timesheet/timesheet_page.dart`
- ✅ Item **"Bảng công"** (`service_timesheet`) → navigate tới `TimesheetPage`

---

## Các Lợi ích:

✅ **Shared Component:** Popup "Chức năng đang được phát triển" có thể tái sử dụng ở bất cứ đâu  
✅ **Nhất quán UI/UX:** Tất cả popup dùng cùng style và message  
✅ **Dễ bảo trì:** Nếu muốn thay đổi popup, chỉ cần sửa 1 file duy nhất  
✅ **Lazy loading:** Các trang đang phát triển sẽ hiển thị thông báo thay vì crash  
✅ **Navigation đúng:** "Bảng công" và "Thông tin" giờ đã dẫn tới trang đúng  

---

## Hướng dẫn Kiểm tra:

1. **Home banner:** Click vào bất kì banner nào → popup "Chức năng đang được phát triển"
2. **Home department:** Kiểm tra BOM bị ẩn, các item khác hiển thị "Sắp ra mắt"
3. **Home all menu sheet:** Click "Thông tin" → navigate tới trang UserInfo
4. **Leave request:** Click "Lưu nháp" hoặc "Gửi yêu cầu" → popup "Chức năng đang được phát triển"
5. **Service:** Click "Bảng công" → navigate tới Timesheet


