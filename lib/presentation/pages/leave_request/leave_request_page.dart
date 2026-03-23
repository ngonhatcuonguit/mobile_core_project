import 'package:flutter/material.dart';
import 'package:flutter_core_project/common/helpers/is_dark_mode.dart';

class LeaveRequestPage extends StatefulWidget {
  const LeaveRequestPage({super.key});

  @override
  State<LeaveRequestPage> createState() => _LeaveRequestPageState();
}

class _LeaveRequestPageState extends State<LeaveRequestPage> {
  String? _selectedLeaveType = 'Phép năm (Annual Leave)';
  DateTime? _fromDate;
  DateTime? _toDate;
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _handoverPersonController =
      TextEditingController();
  final TextEditingController _handoverContentController =
      TextEditingController();

  final List<String> _leaveTypes = [
    'Phép năm (Annual Leave)',
    'Nghỉ ốm (Sick Leave)',
    'Nghỉ không lương (Unpaid Leave)',
    'Nghỉ lễ (Public Holiday)',
    'Nghỉ thai sản (Maternity Leave)',
  ];

  int get _totalDays {
    if (_fromDate == null || _toDate == null) return 0;
    if (_toDate!.isBefore(_fromDate!)) return 0;
    int count = 0;
    DateTime d = _fromDate!;
    while (!d.isAfter(_toDate!)) {
      if (d.weekday != DateTime.saturday && d.weekday != DateTime.sunday) {
        count++;
      }
      d = d.add(const Duration(days: 1));
    }
    return count;
  }

  Future<void> _pickDate(bool isFrom) async {
    final initial = isFrom
        ? (_fromDate ?? DateTime.now())
        : (_toDate ?? _fromDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        final isDark = context.isDarkMode;
        return Theme(
          data: isDark ? ThemeData.dark() : ThemeData.light(),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
          if (_toDate != null && _toDate!.isBefore(picked)) {
            _toDate = picked;
          }
        } else {
          _toDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'mm/dd/yyyy';
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _handoverPersonController.dispose();
    _handoverContentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    // Theme colors
    final scaffoldBg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5);
    final cardBg = isDark ? const Color(0xFF242424) : Colors.white;
    final inputBg = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final borderColor = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE5E7EB);
    final labelColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final sectionTitleColor = isDark ? Colors.white : const Color(0xFF111827);
    final subtitleColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Inline TopBar ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2C2C2C)
                              : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withOpacity(isDark ? 0.3 : 0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                          color: textColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Yêu Cầu Nghỉ Phép Mới',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Employee Info Card ───────────────────────────────
              _buildEmployeeCard(isDark, cardBg, subtitleColor),
              const SizedBox(height: 16),

              // ─── Thông tin nghỉ Section ───────────────────────────
              _buildLeaveInfoSection(
                isDark,
                cardBg,
                inputBg,
                borderColor,
                labelColor,
                textColor,
                sectionTitleColor,
                subtitleColor,
              ),
              const SizedBox(height: 16),

              // ─── Bàn giao công việc Section ───────────────────────
              _buildHandoverSection(
                isDark,
                cardBg,
                inputBg,
                borderColor,
                labelColor,
                textColor,
                sectionTitleColor,
              ),
              const SizedBox(height: 24),

              // ─── Footer Buttons (cuộn theo trang) ─────────────────
              _buildFooterButtons(isDark),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── Employee Card ──────────────────────────────────────────────────────────
  Widget _buildEmployeeCard(bool isDark, Color cardBg, Color subtitleColor) {
    if (isDark) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF242424),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2F4A2F), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + Name row
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A3A1A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: Color(0xFF42C83C),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ngô Nhật Cường',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'IT Technical Development',
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'PHÉP KHẢ DỤNG',
              style: TextStyle(
                color: subtitleColor,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  '1.14',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'ngày',
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A3A1A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF42C83C).withOpacity(0.4),
                    ),
                  ),
                  child: const Text(
                    'Năm 2025',
                    style: TextStyle(
                      color: Color(0xFF42C83C),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      // Light mode card: gradient blue
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ngô Nhật Cường',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'IT Technical Development',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'PHÉP KHẢ DỤNG',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  '1.14',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text(
                    'ngày',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.4)),
                  ),
                  child: const Text(
                    'Năm 2025',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  // ── Leave Info Section ─────────────────────────────────────────────────────
  Widget _buildLeaveInfoSection(
    bool isDark,
    Color cardBg,
    Color inputBg,
    Color borderColor,
    Color labelColor,
    Color textColor,
    Color sectionTitleColor,
    Color subtitleColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: isDark
            ? Border.all(color: const Color(0xFF2A2A2A))
            : Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                color: Color(0xFF42C83C),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'THÔNG TIN NGHỈ',
                style: TextStyle(
                  color: sectionTitleColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Loại phép
          _buildFieldLabel('Loại phép', isRequired: true, labelColor: labelColor),
          const SizedBox(height: 6),
          _buildDropdown(isDark, inputBg, borderColor, textColor),
          const SizedBox(height: 14),

          // Từ ngày / Đến ngày
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Từ ngày', isRequired: true, labelColor: labelColor),
                    const SizedBox(height: 6),
                    _buildDateField(
                      isDark,
                      inputBg,
                      borderColor,
                      textColor,
                      _formatDate(_fromDate),
                      () => _pickDate(true),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Đến ngày', isRequired: true, labelColor: labelColor),
                    const SizedBox(height: 6),
                    _buildDateField(
                      isDark,
                      inputBg,
                      borderColor,
                      textColor,
                      _formatDate(_toDate),
                      () => _pickDate(false),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Tổng cộng
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: inputBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time_outlined,
                    size: 18,
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280)),
                const SizedBox(width: 8),
                Text(
                  'Tổng cộng:',
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  '$_totalDays ngày',
                  style: const TextStyle(
                    color: Color(0xFF42C83C),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Lý do nghỉ
          _buildFieldLabel('Lý do nghỉ', isRequired: true, labelColor: labelColor),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: inputBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: TextField(
              controller: _reasonController,
              maxLines: 4,
              style: TextStyle(color: textColor, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Nhập lý do chi tiết...',
                hintStyle: TextStyle(
                  color: isDark
                      ? const Color(0xFF4B5563)
                      : const Color(0xFF9CA3AF),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Handover Section ───────────────────────────────────────────────────────
  Widget _buildHandoverSection(
    bool isDark,
    Color cardBg,
    Color inputBg,
    Color borderColor,
    Color labelColor,
    Color textColor,
    Color sectionTitleColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: isDark
            ? Border.all(color: const Color(0xFF2A2A2A))
            : Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              const Icon(
                Icons.people_outline,
                color: Color(0xFF42C83C),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'BÀN GIAO CÔNG VIỆC',
                style: TextStyle(
                  color: sectionTitleColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Người nhận bàn giao
          _buildFieldLabel('Người nhận bàn giao', labelColor: labelColor),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: inputBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: TextField(
              controller: _handoverPersonController,
              style: TextStyle(color: textColor, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Tìm tên nhân viên...',
                hintStyle: TextStyle(
                  color: isDark
                      ? const Color(0xFF4B5563)
                      : const Color(0xFF9CA3AF),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: isDark
                      ? const Color(0xFF4B5563)
                      : const Color(0xFF9CA3AF),
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Nội dung công việc
          _buildFieldLabel('Nội dung công việc', labelColor: labelColor),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: inputBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: TextField(
              controller: _handoverContentController,
              maxLines: 3,
              style: TextStyle(color: textColor, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Mô tả ngắn gọn công việc...',
                hintStyle: TextStyle(
                  color: isDark
                      ? const Color(0xFF4B5563)
                      : const Color(0xFF9CA3AF),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Đính kèm tệp
          GestureDetector(
            onTap: () {},
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.attach_file,
                    size: 16,
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Đính kèm tệp',
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer Buttons ─────────────────────────────────────────────────────────
  Widget _buildFooterButtons(bool isDark) {
    return Row(
      children: [
          // Lưu Nháp
          Expanded(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C2C)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                  border: isDark
                      ? Border.all(color: const Color(0xFF3A3A3A))
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Lưu Nháp',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF374151),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Gửi Yêu Cầu
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF42C83C),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Gửi Yêu Cầu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.send_outlined, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _buildFieldLabel(String label,
      {bool isRequired = false, required Color labelColor}) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (isRequired)
          const Text(
            ' *',
            style: TextStyle(
              color: Colors.red,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  Widget _buildDropdown(
      bool isDark, Color inputBg, Color borderColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedLeaveType,
          isExpanded: true,
          dropdownColor: inputBg,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          onChanged: (val) {
            setState(() => _selectedLeaveType = val);
          },
          items: _leaveTypes.map((type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Text(
                type,
                style: TextStyle(color: textColor, fontSize: 14),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDateField(
    bool isDark,
    Color inputBg,
    Color borderColor,
    Color textColor,
    String dateText,
    VoidCallback onTap,
  ) {
    final isPlaceholder = dateText == 'mm/dd/yyyy';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: inputBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          dateText,
          style: TextStyle(
            color: isPlaceholder
                ? (isDark
                    ? const Color(0xFF4B5563)
                    : const Color(0xFF9CA3AF))
                : textColor,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

