import UIKit
import FirebaseMessaging

final class PushNotificationManager {

    static let shared = PushNotificationManager()

    private init() {}

    func register() {
        UIApplication.shared.registerForRemoteNotifications()
        Messaging.messaging().token { token, error in
            if let error = error {
                print("❌ Erreur FCM:", error.localizedDescription)
            } else {
                print("🔥 FCM Token actuel:", token ?? "nil")
            }
        }
    }
}
