import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_core_project/services/firebase_service.dart';

/// Navigator observer tự động ghi nhận tên màn hình lên Firebase Analytics
/// mỗi khi user navigate sang route mới.
///
/// Cách dùng — thêm vào MaterialApp:
/// ```dart
/// MaterialApp(
///   navigatorObservers: [FirebaseAnalyticsObserver(analytics: FirebaseService.instance.analytics)],
/// )
/// ```
class AppFirebaseAnalyticsObserver extends RouteObserver<PageRoute<dynamic>> {
  final FirebaseAnalytics analytics;

  AppFirebaseAnalyticsObserver({required this.analytics});

  void _sendScreenView(PageRoute<dynamic> route) {
    final screenName = route.settings.name ?? route.runtimeType.toString();
    FirebaseService.instance.logScreenView(screenName, screenName);
    debugPrint('[Analytics] Screen: $screenName');
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is PageRoute) {
      _sendScreenView(route);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute is PageRoute) {
      _sendScreenView(newRoute);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute is PageRoute) {
      _sendScreenView(previousRoute);
    }
  }
}

