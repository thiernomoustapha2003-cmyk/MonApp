import SwiftUI
import AVFoundation
import CoreImage

struct FilterOverlayView: UIViewRepresentable {
    
    let session: AVCaptureSession
    let filterName: String
    let currentPosition: AVCaptureDevice.Position
    
    func makeUIView(context: Context) -> FilterView {
        let view = FilterView()
        view.configure(
            session: session,
            filterName: filterName,
            currentPosition: currentPosition
        )
        return view
    }
    
    func updateUIView(_ uiView: FilterView, context: Context) {
        uiView.filterName = filterName
        uiView.currentPosition = currentPosition
    }
    
    static func dismantleUIView(_ uiView: FilterView, coordinator: ()) {
        uiView.cleanup()
    }
}

final class FilterView: UIView, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    weak var session: AVCaptureSession?
    var filterName: String = ""
    var currentPosition: AVCaptureDevice.Position = .front
    
    private let imageView = UIImageView()
    private let contextCI = CIContext()
    private let output = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "cutly.filter.queue")
    private var isOutputAdded = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        addSubview(imageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
    }
    
    func configure(
        session: AVCaptureSession,
        filterName: String,
        currentPosition: AVCaptureDevice.Position
    ) {
        self.session = session
        self.filterName = filterName
        self.currentPosition = currentPosition
        
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: queue)
        
        addOutputIfNeeded()
    }
    
    private func addOutputIfNeeded() {
        guard let session = session, !isOutputAdded else { return }
        
        session.beginConfiguration()
        
        if session.canAddOutput(output) {
            session.addOutput(output)
            isOutputAdded = true
        }
        
        session.commitConfiguration()
    }
    
    func cleanup() {
        output.setSampleBufferDelegate(nil, queue: nil)
        
        guard let session = session, isOutputAdded else { return }
        
        session.beginConfiguration()
        session.removeOutput(output)
        session.commitConfiguration()
        
        isOutputAdded = false
    }
    
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        var ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        ciImage = ciImage.oriented(.right)
        
        if currentPosition == .front {
            ciImage = ciImage.oriented(.upMirrored)
        }
        
        var finalImage = ciImage
        
        if !filterName.isEmpty,
           let filter = CIFilter(name: filterName) {
            filter.setValue(ciImage, forKey: kCIInputImageKey)
            if let outputImage = filter.outputImage {
                finalImage = outputImage
            }
        }
        
        guard let cgImage = contextCI.createCGImage(finalImage, from: finalImage.extent) else { return }
        let uiImage = UIImage(cgImage: cgImage)
        
        DispatchQueue.main.async {
            self.imageView.image = uiImage
        }
    }
}
