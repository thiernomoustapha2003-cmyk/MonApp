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
    var previewLayer: AVCaptureVideoPreviewLayer!
    var hasScanned = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScanner()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
    
    func setupScanner() {
        session = AVCaptureSession()
        
        guard let device = AVCaptureDevice.default(for: .video) else {
            showMessage("Caméra introuvable.")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            
            if session.canAddInput(input) {
                session.addInput(input)
            }
            
            let output = AVCaptureMetadataOutput()
            
            if session.canAddOutput(output) {
                session.addOutput(output)
                output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                output.metadataObjectTypes = [.qr]
            }
            
            previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.frame = view.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
            
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.startRunning()
            }
            
        } catch {
            showMessage("Impossible d’ouvrir la caméra.")
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        
        guard !hasScanned else { return }
        
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = object.stringValue else { return }
        
        hasScanned = true
        session.stopRunning()
        
        guard let bookingId = extractBookingId(from: value) else {
            showMessage("QR code invalide.")
            return
        }
        
        releasePayment(bookingId: bookingId)
    }
    
    func extractBookingId(from value: String) -> String? {
        
        if let url = URL(string: value),
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let bookingId = components.queryItems?.first(where: { $0.name == "bookingId" })?.value {
            return bookingId
        }
        
        if value.contains("bookingId=") {
            return value.components(separatedBy: "bookingId=").last
        }
        
        return value.isEmpty ? nil : value
    }
    
    func releasePayment(bookingId: String) {
        guard let url = URL(string: "https://releaseescrow-jzvik52b6a-uc.a.run.app") else {
            showMessage("URL backend invalide.")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["bookingId": bookingId]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            DispatchQueue.main.async {
                
                if let error = error {
                    self.showMessage("Erreur réseau : \(error.localizedDescription)")
                    return
                }
                
                guard let http = response as? HTTPURLResponse else {
                    self.showMessage("Réponse serveur invalide.")
                    return
                }
                
                if http.statusCode == 200 {
                    self.showMessage("✅ Réservation validée. Paiement libéré.")
                } else {
                    self.showMessage("❌ Impossible de valider cette réservation.")
                }
            }
        }.resume()
    }
    
    func showMessage(_ message: String) {
        let alert = UIAlertController(title: "Cutly", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
