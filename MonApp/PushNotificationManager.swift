import UIKit
import Foundation
import Combine
import Firebase
import FirebaseAuth
import FirebaseMessaging
import UserNotifications


class PushNotificationManager: NSObject, ObservableObject {

    static let shared = PushNotificationManager()

    func register() {
        UNUserNotificationCenter.current().delegate = self

        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, _ in
            print("Permission notif:", granted)
        }

        UIApplication.shared.registerForRemoteNotifications()
        Messaging.messaging().delegate = self
    }
}

// MARK: - APNS TOKEN
extension PushNotificationManager {

    func setAPNSToken(_ deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
}

// MARK: - FCM TOKEN
extension PushNotificationManager: MessagingDelegate {

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("🔥 FCM TOKEN =", fcmToken ?? "nil")

        guard let uid = Auth.auth().currentUser?.uid,
              let token = fcmToken else { return }

        let db = Firestore.firestore()
        db.collection("users").document(uid).setData([
            "fcmToken": token
        ], merge: true)
    }
}

// MARK: - FOREGROUND NOTIF
extension PushNotificationManager: UNUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler:
                                @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}
