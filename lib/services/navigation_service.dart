import 'package:flutter/material.dart';

/// Dịch vụ điều hướng toàn cục.
///
/// Gắn [navigatorKey] vào [MaterialApp.navigatorKey] để cho phép
/// navigate / show dialog từ bất kỳ tầng nào (service, interceptor, …)
/// mà không cần [BuildContext].
class NavigationService {
  NavigationService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// [NavigatorState] hiện tại — có thể null nếu app chưa render.
  static NavigatorState? get navigator => navigatorKey.currentState;

  /// [BuildContext] của root navigator — dùng để show dialog toàn cục.
  static BuildContext? get context => navigatorKey.currentContext;
}
