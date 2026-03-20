import 'package:flutter_core_project/data/data_sources/remote/adjustment_report_api_service.dart';
import 'package:flutter_core_project/data/models/timesheet/adjustment_report_model.dart';

/// UseCase: Gửi báo cáo điều chỉnh công lên server.
/// Trả về message từ server khi thành công.
class SubmitAdjustmentReportUseCase {
  final AdjustmentReportApiService _apiService;

  SubmitAdjustmentReportUseCase(this._apiService);

  Future<String> call(AdjustmentReportRequest request) {
    return _apiService.submitAdjustmentReport(request);
  }
}
