import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized app configuration.
/// Values are read from the loaded .env file (either .env.dev or .env.prod),
/// which is determined by the entrypoint (main_dev.dart / main_prod.dart).
class AppConfig {
  AppConfig._();

  /// The environment name: "development" or "production"
  static String get environment =>
      dotenv.env['ENVIRONMENT'] ?? 'development';

  /// Base URL for the THP API (e.g. https://mobile-app.thp.com.vn)
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://mobile-app.thp.com.vn';

  /// Display name shown in app title / debug banner
  static String get appTitle =>
      dotenv.env['APP_TITLE'] ?? 'My THP';

  /// Whether this is a development build
  static bool get isDev => environment == 'development';

  /// Whether this is a production build
  static bool get isProd => environment == 'production';

  /// Connect / receive / send timeout in milliseconds
  static int get timeoutMs =>
      int.tryParse(dotenv.env['API_TIMEOUT_MS'] ?? '30000') ?? 30000;

  @override
  String toString() => 'AppConfig(env=$environment, baseUrl=$baseUrl)';
}

