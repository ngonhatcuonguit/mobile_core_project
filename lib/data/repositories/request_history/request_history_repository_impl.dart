import 'package:flutter_core_project/data/data_sources/remote/request_history_api_service.dart';
import 'package:flutter_core_project/data/models/request_history/request_history_model.dart';

abstract class RequestHistoryRepository {
  Future<RequestHistoryResponse> getMyRequests({
    int page = 1,
    int pageSize = 10,
  });
}

class RequestHistoryRepositoryImpl implements RequestHistoryRepository {
  final RequestHistoryApiService _api;
  RequestHistoryRepositoryImpl(this._api);

  @override
  Future<RequestHistoryResponse> getMyRequests({
    int page = 1,
    int pageSize = 10,
  }) =>
      _api.getMyRequests(page: page, pageSize: pageSize);
}

