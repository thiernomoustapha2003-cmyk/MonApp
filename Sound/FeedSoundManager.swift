import Foundation
import Combine

final class FeedSoundManager: ObservableObject {

    static let shared = FeedSoundManager()
    
    @Published var selectedSound: Sound? = nil
    
    private init() {}
}
