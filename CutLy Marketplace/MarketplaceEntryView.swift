import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct MarketplaceEntryView: View {

    private enum EntryScreen {
        case loading
        case auth
        case step1
        case step2
        case step3
        case step4
        case step5
        case marketplace
    }

    @State private var screen: EntryScreen = .loading

    var body: some View {
        ZStack {
            MarketplaceUITheme.softBackgroundGradient
                .ignoresSafeArea()

            switch screen {
            case .loading:
                loadingView

            case .auth:
                MarketplaceAuthView()
                    .navigationBarBackButtonHidden(true)

            case .step1:
                MarketplaceProfileSetupView()
                    .navigationBarBackButtonHidden(true)

            case .step2:
                MarketplaceLocationSetupView()
                    .navigationBarBackButtonHidden(true)

            case .step3:
                MarketplacePaymentSetupView()
                    .navigationBarBackButtonHidden(true)

            case .step4:
                MarketplaceVerificationView()
                    .navigationBarBackButtonHidden(true)

            case .step5:
                MarketplaceSetupSummaryView()
                    .navigationBarBackButtonHidden(true)

            case .marketplace:
                MarketplacePremiumHomeView()
                    .navigationBarBackButtonHidden(true)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            checkMarketplaceProfile()
        }
    }

    private var loadingView: some View {
        VStack(spacing: 24) {
            ProgressView()

            Text("Préparation de votre Marketplace...")
                .font(.headline)

            Text("Vérification du compte")
                .foregroundStyle(.secondary)
        }
    }

    private func checkMarketplaceProfile() {
        screen = .loading

        guard Auth.auth().currentUser != nil else {
            screen = .auth
            return
        }

        Task {
            do {
                let profile = try await MarketplaceProfileService.shared.fetchMarketplaceProfile()

                await MainActor.run {
                    guard let profile else {
                        screen = .step1
                        return
                    }

                    if profile.profileCompleted == true {
                        screen = .marketplace
                        return
                    }

                    switch profile.currentStep ?? 1 {
                    case 1:
                        screen = .step2
                    case 2:
                        screen = .step3
                    case 3:
                        screen = .step4
                    case 4, 5:
                        screen = .step5
                    default:
                        screen = .step1
                    }
                }

            } catch {
                print("❌ MarketplaceEntryView:", error.localizedDescription)

                await MainActor.run {
                    screen = .step1
                }
            }
        }
    }
}
