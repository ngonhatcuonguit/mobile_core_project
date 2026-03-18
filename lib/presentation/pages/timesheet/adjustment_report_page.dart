import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Các loại báo cáo điều chỉnh
enum AdjustmentType {
  congTacTrongNgay('Công tác trong ngày'),
  daoCa('Đảo ca'),
  caDem('Ca Đêm'),
  quetVanTayKhongGhiNhan('Quét vân tay nhưng MCC không ghi nhận'),
  quenQuetVanTay('Quên quét vân tay (Forgotten)'),
  chuaLayVanTay('Chưa lấy vân tay (Not yet)'),
  khac('Khác (Other)');

  final String label;
  const AdjustmentType(this.label);
}

class AdjustmentReportPage extends StatefulWidget {
  /// Ngày user đang chọn trong bảng timesheet (có thể null → dùng hôm nay)
  final DateTime? initialDate;

  const AdjustmentReportPage({super.key, this.initialDate});

  @override
  State<AdjustmentReportPage> createState() => _AdjustmentReportPageState();
}

class _AdjustmentReportPageState extends State<AdjustmentReportPage> {
  late DateTime _selectedDate;
  AdjustmentType? _selectedType;
  final TextEditingController _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

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

  // ── Chọn ngày ────────────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
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
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // ── Gửi báo cáo ──────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null) {
      _showSnack('Vui lòng chọn loại báo cáo');
      return;
    }

    setState(() => _isSubmitting = true);

    // TODO: Tích hợp API gửi báo cáo thực tế
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    _showSuccessDialog();
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

  void _showSuccessDialog() {
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
                color: Colors.green.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline,
                  color: Colors.green, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'Gửi thành công!',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _textColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Báo cáo điều chỉnh của bạn đã được gửi lên hệ thống.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _labelColor),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // close dialog
                Navigator.of(context).pop(); // close page
              },
              child: const Text('Đóng'),
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
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: _textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Báo cáo điều chỉnh',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _textColor,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: _borderColor),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header info ──────────────────────────────────────────────
              _buildInfoBanner(),
              const SizedBox(height: 16),

              // ── Chọn ngày ────────────────────────────────────────────────
              _buildSectionLabel('Ngày điều chỉnh', Icons.calendar_today_rounded),
              const SizedBox(height: 8),
              _buildDatePicker(),
              const SizedBox(height: 20),

              // ── Loại báo cáo ─────────────────────────────────────────────
              _buildSectionLabel('Loại báo cáo', Icons.category_rounded),
              const SizedBox(height: 8),
              _buildTypeDropdown(),
              const SizedBox(height: 20),

              // ── Ghi chú thêm ─────────────────────────────────────────────
              _buildSectionLabel('Thông tin thêm', Icons.notes_rounded),
              const SizedBox(height: 8),
              _buildNoteField(),
              const SizedBox(height: 32),

              // ── Nút gửi ──────────────────────────────────────────────────
              _buildSubmitButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
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

  // ── Section label ─────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 15, color: _primary),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _textColor,
          ),
        ),
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _primaryLight.withOpacity(_isDark ? 0.15 : 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.calendar_month_rounded,
                  color: _primary, size: 18),
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
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _textColor,
                    ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButton<AdjustmentType>(
            value: _selectedType,
            isExpanded: true,
            hint: Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Text(
                'Chọn loại báo cáo...',
                style: TextStyle(fontSize: 13, color: _labelColor),
              ),
            ),
            icon: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(Icons.keyboard_arrow_down_rounded,
                  color: _primary, size: 22),
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
                    fontSize: 13,
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
                      fontSize: 13,
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

  // ── Text field ghi chú ────────────────────────────────────────────────────
  Widget _buildNoteField() {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
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
              hintText:
                  'Nhập thêm thông tin chi tiết (thời gian, lý do cụ thể...)',
              hintStyle: TextStyle(fontSize: 12, color: _labelColor),
              filled: true,
              fillColor: _cardColor,
              // Tắt toàn bộ border nội tại — viền được handle bởi Container bên ngoài
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
              // Đẩy error text ra ngoài để không phá layout viền bo
              errorStyle: TextStyle(fontSize: 11, color: Colors.red[400]),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Vui lòng nhập thêm thông tin';
              }
              if (v.trim().length < 5) {
                return 'Thông tin quá ngắn (tối thiểu 5 ký tự)';
              }
              return null;
            },
          ),
        ),
      ),
    );
  }

  // ── Nút gửi ───────────────────────────────────────────────────────────────
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _primary.withOpacity(0.5),
          elevation: 2,
          shadowColor: _primary.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Gửi báo cáo',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
      ),
    );
  }
}

