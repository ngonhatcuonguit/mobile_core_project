# Firebase Cloud Messaging setup

The Dart service, local notification channel, token cache/sync flow and native
capabilities are already configured. Firebase credential files are deliberately
ignored because they belong to a specific Firebase project.

## Android

Create two Android apps in Firebase and download each configuration:

- Dev package `com.constructionplan.app.dev` ->
  `android/app/src/dev/google-services.json`
- Production package `com.constructionplan.app` ->
  `android/app/src/prod/google-services.json`

The Gradle Google Services plugin is applied automatically once either file is
present. Android 13 notification permission and the high-importance foreground
channel are already declared.

## iOS

Create an iOS Firebase app with bundle ID `com.constructionplan.app`, then place
the downloaded file at `ios/Runner/GoogleService-Info.plist`.

Firebase 12 requires iOS 15 or newer; the Podfile and every Runner build
configuration are already aligned to iOS 15.

Enable Push Notifications and Background Modes / Remote notifications for the
Runner target in Xcode. The repository already includes the APNs entitlement and
background modes. Upload the APNs authentication key to Firebase Console before
testing on a physical device.

## Backend token registration

Set `FCM_TOKEN_ENDPOINT` in each environment file when the backend endpoint is
available. The app caches every refreshed token locally and posts this body:

```json
{
  "deviceRegistrationId": "<FCM token>",
  "platform": "android|ios"
}
```

Without Firebase credential files, startup remains functional and logs that FCM
is disabled. This keeps local development and CI builds deterministic.
