import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_core_project/data/models/timesheet/adjustment_report_model.dart';
import 'package:flutter_core_project/domain/usecases/submit_adjustment_report_usecase.dart';
import 'package:flutter_core_project/injection_container.dart';
import 'package:flutter_core_project/services/auth_service.dart';

/// Loại báo cáo điều chỉnh — code khớp với ReasonCode trên server
enum AdjustmentType {
  dayBusiness('DAY_BUSINESS', 'Công tác trong ngày'),
  shiftSwapping('SHIFT_SWAPPING', 'Đảo ca'),
  nightShift('NIGHT_SHIFT', 'Ca Đêm'),
  mccError('MCC_ERROR', 'Quét vân tay nhưng MCC không ghi nhận'),
  forgotten('FORGOTEN', 'Quên quét vân tay (Forgoten)'),
  notYet('NOT_YET', 'Chưa lấy vân tay (Not yet)'),
  other('OTHER', 'Khác (Other)');

  final String code;
  final String label;
  const AdjustmentType(this.code, this.label);
}

class AdjustmentReportPage extends StatefulWidget {
  final DateTime? initialDate;
  const AdjustmentReportPage({super.key, this.initialDate});

  @override
  State<AdjustmentReportPage> createState() => _AdjustmentReportPageState();
}

class _AdjustmentReportPageState extends State<AdjustmentReportPage> {
  late DateTime _selectedDate;
  AdjustmentType? _selectedType;
  DateTime? _timeIn;
  DateTime? _timeOut;
  final TextEditingController _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // Format hiển thị TimeIn/TimeOut
  static final _timeFmt = DateFormat('HH:mm');
  static final _dateFmt = DateFormat('dd/MM/yyyy');
  static final _dateTimeFmt = DateFormat("yyyy-MM-dd'T'HH:mm:ss");

  /// Button chỉ enable khi đã chọn đủ 2 trường bắt buộc: ngày + loại báo cáo
  bool get _canSubmit => _selectedType != null && !_isSubmitting;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // ── Màu chủ đạo ─────────────────────────────────────────────────────────
  static const _primary = Color(0xFF2196F3);
  static const _primaryLight = Color(0xFFE3F2FD);

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bgColor => _isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF5F5F5);
  Color get _cardColor => _isDark ? const Color(0xFF2A2A2A) : Colors.white;
  Color get _labelColor => _isDark ? Colors.grey[400]! : Colors.grey[600]!;
  Color get _textColor => _isDark ? Colors.white : const Color(0xFF1A1A1A);
  Color get _borderColor => _isDark ? const Color(0xFF3A3A3A) : Colors.grey[300]!;

  // ── Khi đổi ngày → reset TimeIn/TimeOut để user chọn lại ──────────────
  void _onDateChanged(DateTime newDate) {
    // Chỉ reset khi ngày thực sự thay đổi
    if (newDate.year == _selectedDate.year &&
        newDate.month == _selectedDate.month &&
        newDate.day == _selectedDate.day) return;

    setState(() {
      _selectedDate = newDate;
      // Reset giờ vào/ra để user chọn lại theo ngày mới
      _timeIn = null;
      _timeOut = null;
    });
  }

  // ── Chọn ngày ────────────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime.now(),
      locale: const Locale('vi'),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: _primary,
            brightness: _isDark ? Brightness.dark : Brightness.light,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) _onDateChanged(picked);
  }

  // ── Chọn giờ (TimeIn hoặc TimeOut) ──────────────────────────────────────
  Future<void> _pickTime({required bool isTimeIn}) async {
    final initial = isTimeIn
        ? (_timeIn != null ? TimeOfDay(hour: _timeIn!.hour, minute: _timeIn!.minute) : TimeOfDay.now())
        : (_timeOut != null ? TimeOfDay(hour: _timeOut!.hour, minute: _timeOut!.minute) : TimeOfDay.now());

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: _primary,
            brightness: _isDark ? Brightness.dark : Brightness.light,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      final dt = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day,
        picked.hour, picked.minute,
      );
      setState(() {
        if (isTimeIn) _timeIn = dt;
        else _timeOut = dt;
      });
    }
  }

  // ── Gửi báo cáo ──────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_canSubmit) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final employeeId = await AuthService.getEmployeeId() ?? '';

      final request = AdjustmentReportRequest.fromFields(
        workingDate: _selectedDate,
        employeeId: employeeId,
        timeIn: _timeIn,
        timeOut: _timeOut,
        reason: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        reasonCode: _selectedType!.code,
      );

      final useCase = sl<SubmitAdjustmentReportUseCase>();
      final message = await useCase(request);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      _showResultDialog(success: true, message: message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      final msg = e.toString().replaceAll('DioException: ', '').replaceAll('Exception: ', '');
      _showResultDialog(success: false, message: msg);
    }
  }

  /// Reset toàn bộ form về trạng thái ban đầu
  void _clearForm() {
    setState(() {
      _selectedDate = DateTime.now();
      _selectedType = null;
      _timeIn = null;
      _timeOut = null;
      _noteController.clear();
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.orange[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showResultDialog({required bool success, required String message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: _cardColor,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: (success ? Colors.green : Colors.red).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                success ? Icons.check_circle_outline : Icons.error_outline_rounded,
                color: success ? Colors.green : Colors.red[400],
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              success ? 'Thành công!' : 'Thất bại',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: success ? Colors.green : Colors.red[400],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _labelColor, height: 1.4),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: success ? Colors.green : _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // đóng dialog
                if (success) {
                  _clearForm(); // clear form, disable button
                }
              },
              child: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Báo cáo điều chỉnh',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textColor)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: _borderColor),
        ),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoBanner(),
                  const SizedBox(height: 16),

                  // ── Chọn ngày ────────────────────────────────────────────────
                  _buildSectionLabel('Ngày điều chỉnh', Icons.calendar_today_rounded),
                  const SizedBox(height: 8),
                  _buildDatePicker(),
                  const SizedBox(height: 20),

                  // ── TimeIn / TimeOut ─────────────────────────────────────────
                  _buildSectionLabel('Giờ vào / Giờ ra', Icons.access_time_rounded),
                  const SizedBox(height: 8),
                  _buildTimeRow(),
                  const SizedBox(height: 20),

                  // ── Loại báo cáo ─────────────────────────────────────────────
                  _buildSectionLabel('Loại báo cáo *', Icons.category_rounded),
                  const SizedBox(height: 8),
                  _buildTypeDropdown(),
                  const SizedBox(height: 20),

                  // ── Lý do điều chỉnh ─────────────────────────────────────────
                  _buildSectionLabel('Lý do điều chỉnh', Icons.notes_rounded),
                  const SizedBox(height: 8),
                  _buildNoteField(),
                  const SizedBox(height: 32),

                  _buildSubmitButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── Full-screen loading overlay ──────────────────────────────────
          if (_isSubmitting)
            Container(
              color: Colors.black.withOpacity(0.45),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        strokeWidth: 3,
                        color: _primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Đang gửi báo cáo...',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Banner thông tin ──────────────────────────────────────────────────────
  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _primary.withOpacity(_isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: _primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Điền đầy đủ thông tin và gửi yêu cầu điều chỉnh công đến bộ phận nhân sự.',
              style: TextStyle(
                  fontSize: 12,
                  color: _isDark ? Colors.blue[200] : _primary,
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 15, color: _primary),
        const SizedBox(width: 6),
        Text(text,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textColor)),
      ],
    );
  }

  // ── Date picker tile ──────────────────────────────────────────────────────
  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _borderColor),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _primaryLight.withOpacity(_isDark ? 0.15 : 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.calendar_month_rounded, color: _primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ngày được chọn',
                      style: TextStyle(fontSize: 11, color: _labelColor)),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('dd / MM / yyyy').format(_selectedDate),
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _textColor),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit_calendar_rounded, size: 18, color: _primary),
          ],
        ),
      ),
    );
  }

  // ── TimeIn / TimeOut row ──────────────────────────────────────────────────
  Widget _buildTimeRow() {
    return Row(
      children: [
        Expanded(child: _buildTimeTile(isTimeIn: true)),
        const SizedBox(width: 10),
        Expanded(child: _buildTimeTile(isTimeIn: false)),
      ],
    );
  }

  Widget _buildTimeTile({required bool isTimeIn}) {
    final value = isTimeIn ? _timeIn : _timeOut;
    final label = isTimeIn ? 'Giờ vào' : 'Giờ ra';

    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: value != null ? _primary.withOpacity(0.5) : _borderColor,
            width: value != null ? 1.4 : 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Column(
        children: [
          // Tap vùng chọn giờ
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            onTap: () => _pickTime(isTimeIn: isTimeIn),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _primaryLight.withOpacity(_isDark ? 0.15 : 1),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(
                      isTimeIn ? Icons.login_rounded : Icons.logout_rounded,
                      color: _primary, size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: TextStyle(fontSize: 11, color: _labelColor)),
                        const SizedBox(height: 2),
                        value != null
                            ? Text(
                                '${_timeFmt.format(value)} - ${_dateFmt.format(value)}',
                                style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700, color: _textColor,
                                ),
                              )
                            : Text('Chưa chọn',
                                style: TextStyle(fontSize: 13, color: _labelColor)),
                      ],
                    ),
                  ),
                  Icon(Icons.access_time_filled_rounded, size: 16, color: _primary),
                ],
              ),
            ),
          ),
          // Nút xoá (chỉ hiện khi đã có giá trị)
          if (value != null) ...[
            Divider(height: 1, color: _borderColor),
            InkWell(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
              onTap: () => setState(() {
                if (isTimeIn) _timeIn = null;
                else _timeOut = null;
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.close_rounded, size: 14, color: Colors.red[400]),
                    const SizedBox(width: 4),
                    Text('Xoá', style: TextStyle(fontSize: 12, color: Colors.red[400])),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Dropdown loại báo cáo ─────────────────────────────────────────────────
  Widget _buildTypeDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _selectedType == null ? _borderColor : _primary.withOpacity(0.5),
          width: _selectedType == null ? 1 : 1.4,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButton<AdjustmentType>(
            value: _selectedType,
            isExpanded: true,
            hint: Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Text('Chọn loại báo cáo...',
                  style: TextStyle(fontSize: 13, color: _labelColor)),
            ),
            icon: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(Icons.keyboard_arrow_down_rounded, color: _primary, size: 22),
            ),
            dropdownColor: _cardColor,
            borderRadius: BorderRadius.circular(10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            items: AdjustmentType.values.map((type) {
              return DropdownMenuItem<AdjustmentType>(
                value: type,
                child: Text(
                  type.label,
                  style: TextStyle(
                    fontSize: 15,
                    color: _textColor,
                    fontWeight: _selectedType == type
                        ? FontWeight.w700
                        : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedType = val),
            selectedItemBuilder: (_) => AdjustmentType.values.map((type) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Text(
                    type.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _primary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ── Text field lý do ──────────────────────────────────────────────────────
  Widget _buildNoteField() {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _borderColor),
          ),
          child: TextFormField(
            controller: _noteController,
            maxLines: 5,
            minLines: 4,
            style: TextStyle(fontSize: 13, color: _textColor, height: 1.5),
            decoration: InputDecoration(
              hintText: 'Nhập lý do điều chỉnh (thời gian, lý do cụ thể...)',
              hintStyle: TextStyle(fontSize: 12, color: _labelColor),
              filled: true,
              fillColor: _cardColor,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
              errorStyle: TextStyle(fontSize: 11, color: Colors.red[400]),
            ),
          ),
        ),
      ),
    );
  }

  // ── Nút gửi ───────────────────────────────────────────────────────────────
  Widget _buildSubmitButton() {
    final enabled = _canSubmit;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: enabled
            ? [BoxShadow(color: _primary.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))]
            : [],
      ),
      child: ElevatedButton(
        onPressed: enabled ? _submit : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? _primary : (_isDark ? const Color(0xFF3A3A3A) : Colors.grey[300]),
          foregroundColor: enabled ? Colors.white : (_isDark ? Colors.grey[600] : Colors.grey[500]),
          disabledBackgroundColor: _isDark ? const Color(0xFF3A3A3A) : Colors.grey[300],
          disabledForegroundColor: _isDark ? Colors.grey[600] : Colors.grey[500],
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              enabled ? Icons.send_rounded : Icons.lock_outline_rounded,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              enabled ? 'Gửi báo cáo' : 'Vui lòng chọn loại báo cáo',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

