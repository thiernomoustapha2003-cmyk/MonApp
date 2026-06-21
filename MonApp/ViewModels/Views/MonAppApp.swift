import SwiftUI
import Firebase
import FirebaseAuth
import StripePayments
import StripePaymentsUI

@main
struct MonAppApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    init() {
        print("🚀 MonAppApp démarrée")

        // 🔔 permission rappels automatiques
        LocalNotificationManager.shared.requestPermission()
        
    }

    var body: some Scene {
        WindowGroup {
            SplashView()
        }
    }
}
