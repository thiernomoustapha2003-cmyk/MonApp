import SwiftUI
import StripePaymentSheet

struct PaymentSheetView: UIViewControllerRepresentable {

    let paymentSheet: PaymentSheet
    let onCompletion: (PaymentSheetResult) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .clear

        DispatchQueue.main.async {
            paymentSheet.present(from: controller) { result in
                onCompletion(result)
            }
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
