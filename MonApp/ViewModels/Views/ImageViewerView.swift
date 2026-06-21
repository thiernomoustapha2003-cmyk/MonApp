//
//  ImageViewerView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 20/06/2026.
//

import SwiftUI
import Photos
import UIKit
import FirebaseFirestore
import FirebaseAuth
import Vision
import FirebaseFunctions
import CoreImage
import CoreImage.CIFilterBuiltins



struct ImageViewerView: View {
    
    let imageUrl: String
    var onOpenMessageMenu: (() -> Void)? = nil
    
    
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1
    @State private var shareItems: [Any] = []
    @State private var showShareSheet = false
    @State private var showReportSheet = false
    @State private var selectedReason: ReportReason?
    @State private var isFavorite = false
    @State private var toastMessage = ""
    @State private var showToast = false
    @State private var showOCRSheet = false
    @State private var detectedText = ""
    @State private var isReadingText = false
    @State private var showAIImageSheet = false
    @State private var aiImageResult = ""
    @State private var isAnalyzingImage = false
    @State private var showQRSheet = false
    @State private var qrResult = ""
    @State private var isScanningQR = false
    @State private var showStyleBooking = false
    @State private var showImageMenu = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            AsyncImage(url: URL(string: imageUrl)) { image in
                image
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .simultaneousGesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = value
                            }
                    )
                    .onLongPressGesture {
                        if let onOpenMessageMenu = onOpenMessageMenu {
                            onOpenMessageMenu()
                        } else {
                            showImageMenu = true
                        }
                    }
            } placeholder: {
                ProgressView()
                    .tint(.white)
            }
            
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.35))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Button {
                        // menu plus tard
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.35))
                            .clipShape(Circle())
                    }
                }
                .padding()
                
                Spacer()
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 28) {
                        ForEach(ImageViewerAction.allCases) { action in
                            imageActionButton(action.icon, action.title) {
                                handleAction(action)
                            }
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 16)
                }
                .background(.ultraThinMaterial)
            }
            if showToast {
                VStack {
                    Spacer()
                    
                    Text(toastMessage)
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.75))
                        .cornerRadius(18)
                        .padding(.bottom, 95)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.easeInOut(duration: 0.25), value: showToast)
            }
            
            
        }
        .sheet(isPresented: $showShareSheet) {
            ActivityViewController(activityItems: shareItems)
        }
        .sheet(isPresented: $showOCRSheet) {
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if isReadingText {
                            HStack {
                                ProgressView()
                                Text("Lecture du texte...")
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Text(detectedText.isEmpty ? "Aucun texte détecté." : detectedText)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.12))
                            .cornerRadius(14)
                        Button {
                            UIPasteboard.general.string = detectedText
                            
                            DispatchQueue.main.async {
                                showQuickToast("📋 Texte copié")
                            }
                        } label: {
                            HStack {
                                Image(systemName: "doc.on.doc.fill")
                                Text("Copier le texte")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(detectedText.isEmpty ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                        }
                        .disabled(detectedText.isEmpty || detectedText == "Aucun texte détecté.")
                    }
                    .padding()
                }
                .navigationTitle("Texte détecté")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .sheet(isPresented: $showAIImageSheet) {
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if isAnalyzingImage {
                            HStack {
                                ProgressView()
                                Text("Analyse de l’image...")
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Text(aiImageResult.isEmpty ? "L’analyse apparaîtra ici." : aiImageResult)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.blue.opacity(0.08))
                            .cornerRadius(14)
                        
                        Button {
                            UIPasteboard.general.string = aiImageResult
                            showQuickToast("✅ Analyse copiée")
                        } label: {
                            HStack {
                                Image(systemName: "doc.on.doc.fill")
                                Text("Copier l’analyse")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(aiImageResult.isEmpty ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                        }
                        .disabled(aiImageResult.isEmpty)
                    }
                    .padding()
                }
                .navigationTitle("Analyse IA")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .sheet(isPresented: $showQRSheet) {
            NavigationView {
                VStack(alignment: .leading, spacing: 16) {
                    if isScanningQR {
                        HStack {
                            ProgressView()
                            Text("Scan QR en cours...")
                                .foregroundColor(.gray)
                        }
                    }

                    Text(qrResult.isEmpty ? "Aucun QR code détecté." : qrResult)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.12))
                        .cornerRadius(14)

                    Button {
                        UIPasteboard.general.string = qrResult
                        showQuickToast("✅ QR copié")
                    } label: {
                        Text("Copier le résultat")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(qrResult.isEmpty ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }
                    .disabled(qrResult.isEmpty)

                    Spacer()
                }
                .padding()
                .navigationTitle("Scanner QR")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .sheet(isPresented: $showStyleBooking) {

            NavigationView {

                StyleBookingAssistantView(
                    imageUrl: imageUrl
                )
            }
        }
        .sheet(isPresented: $showReportSheet) {
            
            NavigationView {
                
                List {
                    
                    ForEach(ReportReason.allCases) { reason in
                        
                        Button {
                            sendReport(reason)
                            showReportSheet = false
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                
                                Text(reason.rawValue)
                                    .foregroundColor(.red)
                                    .font(.body.weight(.semibold))
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.red.opacity(0.7))
                            }
                            .padding()
                            .background(Color.red.opacity(0.10))
                            .cornerRadius(14)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .navigationTitle("Signaler")
            }
        }
        .sheet(isPresented: $showStyleBooking) {

            NavigationView {

                StyleBookingAssistantView(
                    imageUrl: imageUrl
                )
            }
        }
        .confirmationDialog(
            "Actions de l'image",
            isPresented: $showImageMenu,
            titleVisibility: .visible
        ) {

            Button("❤️ Réagir") {

            }

            Button("↩️ Répondre") {

            }

            Button("📤 Partager") {
                shareImage()
            }

            Button("⭐ Favori") {
                addToFavorites()
            }

            Button("🚨 Signaler") {
                showReportSheet = true
            }

            Button("Annuler", role: .cancel) { }
        }
        
        .onAppear {
            checkIfFavorite()
        }
        
    }

    func showQuickToast(_ message: String) {
        toastMessage = message
        showToast = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            showToast = false
        }
    }
    
    
    
    func imageActionButton(_ icon: String, _ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: title == "Favori" ? (isFavorite ? "star.fill" : "star") : icon)
                    .font(.system(size: 26))
                    .foregroundColor(title == "Favori" && isFavorite ? .yellow : .white)
                
                Text(title)
                    .font(.caption2)
                    .lineLimit(1)
                    .foregroundColor(title == "Favori" && isFavorite ? .yellow : .white)
            }
        }
    }
    
    func handleAction(_ action: ImageViewerAction) {
        switch action {
        case .save:
            saveImageToPhotos()
            
        case .share:
            shareImage()
            
        case .report:
            showReportSheet = true
            
        case .favorite:
            addToFavorites()
            
        case .readText:
            readTextFromImage()
            
        case .aiDescribe:
            analyzeImageWithAI()
            
        case .scanQR:
            scanQRCodeFromImage()
            
        case .bookStyle:
            showStyleBooking = true
        }
    }
    
    func saveImageToPhotos() {
        guard let url = URL(string: imageUrl) else {
            print("❌ URL image invalide")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("❌ Erreur téléchargement image:", error.localizedDescription)
                return
            }
            
            guard let data = data,
                  let image = UIImage(data: data) else {
                print("❌ Image illisible")
                return
            }
            
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            print("✅ Image enregistrée dans Photos")
            DispatchQueue.main.async {
                showQuickToast("Image enregistrée")
            }
        }.resume()
    }
    
    func shareImage() {
        guard let url = URL(string: imageUrl) else { return }
        
        shareItems = [url]
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showQuickToast("Ouverture du partage")
            showShareSheet = true
        }
    }
    func sendReport(_ reason: ReportReason) {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        Firestore.firestore()
            .collection("reports")
            .addDocument(data: [
                "reportedBy": uid,
                "reason": reason.rawValue,
                "mediaUrl": imageUrl,
                "source": "imageViewer",
                "status": "pending",
                "createdAt": Timestamp(date: Date())
            ]) { error in
                DispatchQueue.main.async {
                    if error == nil {
                        showQuickToast("Signalement envoyé")
                    } else {
                        showQuickToast("Erreur signalement")
                    }
                }
            }
    }
    func addToFavorites() {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("favoriteMedia")
            .addDocument(data: [
                "mediaUrl": imageUrl,
                "type": "image",
                "createdAt": Timestamp(date: Date())
            ]) { error in
                
                if error == nil {
                    DispatchQueue.main.async {
                        isFavorite = true
                        showQuickToast("Ajouté aux favoris")
                    }
                }
            }
    }
    func checkIfFavorite() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("favoriteMedia")
            .whereField("mediaUrl", isEqualTo: imageUrl)
            .limit(to: 1)
            .getDocuments { snapshot, _ in
                DispatchQueue.main.async {
                    isFavorite = !(snapshot?.documents.isEmpty ?? true)
                }
            }
    }
    func readTextFromImage() {
        guard let url = URL(string: imageUrl) else { return }
        
        isReadingText = true
        detectedText = ""
        showOCRSheet = true
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                DispatchQueue.main.async {
                    isReadingText = false
                    detectedText = "Erreur : \(error.localizedDescription)"
                }
                return
            }
            
            guard let data = data,
                  let uiImage = UIImage(data: data),
                  let cgImage = uiImage.cgImage else {
                DispatchQueue.main.async {
                    isReadingText = false
                    detectedText = "Image illisible."
                }
                return
            }
            
            let request = VNRecognizeTextRequest { request, error in
                DispatchQueue.main.async {
                    isReadingText = false
                    
                    if let error = error {
                        detectedText = "Erreur OCR : \(error.localizedDescription)"
                        return
                    }
                    
                    let observations = request.results as? [VNRecognizedTextObservation] ?? []
                    
                    let text = observations.compactMap {
                        $0.topCandidates(1).first?.string
                    }.joined(separator: "\n")
                    
                    detectedText = text.isEmpty ? "Aucun texte détecté." : text
                }
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    isReadingText = false
                    detectedText = "Erreur analyse image."
                }
            }
        }.resume()
    }
    func analyzeImageWithAI() {
        isAnalyzingImage = true
        aiImageResult = ""
        showAIImageSheet = true

        let functions = Functions.functions(region: "us-central1")

        functions.httpsCallable("analyzeImageMessage").call([
            "imageUrl": imageUrl
        ]) { result, error in
            DispatchQueue.main.async {
                isAnalyzingImage = false

                if let error = error {
                    aiImageResult = "Erreur analyse : \(error.localizedDescription)"
                    return
                }

                guard let data = result?.data as? [String: Any] else {
                    aiImageResult = "Réponse invalide."
                    return
                }

                aiImageResult = data["analysis"] as? String ?? "Aucune analyse disponible."
            }
        }
    }
    func scanQRCodeFromImage() {
        guard let url = URL(string: imageUrl) else { return }

        isScanningQR = true
        qrResult = ""
        showQRSheet = true

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                DispatchQueue.main.async {
                    isScanningQR = false
                    qrResult = "Erreur : \(error.localizedDescription)"
                }
                return
            }

            guard let data = data,
                  let uiImage = UIImage(data: data),
                  let ciImage = CIImage(image: uiImage) else {
                DispatchQueue.main.async {
                    isScanningQR = false
                    qrResult = "Image illisible."
                }
                return
            }

            let detector = CIDetector(
                ofType: CIDetectorTypeQRCode,
                context: nil,
                options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]
            )

            let features = detector?.features(in: ciImage) as? [CIQRCodeFeature] ?? []
            let results = features.compactMap { $0.messageString }

            DispatchQueue.main.async {
                isScanningQR = false
                qrResult = results.isEmpty ? "Aucun QR code détecté." : results.joined(separator: "\n\n")
            }
        }.resume()
    }
    
    
}


