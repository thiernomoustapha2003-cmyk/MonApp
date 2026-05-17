import Foundation
import Combine

final class FeedPlaybackManager: ObservableObject {

    static let shared = FeedPlaybackManager()

    @Published var currentVisiblePostId: String? = nil

    private init() {}

    func setCurrent(postId: String) {
        DispatchQueue.main.async {
            self.currentVisiblePostId = postId
        }
    }

    func shouldPlay(postId: String) -> Bool {
        return currentVisiblePostId == postId
    }
}
