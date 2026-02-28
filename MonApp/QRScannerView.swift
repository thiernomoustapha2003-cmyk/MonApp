import SwiftUI
import AVFoundation

struct QRScannerView: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> ScannerController {
        return ScannerController()
    }

    func updateUIViewController(_ uiViewController: ScannerController, context: Context) {}
}

class ScannerController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    var session: AVCaptureSession!

    override func viewDidLoad() {
        super.viewDidLoad()

        session = AVCaptureSession()
        guard let device = AVCaptureDevice.default(for: .video) else { return }

        let input = try! AVCaptureDeviceInput(device: device)
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        session.addOutput(output)

        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        output.metadataObjectTypes = [.qr]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.frame = view.layer.bounds
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)

        session.startRunning()
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {

        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = object.stringValue else { return }

        session.stopRunning()
        releasePayment(bookingId: value)
    }

    func releasePayment(bookingId: String) {
        guard let url = URL(string: "https://us-central1-afroconnect-7588d.cloudfunctions.net/releaseEscrow") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["bookingId": bookingId]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request).resume()
    }
}
