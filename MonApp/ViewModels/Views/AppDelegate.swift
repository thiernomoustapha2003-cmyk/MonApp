import UIKit
import Firebase
import FirebaseAuth
import FirebaseMessaging
import UserNotifications
import Stripe
import StripePayments
import StripePaymentsUI
import FirebaseFunctions
import AVFoundation

class AppDelegate: NSObject,
                   UIApplicationDelegate,
                   UNUserNotificationCenterDelegate,
                   MessagingDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        
        // ⚠️ Empêche double configuration Firebase (garde ton MonAppApp.swift)
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        // Messaging
        Messaging.messaging().delegate = self
        
        // Auth téléphone
        Auth.auth().settings?.isAppVerificationDisabledForTesting = false
        
        // Stripe
        STPAPIClient.shared.publishableKey = StripeConfig.publishableKey
        
        // Notifications
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
        
        // 🔊 Active le mode vidéo (comme TikTok / Reels / YouTube)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback,
                                                            mode: .moviePlayback,
                                                            options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            print("🔊 Audio session activée")
        } catch {
            print("❌ Audio session error:", error)
        }
        
        print("🚀 AppDelegate configuré")
        return true
    }
    
    // 🔥 Firebase Phone Auth — URL (reCAPTCHA)
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        if Auth.auth().canHandle(url) {
            return true
        }
        return false
    }
    
    // 🔥 Firebase Phone Auth — Silent Push
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification notification: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        if Auth.auth().canHandleNotification(notification) {
            completionHandler(.noData)
            return
        }
        
        completionHandler(.newData)
    }
    
    // APNs Token
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    // FCM Token
    func messaging(_ messaging: Messaging,
                   didReceiveRegistrationToken fcmToken: String?) {
        
        guard let token = fcmToken else { return }
        
        print("🔥 FCM Token:", token)
        
        if let uid = Auth.auth().currentUser?.uid {
            Firestore.firestore()
                .collection("users")
                .document(uid)
                .setData([
                    "fcmToken": token
                ], merge: true)
        }
    }
    
    // Notification foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
        @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
    func applicationDidBecomeActive(_ application: UIApplication) {
        Messaging.messaging().token { token, error in
            if let error = error {
                print("❌ Erreur récupération FCM token:", error.localizedDescription)
                return
            }

            guard let token = token,
                  let uid = Auth.auth().currentUser?.uid else { return }

            print("🔥 FCM token actif:", token)

            Firestore.firestore()
                .collection("users")
                .document(uid)
                .setData([
                    "fcmToken": token,
                    "fcmTokenUpdatedAt": Timestamp(date: Date())
                ], merge: true)
        }
    }
    
    
}
