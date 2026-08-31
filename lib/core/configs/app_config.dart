import 'package:flutter_dotenv/flutter_dotenv.dart';

enum AppEnvironment {
  dev('.env.dev'),
  prod('.env.prod');

  const AppEnvironment(this.fileName);

  final String fileName;
}

/// Runtime configuration loaded from the selected flavor environment file.
class AppConfig {
  AppConfig._();

  static AppEnvironment _environment = AppEnvironment.prod;

  static Future<void> load(AppEnvironment environment) async {
    _environment = environment;
    await dotenv.load(fileName: environment.fileName);
  }

  static AppEnvironment get environment => _environment;

  static String get environmentName =>
      _value('ENVIRONMENT')?.trim().isNotEmpty == true
          ? _value('ENVIRONMENT')!.trim()
          : _environment.name;

  static String get appTitle => _value('APP_TITLE')?.trim().isNotEmpty == true
      ? _value('APP_TITLE')!.trim()
      : 'Construction Plan';

  static String get apiBaseUrl => _value('API_BASE_URL')?.trim() ?? '';

  static int get apiTimeoutMs =>
      int.tryParse(_value('API_TIMEOUT_MS') ?? '') ?? 30000;

  static String get fcmTokenEndpoint =>
      _value('FCM_TOKEN_ENDPOINT')?.trim() ?? '';

  static bool get hasRemoteApi => apiBaseUrl.isNotEmpty;

  static bool get hasFcmTokenEndpoint => fcmTokenEndpoint.isNotEmpty;

  static const String versionLabel = '1.0.5';

  static String? _value(String key) {
    return dotenv.isInitialized ? dotenv.env[key] : null;
  }
}
