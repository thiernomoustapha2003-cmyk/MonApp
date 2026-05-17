import AVFoundation
import UIKit

class VideoFrameExtractor {
    
    static func generateFrames(url: URL, count: Int = 8, completion: @escaping ([UIImage]) -> Void) {
        
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 300, height: 300)
        
        let duration = CMTimeGetSeconds(asset.duration)
        
        guard duration > 0 else {
            completion([])
            return
        }
        
        var times: [NSValue] = []
        
        for i in 0..<count {
            let seconds = Double(i) * duration / Double(count)
            let time = CMTime(seconds: seconds, preferredTimescale: 600)
            times.append(NSValue(time: time))
        }
        
        var imagesDict: [Int: UIImage] = [:]
        var completed = 0
        
        generator.generateCGImagesAsynchronously(forTimes: times) { requestedTime, cgImage, _, _, _ in
            
            defer {
                completed += 1
                
                // 🔥 quand tout est fini (même si certaines frames échouent)
                if completed == count {
                    
                    let sorted = imagesDict
                        .sorted(by: { $0.key < $1.key })
                        .map { $0.value }
                    
                    DispatchQueue.main.async {
                        completion(sorted)
                    }
                }
            }
            
            guard let cgImage = cgImage else { return }
            
            let image = UIImage(cgImage: cgImage)
            
            // 🔥 retrouver index
            if let index = times.firstIndex(where: {
                CMTimeCompare($0.timeValue, requestedTime) == 0
            }) {
                imagesDict[index] = image
            }
        }
    }
}
