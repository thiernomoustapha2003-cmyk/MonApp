import SwiftUI
import Firebase
import FirebaseAuth
import StripePayments
import StripePaymentsUI

@main
struct MonAppApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var callNavigation = CallNavigationManager.shared

    init() {
        FirebaseApp.configure()
        print("🚀 MonAppApp démarrée")
    }

    var body: some Scene {
        WindowGroup {
            SplashView()
                .environmentObject(callNavigation)
                .onOpenURL { url in
                    if url.absoluteString == "cutly://marketplace-certification-success" {
                        NotificationCenter.default.post(
                            name: Notification.Name("MarketplaceCertificationPaymentSuccess"),
                            object: nil
                        )
                    }

                    if url.absoluteString == "cutly://marketplace-certification-cancel" {
                        NotificationCenter.default.post(
                            name: Notification.Name("MarketplaceCertificationPaymentCancel"),
                            object: nil
                        )
                    }
                }
                .fullScreenCover(item: $callNavigation.activeCall) { call in
                    CallScreenView(
                        name: call.callerName,
                        avatarURL: nil,
                        mode: call.type == "video" ? .video : .audio,
                        callId: call.callId,
                        conversationId: call.conversationId
                    ) { duration in
                        CallService.shared.endCall(
                            callId: call.callId,
                            conversationId: call.conversationId,
                            type: call.type,
                            duration: duration
                        )

                        callNavigation.closeCall()
                    }
                }
        }
    }
}
