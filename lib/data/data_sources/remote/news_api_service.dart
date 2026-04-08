import 'package:dio/dio.dart';
import 'package:flutter_core_project/data/models/news/ArticleModel.dart';
import 'package:retrofit/dio.dart';
import 'package:retrofit/http.dart';
import '../../../constants/constants.dart';
import 'parse_error_logger.dart';
part 'news_api_service.g.dart';

@RestApi(baseUrl: newsAPIBaseURL)
abstract class NewsApiService{

  factory NewsApiService(Dio dio) = _NewsApiService;

  @GET('/top-headlines')
  Future<HttpResponse<List<ArticleModel>>> getNewsArticles ({
    @Query("apiKey") String ? apiKey,
    @Query("country") String ? country,
    @Query("category") String ? category,
  });
}