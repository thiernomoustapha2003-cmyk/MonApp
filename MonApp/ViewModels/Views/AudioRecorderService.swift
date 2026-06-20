import Foundation
import AVFoundation
import Combine

class AudioRecorderService: NSObject, ObservableObject {

    static let shared = AudioRecorderService()

    @Published var isRecording = false
    @Published var isPaused = false
    @Published var recordingTime: TimeInterval = 0

    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    private var currentFileURL: URL?

    private let maxDuration: TimeInterval = 28800 // 8 heures

    private override init() {}

    func requestPermission(completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { allowed in
            DispatchQueue.main.async {
                completion(allowed)
            }
        }
    }

    func startRecording() -> URL? {
        let session = AVAudioSession.sharedInstance()

        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)

            let fileURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString + ".m4a")

            currentFileURL = fileURL

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            recorder = try AVAudioRecorder(url: fileURL, settings: settings)
            recorder?.delegate = self
            recorder?.prepareToRecord()
            recorder?.record(forDuration: maxDuration)

            isRecording = true
            isPaused = false
            recordingTime = 0

            startTimer()

            return fileURL

        } catch {
            print("❌ Erreur startRecording:", error.localizedDescription)
            return nil
        }
    }

    func pauseRecording() {
        guard isRecording, !isPaused else { return }

        recorder?.pause()
        isPaused = true
        stopTimer()
    }

    func resumeRecording() {
        guard isRecording, isPaused else { return }

        recorder?.record()
        isPaused = false
        startTimer()
    }

    func finishRecording() -> URL? {
        let url = currentFileURL

        recorder?.stop()
        recorder = nil

        stopTimer()

        isRecording = false
        isPaused = false

        try? AVAudioSession.sharedInstance().setActive(false)

        return url
    }

    func cancelRecording() {
        let url = currentFileURL

        recorder?.stop()
        recorder = nil

        stopTimer()

        isRecording = false
        isPaused = false
        recordingTime = 0
        currentFileURL = nil

        if let url = url {
            try? FileManager.default.removeItem(at: url)
        }

        try? AVAudioSession.sharedInstance().setActive(false)
    }

    private func startTimer() {
        timer?.invalidate()

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.recordingTime += 1

            if self.recordingTime >= self.maxDuration {
                _ = self.finishRecording()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

extension AudioRecorderService: AVAudioRecorderDelegate {}
