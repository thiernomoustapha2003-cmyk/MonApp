import UIKit
import Firebase
import UserNotifications
import FirebaseMessaging
import StripePayments
import StripePaymentsUI
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {

        // ✅ Firebase
        FirebaseApp.configure()
        Messaging.messaging().delegate = self

        // ✅ Stripe (clé publique)
        STPAPIClient.shared.publishableKey = StripeConfig.publishableKey

        // ✅ Notifications
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("✅ Notifications autorisées")
            } else {
                print("❌ Notifications refusées")
            }
        }

        application.registerForRemoteNotifications()

        return true
    }

    // ✅ Notification reçue quand l'app est ouverte
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    // ✅ Token Firebase FCM
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        print("🔥 FCM Token :", token)
    }
}

