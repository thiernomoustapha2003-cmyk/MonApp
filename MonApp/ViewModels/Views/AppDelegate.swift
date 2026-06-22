import UIKit
import Firebase
import FirebaseAuth
import FirebaseMessaging
import FirebaseFirestore
import UserNotifications
import Stripe
import StripePayments
import StripePaymentsUI
import FirebaseFunctions
import AVFoundation
import PushKit

class AppDelegate: NSObject,
                   UIApplicationDelegate,
                   UNUserNotificationCenterDelegate,
                   MessagingDelegate,
                   PKPushRegistryDelegate {

    private var voipRegistry: PKPushRegistry?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {

        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        Messaging.messaging().delegate = self

        Auth.auth().settings?.isAppVerificationDisabledForTesting = false

        STPAPIClient.shared.publishableKey = StripeConfig.publishableKey

        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, _ in
            if granted {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
                print("✅ Notifications autorisées")
            } else {
                print("❌ Notifications refusées")
            }
        }

        let registry = PKPushRegistry(queue: DispatchQueue.main)
        registry.delegate = self
        registry.desiredPushTypes = [.voIP]
        self.voipRegistry = registry

        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .moviePlayback,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
            print("🔊 Audio session activée")
        } catch {
            print("❌ Audio session error:", error)
        }

        print("🚀 AppDelegate configuré")
        return true
    }

    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {

        if Auth.auth().canHandle(url) {
            return true
        }

        return false
    }

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification notification: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

        if Auth.auth().canHandleNotification(notification) {
            completionHandler(.noData)
            return
        }

        completionHandler(.newData)
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func messaging(_ messaging: Messaging,
                   didReceiveRegistrationToken fcmToken: String?) {

        guard let token = fcmToken else { return }

        print("🔥 FCM Token:", token)

        if let uid = Auth.auth().currentUser?.uid {
            Firestore.firestore()
                .collection("users")
                .document(uid)
                .setData([
                    "fcmToken": token,
                    "fcmTokenUpdatedAt": Timestamp(date: Date())
                ], merge: true)
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        Messaging.messaging().token { token, error in
            if let error = error {
                print("❌ Erreur récupération FCM token:", error.localizedDescription)
                return
            }

            guard let token = token,
                  let uid = Auth.auth().currentUser?.uid else { return }

            Firestore.firestore()
                .collection("users")
                .document(uid)
                .setData([
                    "fcmToken": token,
                    "fcmTokenUpdatedAt": Timestamp(date: Date())
                ], merge: true)

            print("🔥 FCM token actif:", token)
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
        @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    func pushRegistry(_ registry: PKPushRegistry,
                      didUpdate pushCredentials: PKPushCredentials,
                      for type: PKPushType) {

        let token = pushCredentials.token.map { String(format: "%02x", $0) }.joined()

        guard let uid = Auth.auth().currentUser?.uid else {
            print("⚠️ VoIP token reçu mais utilisateur pas connecté")
            return
        }

        Firestore.firestore()
            .collection("users")
            .document(uid)
            .setData([
                "voipToken": token,
                "voipTokenUpdatedAt": Timestamp(date: Date())
            ], merge: true)

        print("📞 VoIP Token:", token)
    }

    func pushRegistry(_ registry: PKPushRegistry,
                      didReceiveIncomingPushWith payload: PKPushPayload,
                      for type: PKPushType,
                      completion: @escaping () -> Void) {

        let data = payload.dictionaryPayload

        let callId = data["callId"] as? String ?? ""
        let callerName = data["callerName"] as? String ?? "Appel Cutly"
        let conversationId = data["conversationId"] as? String ?? ""
        let callType = data["type"] as? String ?? "audio"

        CallKitManager.shared.reportIncomingCall(
            callId: callId,
            callerName: callerName,
            conversationId: conversationId,
            type: callType
        )

        completion()
    }
}
