import UIKit
import Flutter
import UserNotifications
import FirebaseCore
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Firebase
    FirebaseApp.configure()

    // Register for remote notifications (required for FCM on iOS)
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { _, _ in }
      )
    } else {
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }
    application.registerForRemoteNotifications()

    // Set FCM messaging delegate
    Messaging.messaging().delegate = self

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - FCM Token refresh
  override func application(_ application: UIApplication,
                             didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  // MARK: - Remote Notification (required when FirebaseAppDelegateProxyEnabled = false)
  // Firebase cannot auto-swizzle this method, so we must call appDidReceiveMessage manually
  // to ensure FCM receives background & data-only notifications correctly.
  override func application(_ application: UIApplication,
                             didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                             fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    // Forward to Firebase Messaging so FCM can process data messages / background refresh
    Messaging.messaging().appDidReceiveMessage(userInfo)
    // Forward to Flutter plugins (firebase_messaging plugin handles onMessage / onBackgroundMessage)
    super.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
  }

  // MARK: - Registration failure (for debugging)
  override func application(_ application: UIApplication,
                             didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("[APNs] ❌ Failed to register for remote notifications: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("FCM Token: \(fcmToken ?? "nil")")
    let dataDict: [String: String] = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(
      name: Notification.Name("FCMToken"),
      object: nil,
      userInfo: dataDict
    )
  }
}
