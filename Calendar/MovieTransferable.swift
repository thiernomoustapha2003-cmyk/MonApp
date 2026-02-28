import Foundation
import UniformTypeIdentifiers
import SwiftUI

struct MovieTransferable: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .movie) { received in
            let tmp = FileManager.default.temporaryDirectory
            let fileURL = tmp.appendingPathComponent(UUID().uuidString + ".mov")
            try FileManager.default.copyItem(at: received.file, to: fileURL)
            return MovieTransferable(url: fileURL)
        }
    }
}
