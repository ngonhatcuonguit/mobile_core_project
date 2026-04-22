import 'package:flutter/material.dart';
import 'package:flutter_core_project/common/helpers/is_dark_mode.dart';
import 'package:flutter_core_project/presentation/widgets/dialogs/under_development_dialog.dart';
import 'package:flutter_core_project/services/auth_service.dart';
import 'package:flutter_core_project/services/localization_service.dart';

class LeaveRequestPage extends StatefulWidget {
  const LeaveRequestPage({super.key});

  @override
  State<LeaveRequestPage> createState() => _LeaveRequestPageState();
}

class _LeaveRequestPageState extends State<LeaveRequestPage> {
  int? _selectedLeaveTypeIndex = 0; // Use index instead of string
  DateTime? _fromDate;
  DateTime? _toDate;
  late List<String> _leaveTypes;
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _handoverPersonController =
      TextEditingController();
  final TextEditingController _handoverContentController =
      TextEditingController();

  // User data
  String? _displayName;
  String? _department;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final displayName = await AuthService.getDisplayName();
    final department = await AuthService.getDepartment();
    setState(() {
      _displayName = displayName;
      _department = department;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize leave types once per dependency change
    _leaveTypes = [
      context.tr('leave_type_annual'),
      context.tr('leave_type_sick'),
      context.tr('leave_type_unpaid'),
      context.tr('leave_type_public'),
      context.tr('leave_type_maternity'),
    ];
    // Set default selected index
    _selectedLeaveTypeIndex ??= 0;
  }


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
                      context.tr('leave_request_title'),
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
    final displayName = _displayName ?? 'User';
    final department = _department ?? 'Department';

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
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      department,
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
              context.tr('leave_available'),
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
                    context.tr('leave_days_unit'),
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
                  child: Text(
                    context.tr('leave_year_label'),
                    style: const TextStyle(
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      department,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('leave_available'),
              style: const TextStyle(
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
                  '1.05',//load ngày từ api
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
                    context.tr('leave_days_unit'),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
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
                  child: Text(
                    context.tr('leave_year_label'),
                    style: const TextStyle(
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
                context.tr('leave_info_section'),
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
          _buildFieldLabel(context.tr('leave_type_label'), isRequired: true, labelColor: labelColor),
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
                    _buildFieldLabel(context.tr('leave_from_date'), isRequired: true, labelColor: labelColor),
                    const SizedBox(height: 6),
                    _buildDateField(
                      isDark, inputBg, borderColor, textColor,
                      _formatDate(_fromDate), () => _pickDate(true),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel(context.tr('leave_to_date'), isRequired: true, labelColor: labelColor),
                    const SizedBox(height: 6),
                    _buildDateField(
                      isDark, inputBg, borderColor, textColor,
                      _formatDate(_toDate), () => _pickDate(false),
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
                  context.tr('leave_total'),
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  '$_totalDays ${context.tr('leave_days_unit')}',
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
          _buildFieldLabel(context.tr('leave_reason'), isRequired: true, labelColor: labelColor),
          const SizedBox(height: 6),
          TextField(
            controller: _reasonController,
            maxLines: 4,
            style: TextStyle(color: textColor, fontSize: 14),
            decoration: InputDecoration(
              hintText: context.tr('leave_hint_reason'),
              hintStyle: TextStyle(
                color: isDark
                    ? const Color(0xFF4B5563)
                    : const Color(0xFF9CA3AF),
                fontSize: 14,
              ),
              filled: true,
              fillColor: inputBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderColor),
              ),
              contentPadding: const EdgeInsets.all(12),
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
                context.tr('leave_handover_section'),
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
          _buildFieldLabel(context.tr('leave_handover_person'), labelColor: labelColor),
          const SizedBox(height: 6),
          TextField(
            controller: _handoverPersonController,
            style: TextStyle(color: textColor, fontSize: 14),
            decoration: InputDecoration(
              hintText: context.tr('leave_hint_search'),
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
              filled: true,
              fillColor: inputBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderColor),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
          const SizedBox(height: 14),

          // Nội dung công việc
          _buildFieldLabel(context.tr('leave_work_content'), labelColor: labelColor),
          const SizedBox(height: 6),
          TextField(
            controller: _handoverContentController,
            maxLines: 3,
            style: TextStyle(color: textColor, fontSize: 14),
            decoration: InputDecoration(
              hintText: context.tr('leave_hint_work'),
              hintStyle: TextStyle(
                color: isDark
                    ? const Color(0xFF4B5563)
                    : const Color(0xFF9CA3AF),
                fontSize: 14,
              ),
              filled: true,
              fillColor: inputBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderColor),
              ),
              contentPadding: const EdgeInsets.all(12),
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
                    context.tr('leave_attach_file'),
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
              onTap: () => showUnderDevelopmentDialog(context),
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
                    context.tr('leave_save_draft'),
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
              onTap: () => showUnderDevelopmentDialog(context),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF42C83C),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.tr('leave_submit'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.send_outlined, color: Colors.white, size: 18),
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
        child: DropdownButton<int>(
          value: _selectedLeaveTypeIndex,
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
            setState(() => _selectedLeaveTypeIndex = val);
          },
          items: List.generate(
            _leaveTypes.length,
            (index) => DropdownMenuItem<int>(
              value: index,
              child: Text(
                _leaveTypes[index],
                style: TextStyle(color: textColor, fontSize: 14),
              ),
            ),
          ),
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

