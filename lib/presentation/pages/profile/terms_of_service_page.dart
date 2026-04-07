import 'package:flutter/material.dart';
import 'package:flutter_core_project/common/helpers/is_dark_mode.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final bg = isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF5F6FA);
    final cardBg = isDark ? const Color(0xFF242424) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final textColor = isDark ? Colors.white70 : const Color(0xFF374151);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: titleColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Điều khoản dịch vụ',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: titleColor,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ĐIỀU KHOẢN VÀ DỊCH VỤ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Công ty CÔNG TY TNHH THƯƠNG MẠI - DỊCH VỤ TÂN HIỆP PHÁT thu thập, sử dụng, lưu trữ và xử lý dữ liệu cá nhân của tôi theo Luật Bảo vệ Dữ liệu Cá nhân số 91/2025/QH15, cho các mục đích: tuyển dụng, quản lý nhân sự, lưu trữ hồ sơ nhân sự, thống kê, báo cáo nội bộ và chia sẻ dữ liệu cho bên thứ ba bao gồm nhưng không giới hạn: cơ quan quản lý thuế, ngân hàng, các tổ chức khác…để thực hiện nghĩa vụ của doanh nghiệp đối với người lao động như bảo hiểm, thuế,… và quyền lợi khác cho NLĐ theo quy định của pháp luật và chính sách công ty.',
                style: TextStyle(
                  fontSize: 13,
                  color: textColor,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tôi đã được thông báo về quyền của mình đối với dữ liệu cá nhân, bao gồm quyền truy cập, chỉnh sửa, rút lại sự đồng ý, yêu cầu xóa hoặc hạn chế xử lý dữ liệu bằng hình thức gởi yêu cầu bằng văn bản đến Phòng Nhân Sự công ty. Dữ liệu của tôi sẽ được lưu trữ trong thời hạn thực hiện hợp đồng và sau khi chấm dứt hợp đồng cho các mục đích nêu trên cho đến khi Bạn có yêu cầu sửa đổi hoặc xóa bỏ dữ liệu.',
                style: TextStyle(
                  fontSize: 13,
                  color: textColor,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

