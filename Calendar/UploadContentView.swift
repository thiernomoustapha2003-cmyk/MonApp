import SwiftUI
import PhotosUI
import AVKit
import AVFoundation
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
import UniformTypeIdentifiers

struct UploadContentView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var selectedItem: PhotosPickerItem?
    @State private var mediaData: Data?
    @State private var videoURL: URL?
    @State private var isVideo = false

    @State private var caption = ""
    @FocusState private var isTyping: Bool
    @State private var isUploading = false
    @State private var progress: Double = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {

                // PREVIEW
                Group {
                    if let data = mediaData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 300)
                            .cornerRadius(12)
                    }
                    else if let videoURL {
                        VideoPlayer(player: AVPlayer(url: videoURL))
                            .frame(height: 300)
                            .cornerRadius(12)
                    }
                    else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.12))
                            .frame(height: 300)
                            .overlay(Text("Sélectionne une image ou vidéo"))
                    }
                }

                // PICKER
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .any(of: [.videos, .images]),
                    preferredItemEncoding: .current
                ) {
                    UploadButtonUI(title: "Choisir photo ou vidéo", icon: "plus.circle.fill")
                }
                .onChange(of: selectedItem) { newItem in
                    guard let newItem else { return }
                    Task { await loadMedia(from: newItem) }
                }

                // CAPTION (TikTok-like)
                ZStack(alignment: .topLeading) {
                    if caption.isEmpty {
                        Text("Écris une description... #hashtag @tag")
                            .foregroundColor(.gray)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                    }
                    TextEditor(text: $caption)
                        .focused($isTyping)
                        .frame(minHeight: 90, maxHeight: 160)
                        .padding(6)
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                }
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.2)))

                Spacer()

                // UPLOAD BUTTON
                Button {
                    Task { await uploadPost() }
                } label: {
                    if isUploading {
                        ProgressView(value: progress)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Publier")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .disabled((mediaData == nil && videoURL == nil) || isUploading)
            }
            .padding()
            .navigationTitle("Nouvelle publication")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
        .onTapGesture { isTyping = false }
    }

    // MARK: LOAD MEDIA
    func loadMedia(from item: PhotosPickerItem) async {
        // Try video first (MovieTransferable)
        do {
            if let movie = try? await item.loadTransferable(type: MovieTransferable.self) {
                await MainActor.run {
                    self.videoURL = movie.url
                    self.mediaData = nil
                    self.isVideo = true
                }
                print("VIDEO OK:", movie.url)
                return
            }
        }

        // Then image
        do {
            if let data = try? await item.loadTransferable(type: Data.self) {
                await MainActor.run {
                    self.mediaData = data
                    self.videoURL = nil
                    self.isVideo = false
                }
                print("IMAGE OK")
                return
            }
        }
    }

    // MARK: UPLOAD POST
    func uploadPost() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("❌ user not logged in")
            return
        }

        let postId = UUID().uuidString
        let db = Firestore.firestore()

        await MainActor.run {
            isUploading = true
            progress = 0.05
        }

        var mediaURLString = ""
        var type = "image"

        do {
            if isVideo, let videoURL {
                type = "video"

                // optionnel : mettre un petit progrès
                await MainActor.run { progress = 0.1 }

                // Convertir + uploader via VideoUploadService (la continuation renvoie String non-optionnel)
                let uploadedURL: String = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<String, Error>) in
                    VideoUploadService.shared.uploadVideo(originalURL: videoURL) { urlString in
                        if let u = urlString {
                            cont.resume(returning: u) // renvoie une String non-optionnelle
                        } else {
                            let err = NSError(domain: "VideoUpload", code: -1, userInfo: [NSLocalizedDescriptionKey: "Upload failed"])
                            cont.resume(throwing: err)
                        }
                    }
                }

                // ici uploadedURL est une String sûre (non-optionnelle)
                mediaURLString = uploadedURL
            
                type = "video"
            } else if let mediaData {
                // image upload
                let filename = "\(uid)/\(postId).jpg"
                let ref = Storage.storage().reference().child("posts/\(filename)")
                let metadata = StorageMetadata()
                metadata.contentType = "image/jpeg"

                let _ = try await ref.putDataAsync(mediaData, metadata: metadata)
                let downloadURL = try await ref.downloadURL()
                mediaURLString = downloadURL.absoluteString
                type = "image"
            } else {
                throw NSError(domain: "no_media", code: -1)
            }

            await MainActor.run { progress = 0.75 }

            // fetch user info
            let userDoc = try await db.collection("users").document(uid).getDocument()
            let creatorName = userDoc.data()?["name"] as? String ?? "Creator"
            let avatar = userDoc.data()?["avatar"] as? String ?? ""

            // save post
            try await db.collection("posts").document(postId).setData([
                "creatorId": uid,
                "creatorName": creatorName,
                "creatorAvatar": avatar,
                "mediaURL": mediaURLString,
                "caption": caption,
                "type": type,
                "likesCount": 0,
                "commentsCount": 0,
                "viewsCount": 0,
                "savesCount": 0,
                "createdAt": Timestamp()
            ])

            await MainActor.run { progress = 1 }
            try? await Task.sleep(nanoseconds: 500_000_000)
            dismiss()
        } catch {
            print("UPLOAD ERROR:", error)
            // si 403 -> vérifier Storage rules / GoogleService-Info.plist / Auth
        }

        await MainActor.run { isUploading = false }
    }
}
