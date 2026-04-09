import Foundation
import UIKit
import UserNotifications

@MainActor
final class SpendSageAppDelegate: NSObject, UIApplicationDelegate, @preconcurrency UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        PushRegistrationPersistence.cacheToken(token)
        NotificationCenter.default.post(
            name: .spendsageDidRegisterForRemoteNotifications,
            object: nil,
            userInfo: [PushRegistrationNotificationKeys.token: token]
        )
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NotificationCenter.default.post(
            name: .spendsageDidFailRemoteNotificationRegistration,
            object: nil,
            userInfo: [PushRegistrationNotificationKeys.error: error.localizedDescription]
        )
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .badge, .sound, .list])
    }
}
