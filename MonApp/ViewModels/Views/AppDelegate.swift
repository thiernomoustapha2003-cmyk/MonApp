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
        
        configureNotifications(application)
        configureVoIPPush()
        configureBaseAudioSession()
        
        print("🚀 AppDelegate configuré")
        print("🔥 FirebaseAppDelegateProxyEnabled =", Bundle.main.object(forInfoDictionaryKey: "FirebaseAppDelegateProxyEnabled") ?? "ABSENT")
        return true
    }
    
    // MARK: - Notifications normales
    
    private func configureNotifications(_ application: UIApplication) {
        UNUserNotificationCenter.current().delegate = self
        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("🔍 Notification status:", settings.authorizationStatus.rawValue)
            
            if settings.authorizationStatus == .authorized ||
                settings.authorizationStatus == .provisional ||
                settings.authorizationStatus == .ephemeral {
                
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                    print("📲 registerForRemoteNotifications appelé car déjà autorisé")
                }
                return
            }
            
            if settings.authorizationStatus == .denied {
                print("❌ Notifications refusées dans Réglages iPhone")
                return
            }
            
            UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            ) { granted, error in
                
                if let error = error {
                    print("❌ Permission notification error:", error.localizedDescription)
                }
                
                print("🔔 Permission notification demandée:", granted)
                
                if granted {
                    DispatchQueue.main.async {
                        application.registerForRemoteNotifications()
                        print("📲 registerForRemoteNotifications appelé après autorisation")
                    }
                } else {
                    print("❌ Notifications refusées par requestAuthorization")
                }
            }
        }
    }
    
    // MARK: - PushKit VoIP
    
    private func configureVoIPPush() {
        let registry = PKPushRegistry(queue: DispatchQueue.main)
        registry.delegate = self
        registry.desiredPushTypes = [.voIP]
        self.voipRegistry = registry
        print("📞 PushKit VoIP configuré")
    }
    
    // MARK: - Audio session de base
    
    private func configureBaseAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .moviePlayback,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
            print("🔊 Audio session base activée")
        } catch {
            print("❌ Audio session base error:", error.localizedDescription)
        }
    }
    
    // MARK: - Deep links Firebase Auth
    
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        
        if Auth.auth().canHandle(url) {
            return true
        }
        
        return false
    }
    
    // MARK: - Notifications reçues
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification notification: [AnyHashable : Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        
        if Auth.auth().canHandleNotification(notification) {
            completionHandler(.noData)
            return
        }
        
        print("📩 Remote notification reçue:", notification)
        
        NotificationCenter.default.post(
            name: Notification.Name("OpenNotification"),
            object: nil,
            userInfo: notification
        )
        
        completionHandler(.newData)
    }
    
    // MARK: - APNs token normal
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {

        Messaging.messaging().apnsToken = deviceToken
       
        

        let apnsToken = deviceToken.map {
            String(format: "%02x", $0)
        }.joined()
        
        print("📲 APNs Token normal:", apnsToken)
        
        guard let uid = Auth.auth().currentUser?.uid else {
            print("⚠️ APNs token reçu mais utilisateur pas connecté")
            return
        }
        
        Firestore.firestore()
            .collection("users")
            .document(uid)
            .setData([
                "apnsToken": apnsToken,
                "apnsTokenUpdatedAt": Timestamp(date: Date())
            ], merge: true)
        
        print("✅ APNs Token normal sauvegardé Firestore")
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("❌ APNs registration failed:", error.localizedDescription)
    }
    
    // MARK: - FCM token
    
    func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        
        guard let fcmToken = fcmToken else {
            print("⚠️ FCM Token nil")
            return
        }
        
        print("🔥 FCM Token:", fcmToken)
        
        guard let uid = Auth.auth().currentUser?.uid else {
            print("⚠️ FCM token reçu mais utilisateur pas connecté")
            return
        }
        
        var dataToSave: [String: Any] = [
            "fcmToken": fcmToken,
            "fcmTokenUpdatedAt": Timestamp(date: Date())
        ]
        
        if let apnsData = Messaging.messaging().apnsToken {
            let apnsToken = apnsData.map { String(format: "%02x", $0) }.joined()
            
            dataToSave["apnsToken"] = apnsToken
            dataToSave["apnsTokenUpdatedAt"] = Timestamp(date: Date())
            
            print("📲 APNs Token via MessagingDelegate:", apnsToken)
        } else {
            print("❌ APNS TOKEN NIL dans MessagingDelegate")
        }
        
        Firestore.firestore()
            .collection("users")
            .document(uid)
            .setData(dataToSave, merge: true)
        
        print("✅ Tokens sauvegardés Firestore")
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        refreshTokens()
        
        // Quand l'app redevient active après écran verrouillé,
        // on demande à la navigation SwiftUI d'ouvrir l'appel actif si nécessaire.
        NotificationCenter.default.post(
            name: Notification.Name("AppBecameActiveForCall"),
            object: nil
        )
    }
    
    private func refreshTokens() {
        Messaging.messaging().token { token, error in
            
            if let error = error {
                print("❌ Erreur récupération FCM token:", error.localizedDescription)
                return
            }
            
            guard let token = token,
                  let uid = Auth.auth().currentUser?.uid else { return }
            
            var dataToSave: [String: Any] = [
                "fcmToken": token,
                "fcmTokenUpdatedAt": Timestamp(date: Date())
            ]
            
            if let apnsData = Messaging.messaging().apnsToken {
                let apnsToken = apnsData.map { String(format: "%02x", $0) }.joined()
                dataToSave["apnsToken"] = apnsToken
                dataToSave["apnsTokenUpdatedAt"] = Timestamp(date: Date())
                print("📲 APNs Token via Firebase:", apnsToken)
            }
            
            Firestore.firestore()
                .collection("users")
                .document(uid)
                .setData(dataToSave, merge: true)
            
            print("🔥 Tokens actifs sauvegardés")
        }
    }
    
    // MARK: - Notification affichée pendant app ouverte
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
        @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("🔔 Notification foreground:", notification.request.content.userInfo)
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        
        let userInfo = response.notification.request.content.userInfo
        print("👆 Notification cliquée:", userInfo)
        
        NotificationCenter.default.post(
            name: Notification.Name("OpenNotification"),
            object: nil,
            userInfo: userInfo
        )
        
        completionHandler()
    }
    
    // MARK: - VoIP token
    
    func pushRegistry(
        _ registry: PKPushRegistry,
        didUpdate pushCredentials: PKPushCredentials,
        for type: PKPushType
    ) {
        
        let voipToken = pushCredentials.token.map {
            String(format: "%02x", $0)
        }.joined()
        
        print("📞 VoIP Token:", voipToken)
        
        guard let uid = Auth.auth().currentUser?.uid else {
            print("⚠️ VoIP token reçu mais utilisateur pas connecté")
            return
        }
        
        Firestore.firestore()
            .collection("users")
            .document(uid)
            .setData([
                "voipToken": voipToken,
                "voipTokenUpdatedAt": Timestamp(date: Date())
            ], merge: true)
        
        print("✅ VoIP Token sauvegardé Firestore")
    }
    
    func pushRegistry(
        _ registry: PKPushRegistry,
        didInvalidatePushTokenFor type: PKPushType
    ) {
        
        print("⚠️ VoIP token invalidé")
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore()
            .collection("users")
            .document(uid)
            .setData([
                "voipToken": FieldValue.delete(),
                "voipTokenUpdatedAt": Timestamp(date: Date())
            ], merge: true)
    }
    
    // MARK: - VoIP push entrant
    
    func pushRegistry(
        _ registry: PKPushRegistry,
        didReceiveIncomingPushWith payload: PKPushPayload,
        for type: PKPushType,
        completion: @escaping () -> Void
    ) {
        
        let data = payload.dictionaryPayload
        print("📲 VoIP push reçu:", data)
        
        let callId = data["callId"] as? String ?? ""
        let callerName = data["callerName"] as? String ?? "Appel Cutly"
        let conversationId = data["conversationId"] as? String ?? ""
        let callType = data["type"] as? String ?? "audio"
        
        guard !callId.isEmpty, !conversationId.isEmpty else {
            print("❌ VoIP push invalide: callId/conversationId manquant")
            completion()
            return
        }
        
        // 1. Afficher l'écran natif iPhone.
        CallKitManager.shared.reportIncomingCall(
            callId: callId,
            callerName: callerName,
            conversationId: conversationId,
            type: callType
        )
        
        // 2. Prévenir SwiftUI qu'un appel existe.
        // Important : ça permettra plus tard d'ouvrir directement la bonne conversation.
        NotificationCenter.default.post(
            name: Notification.Name("IncomingVoIPCallReceived"),
            object: nil,
            userInfo: [
                "callId": callId,
                "conversationId": conversationId,
                "callerName": callerName,
                "type": callType
            ]
        )
        
        completion()
    }
    
    
}
