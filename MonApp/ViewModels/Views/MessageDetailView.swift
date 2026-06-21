import SwiftUI
import Firebase
import FirebaseAuth
import PhotosUI
import AVKit
import Photos
import FirebaseStorage
import UniformTypeIdentifiers
import FirebaseFunctions


struct MessageDetailView: View {

    let conversationId: String
    let otherUserName: String
    
    
    @State private var activeImage: ChatImageItem? = nil
    
    
    @State private var showTranscriptionSheet = false
    @State private var messageToTranscribe: Message? = nil
    @State private var transcriptionText = ""
    @State private var isTranscribing = false
    @State private var isTranslating = false
    @State private var translatedText = ""
    @State private var showTranslationSheet = false
    @State private var messageToTranslate: Message? = nil
    @State private var selectedTranslationLanguage = "Français"
    let translationLanguages = [
        "Français",
        "Anglais",
        "Espagnol",
        "Arabe",
        "Portugais",
        "Allemand",
        "Italien",
        "Turc",
        "Chinois",
        "Wolof",
        "Bambara",
        "Lingala",
        "Swahili",
        "Hausa",
        "Yoruba",
        "Igbo",
        "Somali",
        "Soussou",
        "Malinké",
        "Pulaar / Fulani / Peul"
    ]

    @State private var messageText = ""
    @State private var messages: [Message] = []
    
    @State private var messageToReport: Message? = nil
    @State private var showReportSheet = false
    @State private var reportReason = ""
    
    @State private var shareItems: [Any] = []
    @State private var showShareSheet = false
    
    @State private var selectedMediaItems: [PhotosPickerItem] = []
    @State private var showMediaPreview = false
    @State private var previewMedias: [ChatPreviewMedia] = []
    @State private var isUploadingMedia = false
    
    @StateObject private var audioRecorder = AudioRecorderService.shared
    @State private var recordedAudioURL: URL? = nil
    @State private var isUploadingAudio = false
    
    @State private var sendAudioAsViewOnce = false
    @State private var otherListeningMessageId: String? = nil
    @State private var otherListeningProgress: Double = 0
    
    @State private var activeViewOnceMessage: Message?
    @State private var showAudioCall = false
    @State private var showVideoCall = false
    @State private var currentCallId: String? = nil
    @State private var incomingCallId: String? = nil
    @State private var incomingCallType = "audio"
    @State private var showIncomingCall = false
    
    
    
    
    @State private var activeVideo: ChatVideoItem? = nil
    
    @State private var sendAsViewOnce = false
    
    @State private var otherUserTyping = false
    @State private var otherUserRecording = false
    
    
    
    @State private var replyingTo: Message? = nil
    @State private var selectedReactionMessage: Message? = nil
    @State private var showReactionPicker = false
    @State private var selectedMenuMessage: Message? = nil
    //@State private var selectedMenuMessageId: String? = nil
    @State private var pinnedMessage: Message? = nil
    //@State private var showMessageMenu = false
    @State private var showFullEmojiPicker = false
    let reactionEmojis = ["👍", "❤️", "😂", "😮", "😢", "🙏", "➕"]
    let allEmojis = EmojiData.all

    var currentUserId: String {
        Auth.auth().currentUser?.uid ?? ""
    }
    var body: some View {
        VStack {
            
            ScrollViewReader { proxy in
                
                if let pinnedMessage = pinnedMessage {
                    Button {
                        withAnimation {
                            proxy.scrollTo(pinnedMessage.id, anchor: .center)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "pin.fill")
                                .foregroundColor(.orange)

                            Text(pinnedMessagePreview(pinnedMessage))
                                .font(.caption)
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            Spacer()

                            Image(systemName: "chevron.down")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.12))
                    }
                    .buttonStyle(.plain)
                }
                
                ScrollView {
                    VStack(spacing: 10) {
                        
                        ForEach(messages) { message in
                            messageBubble(message)
                                .id(message.id)
                                .gesture(
                                    DragGesture(minimumDistance: 20)
                                        .onEnded { value in
                                            if value.translation.width > 60 {
                                                replyingTo = message
                                            }
                                        }
                                )
                                .onLongPressGesture {
                                    selectedMenuMessage = message
                                }
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _ in
                    if let last = messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            
            VStack(spacing: 6) {
                
                if let replyingTo = replyingTo {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Réponse à \(replyingTo.senderName)")
                                .font(.caption.bold())
                                .foregroundColor(.blue)
                            
                            Text(replyingTo.text)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        Button {
                            self.replyingTo = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(10)
                    .background(Color.gray.opacity(0.12))
                    .cornerRadius(10)
                }
                
                if audioRecorder.isRecording {
                    VStack(spacing: 8) {

                        HStack(spacing: 14) {
                            Text(formatAudioTime(audioRecorder.recordingTime))
                                .font(.caption.bold())
                                .foregroundColor(.red)

                            Button {
                                pauseOrResumeAudio()
                            } label: {
                                Image(systemName: audioRecorder.isPaused ? "play.circle.fill" : "pause.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.orange)
                            }

                            Button {
                                cancelAudioRecording()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.red)
                            }

                            Button {
                                finishAndSendAudio()
                            } label: {
                                Image(systemName: sendAudioAsViewOnce ? "lock.circle.fill" : "checkmark.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(sendAudioAsViewOnce ? .blue : .green)
                            }
                        }

                        Toggle(isOn: $sendAudioAsViewOnce) {
                            HStack(spacing: 6) {
                                Image(systemName: "1.circle.fill")
                                    .foregroundColor(sendAudioAsViewOnce ? .blue : .gray)

                                Text("Vocal vue unique")
                                    .font(.caption.bold())
                                    .foregroundColor(sendAudioAsViewOnce ? .blue : .gray)
                            }
                        }
                        .font(.caption)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                        .padding(.horizontal)
                    }
                }
                
                if otherUserRecording {

                    HStack(spacing: 6) {

                        Image(systemName: "mic.fill")
                            .foregroundColor(.red)

                        Text("\(otherUserName) enregistre un vocal...")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)

                } else if otherUserTyping {

                    HStack(spacing: 6) {

                        Image(systemName: "ellipsis.message.fill")
                            .foregroundColor(.blue)

                        Text("\(otherUserName) écrit...")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                }
                
                HStack(spacing: 10) {
                    PhotosPicker(
                        selection: $selectedMediaItems,
                        maxSelectionCount: nil,
                        matching: .any(of: [.images, .videos])
                    ) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .disabled(isUploadingMedia)
                    
                    TextField("Message...", text: $messageText)
                        .onChange(of: messageText) { _, newValue in

                            if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                ChatPresenceService.shared.setTyping(
                                    conversationId: conversationId,
                                    isTyping: false
                                )
                            } else {
                                ChatPresenceService.shared.setTyping(
                                    conversationId: conversationId,
                                    isTyping: true
                                )
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.gray.opacity(0.10))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                        )

                    Button {
                        handleAudioButton()
                    } label: {
                        Image(systemName: audioRecorder.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                            .font(.system(size: 38))
                            .foregroundColor(audioRecorder.isRecording ? .red : .blue)
                            .frame(width: 44, height: 44)
                    }
                    .disabled(isUploadingAudio)
                    
                    Button("Envoyer") {
                        sendMessage()
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding()
        }
            
        .navigationTitle(otherUserName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    CallService.shared.startCall(
                        conversationId: conversationId,
                        receiverName: otherUserName,
                        type: "audio"
                    ) { callId in
                        currentCallId = callId
                        showAudioCall = true
                    }

                    showAudioCall = true
                } label: {
                    Image(systemName: "phone.fill")
                }

                Button {
                    CallService.shared.startCall(
                        conversationId: conversationId,
                        receiverName: otherUserName,
                        type: "video"
                    ) { callId in
                        currentCallId = callId
                        showVideoCall = true
                    }

                    showVideoCall = true
                } label: {
                    Image(systemName: "video.fill")
                }
            }
        }
        .confirmationDialog("Réagir au message", isPresented: $showReactionPicker) {
            ForEach(reactionEmojis, id: \.self) { emoji in
                Button(emoji) {
                    if emoji == "➕" {
                        showFullEmojiPicker = true
                    } else if let message = selectedReactionMessage {
                        reactToMessage(message, emoji: emoji)
                    }
                }
            }
            
            Button("Annuler", role: .cancel) { }
        }
        
        
        .sheet(isPresented: $showFullEmojiPicker) {
            EmojiPickerView(emojis: allEmojis) { emoji in
                if let message = selectedReactionMessage {
                    reactToMessage(message, emoji: emoji)
                }
                showFullEmojiPicker = false
            }
        }
        
        .sheet(isPresented: $showMediaPreview) {
            ChatMediaPreviewView(
                medias: $previewMedias,
                sendAsViewOnce: $sendAsViewOnce,
                onCancel: {
                    previewMedias = []
                    selectedMediaItems = []
                    sendAsViewOnce = false
                    showMediaPreview = false
                },
                onSend: {
                    sendPreviewMedias()
                }
            )
        }
        
        .fullScreenCover(item: $activeVideo) { item in
            NativeVideoPlayerScreen(url: item.url)
        }

        .fullScreenCover(isPresented: $showIncomingCall) {
            IncomingCallView(
                callerName: otherUserName,
                callType: incomingCallType,
                onAccept: {
                    if let callId = incomingCallId {
                        CallService.shared.acceptCall(callId: callId)
                        currentCallId = callId
                    }

                    showIncomingCall = false

                    if incomingCallType == "video" {
                        showVideoCall = true
                    } else {
                        showAudioCall = true
                    }
                },
                onDecline: {
                    if let callId = incomingCallId {
                        CallService.shared.declineCall(callId: callId)
                        CallService.shared.saveMissedCall(
                            conversationId: conversationId,
                            type: incomingCallType
                        )
                    }

                    showIncomingCall = false
                }
            )
        }
        
        
        
        .fullScreenCover(isPresented: $showAudioCall) {
            CallScreenView(
                name: otherUserName,
                avatarURL: nil,
                mode: .audio,
                callId: currentCallId,
                conversationId: conversationId
            ) { duration in
                if let callId = currentCallId {
                    CallService.shared.endCall(
                        callId: callId,
                        conversationId: conversationId,
                        type: "audio",
                        duration: duration
                    )
                }
            }
        }

        .fullScreenCover(isPresented: $showVideoCall) {
            CallScreenView(
                name: otherUserName,
                avatarURL: nil,
                mode: .video,
                callId: currentCallId,
                conversationId: conversationId
            ) { duration in
                if let callId = currentCallId {
                    CallService.shared.endCall(
                        callId: callId,
                        conversationId: conversationId,
                        type: "video",
                        duration: duration
                    )
                }
            }
        }
        
        
        
        .fullScreenCover(item: $activeImage) { item in
            ImageViewerView(
                imageUrl: item.url,
                onOpenMessageMenu: {

                    activeImage = nil

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        selectedMenuMessage = item.message
                    }
                }
            )
        }
        
        .fullScreenCover(item: $activeViewOnceMessage) { message in

            ViewOnceMediaViewer(
                type: message.type,
                url: message.imageUrl ?? message.videoUrl ?? ""
            ) {
                markViewOnceAsOpened(message)
                activeViewOnceMessage = nil
            }
        }
         
        .sheet(isPresented: $showReportSheet) {
            VStack(spacing: 18) {
                Text("Signaler ce message")
                    .font(.headline)

                Text("Choisis une raison")
                    .font(.caption)
                    .foregroundColor(.gray)

                ForEach([
                    "Contenu inapproprié",
                    "Harcèlement ou insultes",
                    "Spam ou arnaque",
                    "Nudité ou contenu choquant",
                    "Violence ou menace",
                    "Autre"
                ], id: \.self) { reason in
                    Button {
                        reportReason = reason

                        if let message = messageToReport {
                            reportMessage(message, reason: reason)
                        }

                        showReportSheet = false
                    } label: {
                        HStack {
                            Text(reason)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.10))
                        .cornerRadius(14)
                    }
                    .buttonStyle(.plain)
                }

                Button("Annuler", role: .cancel) {
                    showReportSheet = false
                }
                .padding(.top, 8)
            }
            .padding()
            .presentationDetents([.medium])
        }
        
        .sheet(isPresented: $showTranslationSheet) {

            NavigationView {

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {

                        Text("Message original")
                            .font(.headline)

                        Text((messageToTranslate?.text.isEmpty ?? true) ? "Aucun texte à traduire" : messageToTranslate?.text ?? "")
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)

                        Text("Traduire vers")
                            .font(.headline)

                        Picker("Langue", selection: $selectedTranslationLanguage) {
                            ForEach(translationLanguages, id: \.self) { language in
                                Text(language).tag(language)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding()
                        .background(Color.gray.opacity(0.10))
                        .cornerRadius(12)

                        Button {
                            translateSelectedMessage()
                        } label: {
                            Text("Traduire")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(14)
                        }

                        Text("Résultat")
                            .font(.headline)

                        Text(translatedText.isEmpty ? "La traduction apparaîtra ici." : translatedText)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.blue.opacity(0.08))
                            .cornerRadius(12)
                    }
                    .padding()
                }
                .navigationTitle("Traduction")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        
        .sheet(isPresented: $showTranscriptionSheet) {
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {

                        Text("Transcription vocale")
                            .font(.headline)

                        Text("Traduire vers")
                            .font(.headline)

                        Picker("Langue", selection: $selectedTranslationLanguage) {
                            ForEach(translationLanguages, id: \.self) { language in
                                Text(language).tag(language)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding()
                        .background(Color.gray.opacity(0.10))
                        .cornerRadius(12)

                        if isTranscribing {
                            HStack {
                                ProgressView()
                                Text("Transcription en cours...")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                        }

                        Text(transcriptionText.isEmpty ? "Le texte du vocal apparaîtra ici." : transcriptionText)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.blue.opacity(0.08))
                            .cornerRadius(14)

                        Button {
                            transcribeSelectedAudio()
                        } label: {
                            Text("Retranscrire / Traduire")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(14)
                        }
                    }
                    .padding()
                }
                .navigationTitle("Transcription")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        
        
        .sheet(item: $selectedMenuMessage) { message in
            ScrollView {
                VStack(spacing: 16) {

                    HStack(spacing: 14) {
                        ForEach(["👍","❤️","😂","😮","😢","🙏"], id: \.self) { emoji in
                            Button {
                                reactToMessage(message, emoji: emoji)
                                selectedMenuMessage = nil
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 30))
                            }
                        }

                        Button {
                            selectedReactionMessage = message
                            selectedMenuMessage = nil

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                showFullEmojiPicker = true
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.12))
                    .cornerRadius(22)

                    VStack(spacing: 0) {
                        menuButton("↩️", "Répondre") {
                            replyingTo = message
                            selectedMenuMessage = nil
                        }

                        menuButton("🌍", "Traduire") {
                            messageToTranslate = message
                            translatedText = message.text
                            selectedMenuMessage = nil

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                showTranslationSheet = true
                            }
                        }

                        if message.type == "audio" {
                            menuButton("📝", "Transcrire le vocal") {
                                messageToTranscribe = message
                                transcriptionText = ""
                                selectedMenuMessage = nil

                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    showTranscriptionSheet = true
                                }
                            }
                        }

                        menuButton("📤", "Partager") {
                            shareMessage(message)
                            selectedMenuMessage = nil
                        }

                        menuButton("⬇️", "Télécharger") {
                            downloadMessageMedia(message)
                            selectedMenuMessage = nil
                        }

                        menuButton("📌", message.isPinned ? "Désépingler" : "Épingler") {
                            togglePinMessage(message)
                            selectedMenuMessage = nil
                        }

                        menuButton("⚠️", "Signaler") {
                            messageToReport = message
                            reportReason = ""
                            selectedMenuMessage = nil

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                showReportSheet = true
                            }
                        }

                        menuButton("🗑", "Supprimer pour moi", isDestructive: true) {
                            deleteMessageForMe(message)
                            selectedMenuMessage = nil
                        }

                        if message.senderId == currentUserId {
                            menuButton("🗑", "Supprimer pour tout le monde", isDestructive: true) {
                                deleteMessageForEveryone(message)
                                selectedMenuMessage = nil
                            }
                        }
                    }
                    .background(Color.gray.opacity(0.08))
                    .cornerRadius(24)
                }
                .padding()
            }
            .presentationDetents([.medium, .large])
        }
        
        .sheet(isPresented: $showShareSheet) {
            ChatShareSheet(items: shareItems)
        }
        
        .onAppear {
            listenMessages()
            listenPresence()
            listenIncomingCalls()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                markConversationAsSeen()
            }
        }
        .onChange(of: selectedMediaItems) { oldValue, newValue in
            prepareSelectedMedias()
        }
    }
    

        
    func messageBubble(_ message: Message) -> some View {

        if message.type == "system" || message.senderId == "system" {
            return AnyView(
                Text(message.text)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(8)
                    .background(Color.gray.opacity(0.12))
                    .cornerRadius(10)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            )
        }

        if message.type == "deleted" {
            return AnyView(
                HStack {
                    Spacer()
                    Text("🚫 Ce message a été supprimé")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .italic()
                        .padding(10)
                        .background(Color.gray.opacity(0.12))
                        .cornerRadius(12)
                    Spacer()
                }
            )
        }
        
        if message.isViewOnce,
           message.openedBy.contains(currentUserId),
           message.senderId != currentUserId {

            return AnyView(
                HStack {
                    Spacer()

                    HStack(spacing: 8) {
                        Image(systemName: message.type == "audio" ? "mic.slash.fill" : "lock.fill")
                            .foregroundColor(.gray)

                        Text(message.type == "audio" ? "Vocal déjà écouté" : "Média déjà ouvert")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .italic()
                    }
                    .padding(10)
                    .background(Color.gray.opacity(0.12))
                    .cornerRadius(12)

                    Spacer()
                }
            )
        }
        
        
        let isMine = message.senderId == currentUserId

        return AnyView(
            HStack {
                if isMine { Spacer() }

                VStack(alignment: isMine ? .trailing : .leading, spacing: 4) {

                    if message.isPinned {

                        HStack(spacing: 4) {

                            Image(systemName: "pin.fill")
                                .font(.caption2)
                                .foregroundColor(.orange)

                            Text("Épinglé")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    
                    if !isMine {
                        Text(message.senderName)
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }

                    if let replyText = message.replyToText {

                        VStack(alignment: .leading, spacing: 2) {

                            Text(message.replyToSender ?? "Utilisateur")
                                .font(.caption2)
                                .bold()
                                .foregroundColor(.blue)

                            Text(replyText)
                                .font(.caption2)
                                .lineLimit(2)
                                .foregroundColor(.gray)
                        }
                        .padding(8)
                        .background(Color.black.opacity(0.05))
                        .cornerRadius(8)
                    }
                    
                    if message.isViewOnce && message.type != "audio" {

                        if message.opened {

                            HStack(spacing: 8) {

                                Image(systemName: "lock.fill")
                                    .foregroundColor(.gray)

                                Text(formatOpenedTime(message.openedAt))
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                            .padding(12)
                            .background(Color.gray.opacity(0.12))
                            .cornerRadius(14)

                        } else {

                            Button {
                                activeViewOnceMessage = message
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "lock.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.blue)

                                    Text(
                                        message.type == "image"
                                        ? "Photo vue unique"
                                        : message.type == "audio"
                                        ? "Vocal vue unique"
                                        : "Vidéo vue unique"
                                    )
                                        .font(.caption)
                                }
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(Color.gray.opacity(0.15))
                                )
                            }
                        }
                    }
                    else
                    
                    if message.type == "image",
                       let imageUrl = message.imageUrl {

                        Button {
                            activeImage = ChatImageItem(url: imageUrl, message: message)
                        } label: {

                            AsyncImage(url: URL(string: imageUrl)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 230, height: 260)
                            .clipped()
                            .cornerRadius(16)
                        }
                        .buttonStyle(.plain)

                    } else if message.type == "video",
                              let videoUrl = message.videoUrl,
                              let url = URL(string: videoUrl) {

                        Button {
                            activeVideo = ChatVideoItem(url: url)
                        } label: {
                            ChatVideoThumbnailView(videoURL: url)
                        }
                        .buttonStyle(PlainButtonStyle())

                    } else if message.type == "audio", message.isViewOnce {
                        
                        let currentUserHasOpened = message.openedBy.contains(currentUserId) || message.listenedBy.contains(currentUserId)
                        let otherHasListened = message.listenedBy.contains(where: { $0 != currentUserId }) || message.openedBy.contains(where: { $0 != currentUserId })
                        
                        if isMine {
                            if otherHasListened {
                                HStack(spacing: 8) {
                                    Image(systemName: "mic.slash.fill")
                                        .foregroundColor(.gray)
                                    
                                    Text(formatOpenedTime(message.openedAt).replacingOccurrences(of: "Ouvert", with: "Écouté"))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .italic()
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Color.green.opacity(0.18))
                                .cornerRadius(18)
                            } else {
                                HStack(spacing: 8) {
                                    Image(systemName: "1.circle")
                                    Text("Vocal vue unique")
                                    Text(formatAudioTime(message.audioDuration ?? 0))
                                        .foregroundColor(.gray)
                                }
                                .font(.caption)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Color.green.opacity(0.28))
                                .cornerRadius(18)
                            }
                            
                        } else {
                            if currentUserHasOpened {
                                HStack(spacing: 8) {
                                    Image(systemName: "mic.slash.fill")
                                        .foregroundColor(.gray)
                                    
                                    Text("Vocal déjà écouté")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .italic()
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Color.gray.opacity(0.15))
                                .cornerRadius(18)
                                
                            } else if let audioUrl = message.audioUrl {
                                ChatViewOnceAudioBubble(
                                    audioUrl: audioUrl,
                                    duration: message.audioDuration,
                                    messageId: message.id,
                                    conversationId: conversationId,
                                    listenedBy: message.listenedBy,
                                    isMine: isMine
                                )
                            }
                        }
                    }else if message.type == "audio",
                              let audioUrl = message.audioUrl {

                        if otherListeningMessageId == message.id {

                            HStack(spacing: 6) {

                                Image(systemName: "ear.fill")
                                    .foregroundColor(.blue)

                                ProgressView(value: otherListeningProgress)
                                    .frame(width: 90)

                                Text("\(Int(otherListeningProgress * 100))%")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.blue.opacity(0.12))
                            .cornerRadius(12)
                        }

                        ChatAudioPlayerView(
                            audioUrl: audioUrl,
                            duration: message.audioDuration,
                            messageId: message.id,
                            conversationId: conversationId,
                            listenedBy: message.listenedBy,
                            avatarURL: message.senderAvatar,
                            isMine: isMine,
                            isViewOnce: message.isViewOnce
                        )
                        .frame(maxWidth: 260)
                        .padding(.horizontal, 14)
                
                    } else {
                        Text(message.text)
                            .padding(12)
                            .background(isMine ? Color.blue : Color.gray.opacity(0.25))
                            .foregroundColor(isMine ? .white : .primary)
                            .cornerRadius(14)
                            .frame(maxWidth: 260, alignment: isMine ? .trailing : .leading)
                    }

                    if !message.reactions.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(Array(message.reactions.values), id: \.self) { emoji in
                                Text(emoji)
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(12)
                    }

                    HStack(spacing: 4) {
                        Text(formatMessageTime(message.timestamp))
                            .font(.caption2)
                            .foregroundColor(.gray)

                        if isMine {
                            let otherHasSeen = message.seenBy.contains(where: { $0 != currentUserId })
                            let otherHasListened = message.listenedBy.contains(where: { $0 != currentUserId })

                            if message.type == "audio" {
                                if otherHasListened {
                                    Image(systemName: "headphones")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                } else if otherHasSeen {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                } else {
                                    Image(systemName: "checkmark")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                            } else {
                                if otherHasSeen {
                                    Text("Lu")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                } else {
                                    Text("Envoyé")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }

                if !isMine { Spacer() }
            }
        )
    }

    func togglePinMessage(_ message: Message) {

        Firestore.firestore()
            .collection("conversations")
            .document(conversationId)
            .collection("messages")
            .document(message.id)
            .updateData([
                "isPinned": !message.isPinned
            ])
    }
    

func deleteMessageForMe(_ message: Message) {
    guard let uid = Auth.auth().currentUser?.uid else { return }

    Firestore.firestore()
        .collection("conversations")
        .document(conversationId)
        .collection("messages")
        .document(message.id)
        .updateData([
            "deletedFor": FieldValue.arrayUnion([uid])
        ])
}

func deleteMessageForEveryone(_ message: Message) {
    guard message.senderId == currentUserId else { return }

    let db = Firestore.firestore()
    let now = Timestamp(date: Date())

    db.collection("conversations")
        .document(conversationId)
        .collection("messages")
        .document(message.id)
        .updateData([
            "type": "deleted",
            "text": "🚫 Ce message a été supprimé",
            "imageUrl": FieldValue.delete(),
            "videoUrl": FieldValue.delete(),
            "audioUrl": FieldValue.delete(),
            "reactions": [:],
            "deletedAt": now
        ])

    db.collection("conversations")
        .document(conversationId)
        .updateData([
            "lastMessage": "🚫 Ce message a été supprimé",
            "lastMessagePreview": "🚫 Ce message a été supprimé",
            "lastMessageType": "deleted",
            "updatedAt": now
        ])
}

}



// MARK: - FIRESTORE

extension MessageDetailView {
    
    func listenMessages() {
        let db = Firestore.firestore()
        
        db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .order(by: "createdAt")
            .addSnapshotListener { snapshot, _ in
                
                guard let docs = snapshot?.documents else { return }
                
                let uid = Auth.auth().currentUser?.uid ?? ""
                
                self.messages = docs.compactMap { doc in
                    let data = doc.data()
                    
                    let deletedFor = data["deletedFor"] as? [String] ?? []
                    
                    if deletedFor.contains(uid) {
                        return nil
                    }
                    
                    return Message(
                        id: doc.documentID,
                        senderId: data["senderId"] as? String ?? "",
                        senderName: data["senderName"] as? String ?? "Utilisateur",
                        senderAvatar: data["senderAvatar"] as? String,
                        text: data["text"] as? String ?? "",
                        type: data["type"] as? String ?? "text",
                        imageUrl: data["imageUrl"] as? String,
                        videoUrl: data["videoUrl"] as? String,
                        audioUrl: data["audioUrl"] as? String,
                        audioDuration: data["audioDuration"] as? Double,
                        timestamp: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                        seenBy: data["seenBy"] as? [String] ?? [],
                        listenedBy: data["listenedBy"] as? [String] ?? [],
                        deletedFor: deletedFor,
                        isViewOnce: data["isViewOnce"] as? Bool ?? false,
                        openedBy: data["openedBy"] as? [String] ?? [],
                        opened: data["opened"] as? Bool ?? false,
                        openedAt: (data["openedAt"] as? Timestamp)?.dateValue(),
                        reactions: data["reactions"] as? [String: String] ?? [:],
                        isPinned: data["isPinned"] as? Bool ?? false,
                        replyToMessageId: data["replyToMessageId"] as? String,
                        replyToText: data["replyToText"] as? String,
                        replyToSender: data["replyToSender"] as? String
                    )
                }
                self.pinnedMessage = self.messages.first(where: { $0.isPinned })
                
                
            }
    }
    
    func pinnedMessagePreview(_ message: Message) -> String {
        if message.isViewOnce {
            if message.type == "image" {
                return "📌 Photo vue unique épinglée"
            } else if message.type == "video" {
                return "📌 Vidéo vue unique épinglée"
            } else if message.type == "audio" {
                return "📌 Vocal vue unique épinglé"
            }
        }

        if message.type == "image" {
            return "📌 Photo épinglée"
        } else if message.type == "video" {
            return "📌 Vidéo épinglée"
        } else if message.type == "audio" {
            return "📌 Vocal épinglé"
        }

        return message.text.isEmpty ? "📌 Message épinglé" : message.text
    }
    
    
    func listenPresence() {

        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("conversations")
            .document(conversationId)
            .collection("presence")
            .addSnapshotListener { snapshot, _ in

                guard let docs = snapshot?.documents else { return }

                for doc in docs {

                    if doc.documentID == uid {
                        continue
                    }

                    let data = doc.data()

                    DispatchQueue.main.async {
                        self.otherUserTyping =
                        data["isTyping"] as? Bool ?? false
                        
                        self.otherUserRecording =
                        data["isRecordingAudio"] as? Bool ?? false
                        self.otherListeningMessageId = data["listeningMessageId"] as? String
                        self.otherListeningProgress = data["listeningProgress"] as? Double ?? 0
                    }
                }
            }
    }
    
    func markViewOnceAsOpened(_ message: Message) {
        guard message.isViewOnce else { return }
        guard message.senderId != currentUserId else { return }

        Firestore.firestore()
            .collection("conversations")
            .document(conversationId)
            .collection("messages")
            .document(message.id)
            .updateData([
                "opened": true,
                "openedAt": Timestamp(date: Date()),
                "openedBy": FieldValue.arrayUnion([currentUserId])
            ])
    }
    
    
    
    func sendMessage() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let text = messageText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        
        let db = Firestore.firestore()
        let messageId = UUID().uuidString
        let now = Timestamp(date: Date())
        
        var messageData: [String: Any] = [
            "senderId": currentUserId,
            "senderName": "Moi",
            "text": text,
            "type": "text",
            "createdAt": now,
            "seenBy": [currentUserId]
        ]
        if let replyingTo = replyingTo {
            messageData["replyToMessageId"] = replyingTo.id
            messageData["replyToText"] = replyingTo.text
            messageData["replyToSender"] = replyingTo.senderName
        }
        
        db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .document(messageId)
            .setData(messageData)
        
        db.collection("conversations")
            .document(conversationId)
            .getDocument { snap, _ in
                
                let data = snap?.data() ?? [:]
                let participants = data["participants"] as? [String] ?? []
                let receiverId = participants.first(where: { $0 != currentUserId }) ?? ""
                
                var updates: [String: Any] = [
                    "lastMessage": text,
                    "lastMessagePreview": text,
                    "lastMessageType": "text",
                    "lastSenderId": currentUserId,
                    "lastMessageDate": now,
                    "updatedAt": now,
                    "seenBy": [currentUserId]
                ]
                
                if !receiverId.isEmpty {
                    updates["unreadCounts.\(receiverId)"] = FieldValue.increment(Int64(1))
                    updates["unreadFor"] = FieldValue.arrayUnion([receiverId])
                }
                
                db.collection("conversations")
                    .document(conversationId)
                    .updateData(updates)
            }
        
        ChatPresenceService.shared.setTyping(
            conversationId: conversationId,
            isTyping: false
        )
        messageText = ""
        replyingTo = nil
    }
    
    func menuButton(
        _ icon: String,
        _ title: String,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Text(icon)
                    .font(.title3)

                Text(title)
                    .font(.body)
                    .foregroundColor(isDestructive ? .red : .primary)

                Spacer()
            }
            .padding()
        }
    }
    
    func markConversationAsSeen() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        let convRef = db.collection("conversations").document(conversationId)

        convRef.updateData([
            "seenBy": FieldValue.arrayUnion([uid]),
            "unreadFor": FieldValue.arrayRemove([uid]),
            "unreadCounts.\(uid)": 0,
            "updatedAt": FieldValue.serverTimestamp()
        ])

        convRef.collection("messages")
            .whereField("senderId", isNotEqualTo: uid)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ markConversationAsSeen messages:", error.localizedDescription)
                    return
                }

                snapshot?.documents.forEach { doc in
                    doc.reference.updateData([
                        "seenBy": FieldValue.arrayUnion([uid])
                    ])
                }
            }
    }
    
    
    
    func prepareSelectedMedias() {
        guard !selectedMediaItems.isEmpty else { return }
        
        previewMedias = []
        
        Task {
            for item in selectedMediaItems {
                do {
                    if let data = try await item.loadTransferable(type: Data.self) {
                        
                        if item.supportedContentTypes.contains(where: { $0.conforms(to: .image) }) {
                            let image = UIImage(data: data)
                            
                            let media = ChatPreviewMedia(
                                type: "image",
                                data: data,
                                image: image,
                                videoURL: nil
                            )
                            
                            await MainActor.run {
                                previewMedias.append(media)
                            }
                            
                        } else if item.supportedContentTypes.contains(where: { $0.conforms(to: .movie) }) {
                            let tempURL = FileManager.default.temporaryDirectory
                                .appendingPathComponent(UUID().uuidString + ".mov")
                            
                            try data.write(to: tempURL)
                            
                            let media = ChatPreviewMedia(
                                type: "video",
                                data: data,
                                image: nil,
                                videoURL: tempURL
                            )
                            
                            await MainActor.run {
                                previewMedias.append(media)
                            }
                        }
                    }
                } catch {
                    print("❌ Préparation média:", error.localizedDescription)
                }
            }
            
            await MainActor.run {
                showMediaPreview = true
            }
        }
    }
    
    func sendPreviewMedias() {
        guard !previewMedias.isEmpty else { return }
        
        let viewOnceValue = sendAsViewOnce
        print("🔒 Vue unique AU MOMENT ENVOI =", viewOnceValue)
        
        isUploadingMedia = true
        
        for media in previewMedias {
            
            if media.type == "image", let image = media.image {
                ChatMediaService.shared.uploadImage(image, conversationId: conversationId) { url in
                    if let url = url {
                        print("🔒 IMAGE Vue unique =", viewOnceValue)
                        sendMediaMessage(type: "image", mediaUrl: url, isViewOnce: viewOnceValue)
                    }
                }
                
            } else if media.type == "video", let url = media.videoURL {
                ChatMediaService.shared.uploadVideo(fileURL: url, conversationId: conversationId) { videoUrl in
                    if let videoUrl = videoUrl {
                        print("🔒 VIDEO Vue unique =", viewOnceValue)
                        sendMediaMessage(type: "video", mediaUrl: videoUrl, isViewOnce: viewOnceValue)
                    }
                }
            }
        }
        
        previewMedias = []
        selectedMediaItems = []
        showMediaPreview = false
        isUploadingMedia = false
        sendAsViewOnce = false
    }
    
    
    func sendMediaMessage(type: String, mediaUrl: String, isViewOnce: Bool = false) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let messageId = UUID().uuidString
        let now = Timestamp(date: Date())
        
        var messageData: [String: Any] = [
            "senderId": currentUserId,
            "senderName": "Moi",
            "text": type == "image" ? "📷 Photo" : "🎥 Vidéo",
            "type": type,
            "createdAt": now,
            "seenBy": [currentUserId],
            "isViewOnce": isViewOnce,
            "openedBy": []
        ]
        
        if type == "image" {
            messageData["imageUrl"] = mediaUrl
        } else {
            messageData["videoUrl"] = mediaUrl
        }
        
        db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .document(messageId)
            .setData(messageData)
        db.collection("conversations")
            .document(conversationId)
            .getDocument { snap, _ in

                let data = snap?.data() ?? [:]
                let participants = data["participants"] as? [String] ?? []
                let receiverId = participants.first(where: { $0 != currentUserId }) ?? ""

                var updates: [String: Any] = [
                    "lastMessage": type == "image" ? "📷 Photo" : "🎥 Vidéo",
                    "lastMessagePreview": type == "image" ? "📷 Photo" : "🎥 Vidéo",
                    "lastMessageType": type,
                    "lastSenderId": currentUserId,
                    "lastMessageDate": now,
                    "updatedAt": now,
                    "seenBy": [currentUserId]
                ]

                if !receiverId.isEmpty {
                    updates["unreadCounts.\(receiverId)"] = FieldValue.increment(Int64(1))
                    updates["unreadFor"] = FieldValue.arrayUnion([receiverId])
                }

                db.collection("conversations")
                    .document(conversationId)
                    .updateData(updates)
            }
    }
    
   
    
    func formatOpenedTime(_ date: Date?) -> String {
        guard let date = date else { return "Média ouvert" }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "HH:mm"

        return "Ouvert à \(formatter.string(from: date))"
    }
    
    
    
    func formatMessageTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
        } else {
            formatter.dateFormat = "dd/MM HH:mm"
        }
        
        return formatter.string(from: date)
    }
    func reactToMessage(_ message: Message, emoji: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore()
            .collection("conversations")
            .document(conversationId)
            .collection("messages")
            .document(message.id)
            .updateData([
                "reactions.\(uid)": emoji
            ])
    }
    
    func handleAudioButton() {
        if audioRecorder.isRecording {
            return
        }

        recordedAudioURL = audioRecorder.startRecording()

        ChatPresenceService.shared.setRecording(
            conversationId: conversationId,
            isRecording: true
        )
    }
    func pauseOrResumeAudio() {
        if audioRecorder.isPaused {
            audioRecorder.resumeRecording()
        } else {
            audioRecorder.pauseRecording()
        }
    }

    func cancelAudioRecording() {
        audioRecorder.cancelRecording()
        recordedAudioURL = nil

        ChatPresenceService.shared.setRecording(
            conversationId: conversationId,
            isRecording: false
        )
    }

    func finishAndSendAudio() {
        let viewOnceValue = sendAudioAsViewOnce

        if let url = audioRecorder.finishRecording() {
            sendAudioMessage(
                fileURL: url,
                duration: audioRecorder.recordingTime,
                isViewOnce: viewOnceValue
            )
        }

        recordedAudioURL = nil
        sendAudioAsViewOnce = false

        ChatPresenceService.shared.setRecording(
            conversationId: conversationId,
            isRecording: false
        )
    }
    
    func sendAudioMessage(fileURL: URL, duration: Double, isViewOnce: Bool) {
        isUploadingAudio = true

        ChatAudioService.shared.uploadAudio(fileURL: fileURL, conversationId: conversationId) { audioUrl in
            DispatchQueue.main.async {
                isUploadingAudio = false

                guard let audioUrl = audioUrl else { return }
                saveAudioMessage(audioUrl: audioUrl, duration: duration, isViewOnce: isViewOnce)
            }
        }
    }
    func saveAudioMessage(audioUrl: String, duration: Double, isViewOnce: Bool) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        let messageId = UUID().uuidString
        let now = Timestamp(date: Date())

        var messageData: [String: Any] = [
            "senderId": currentUserId,
            "senderName": "Moi",
            "text": isViewOnce ? "🎤 Vocal vue unique" : "🎤 Message vocal",
            "type": "audio",
            "audioUrl": audioUrl,
            "audioDuration": duration,
            "createdAt": now,
            "seenBy": [currentUserId],
            "listenedBy": [],
            "isViewOnce": isViewOnce,
            "opened": false,
            "openedBy": [],
            "openedAt": NSNull()
        ]

        db.collection("users")
            .document(currentUserId)
            .getDocument { snap, _ in

                let data = snap?.data() ?? [:]

                if let avatar = data["imageUrl"] as? String ?? data["profileImageUrl"] as? String {
                    messageData["senderAvatar"] = avatar
                }

                if let name = data["name"] as? String ?? data["fullName"] as? String {
                    messageData["senderName"] = name
                }

                db.collection("conversations")
                    .document(conversationId)
                    .collection("messages")
                    .document(messageId)
                    .setData(messageData)

                db.collection("conversations")
                    .document(conversationId)
                    .getDocument { snap, _ in

                        let convData = snap?.data() ?? [:]
                        let participants = convData["participants"] as? [String] ?? []
                        let receiverId = participants.first(where: { $0 != currentUserId }) ?? ""

                        var updates: [String: Any] = [
                            "lastMessage": isViewOnce ? "🎤 Vocal vue unique" : "🎤 Message vocal",
                            "lastMessagePreview": isViewOnce ? "🎤 Vocal vue unique" : "🎤 Message vocal",
                            "lastMessageType": "audio",
                            "lastSenderId": currentUserId,
                            "lastMessageDate": now,
                            "updatedAt": now,
                            "seenBy": [currentUserId]
                        ]

                        if !receiverId.isEmpty {
                            updates["unreadCounts.\(receiverId)"] = FieldValue.increment(Int64(1))
                            updates["unreadFor"] = FieldValue.arrayUnion([receiverId])
                        }

                        db.collection("conversations")
                            .document(conversationId)
                            .updateData(updates)
                    }
            }
    }

    func downloadMessageMedia(_ message: Message) {
        var urlString: String?

        if message.type == "image" {
            urlString = message.imageUrl
        } else if message.type == "video" {
            urlString = message.videoUrl
        } else if message.type == "audio" {
            urlString = message.audioUrl
        } else {
            print("❌ Aucun média à télécharger")
            return
        }

        guard let urlString = urlString,
              let url = URL(string: urlString) else {
            print("❌ URL média invalide")
            return
        }

        URLSession.shared.downloadTask(with: url) { tempURL, response, error in
            if let error = error {
                print("❌ Erreur téléchargement:", error.localizedDescription)
                return
            }

            guard let tempURL = tempURL else {
                print("❌ Fichier temporaire introuvable")
                return
            }

            let fileExtension: String

            if message.type == "image" {
                fileExtension = "jpg"
            } else if message.type == "video" {
                fileExtension = "mov"
            } else {
                fileExtension = "m4a"
            }

            let finalURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString + "." + fileExtension)

            do {
                if FileManager.default.fileExists(atPath: finalURL.path) {
                    try FileManager.default.removeItem(at: finalURL)
                }

                try FileManager.default.moveItem(at: tempURL, to: finalURL)

                DispatchQueue.main.async {
                    if message.type == "image" {
                        saveImageToPhotos(finalURL)
                    } else if message.type == "video" {
                        saveVideoToPhotos(finalURL)
                    } else {
                        saveAudioToFiles(finalURL)
                    }
                }

            } catch {
                print("❌ Erreur fichier:", error.localizedDescription)
            }
        }.resume()
    }
    
    func saveImageToPhotos(_ fileURL: URL) {
        guard let image = UIImage(contentsOfFile: fileURL.path) else {
            print("❌ Image illisible")
            return
        }

        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        print("✅ Photo enregistrée dans Photos")
    }

    func saveVideoToPhotos(_ fileURL: URL) {
        UISaveVideoAtPathToSavedPhotosAlbum(fileURL.path, nil, nil, nil)
        print("✅ Vidéo enregistrée dans Photos")
    }

    func saveAudioToFiles(_ fileURL: URL) {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsURL.appendingPathComponent("vocal-\(UUID().uuidString).m4a")

        do {
            try FileManager.default.copyItem(at: fileURL, to: destinationURL)
            print("✅ Vocal enregistré dans Fichiers:", destinationURL.path)
        } catch {
            print("❌ Erreur sauvegarde vocal:", error.localizedDescription)
        }
    }
    
    func shareMessage(_ message: Message) {

        if message.type == "text" {
            shareItems = [message.text]
            showShareSheet = true
            return
        }

        var urlString: String?

        if message.type == "image" {
            urlString = message.imageUrl
        } else if message.type == "video" {
            urlString = message.videoUrl
        } else if message.type == "audio" {
            urlString = message.audioUrl
        }

        guard let urlString = urlString,
              let url = URL(string: urlString) else {
            print("❌ Rien à partager")
            return
        }

        shareItems = [url]
        showShareSheet = true
    }
    
    func reportMessage(_ message: Message, reason: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()

        let reportData: [String: Any] = [
            "conversationId": conversationId,
            "messageId": message.id,
            "reportedBy": currentUserId,
            "reportedUserId": message.senderId,
            "messageType": message.type,
            "messageText": message.text,
            "reason": reason,
            "status": "pending",
            "appSection": "messages",
            "createdAt": Timestamp(date: Date())
        ]

        db.collection("reports")
            .addDocument(data: reportData) { error in
                if let error = error {
                    print("❌ Erreur signalement:", error.localizedDescription)
                } else {
                    print("✅ Message signalé avec succès")
                }
            }
    }
    
    func translateSelectedMessage() {
        guard let message = messageToTranslate else { return }

        let text = message.text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else {
            translatedText = "Aucun texte à traduire."
            return
        }

        isTranslating = true
        translatedText = "Traduction en cours..."

        let functions = Functions.functions(region: "us-central1")

        functions.httpsCallable("translateMessage").call([
            "text": text,
            "targetLanguage": selectedTranslationLanguage
        ]) { result, error in

            DispatchQueue.main.async {
                isTranslating = false

                if let error = error {
                    translatedText = "Erreur traduction : \(error.localizedDescription)"
                    return
                }

                guard let data = result?.data as? [String: Any] else {
                    translatedText = "Réponse invalide."
                    return
                }

                let detected = data["detectedLanguage"] as? String ?? "inconnue"
                let translated = data["translatedText"] as? String ?? ""

                translatedText = "Langue détectée : \(detected)\n\n\(translated)"
            }
        }
    }
    
    
    
    func transcribeSelectedAudio() {
        guard let message = messageToTranscribe else { return }

        guard let audioUrl = message.audioUrl, !audioUrl.isEmpty else {
            transcriptionText = "Aucun vocal trouvé."
            return
        }

        isTranscribing = true
        transcriptionText = ""

        let functions = Functions.functions(region: "us-central1")

        functions.httpsCallable("transcribeAudioMessage").call([
            "audioUrl": audioUrl,
            "targetLanguage": selectedTranslationLanguage
        ]) { result, error in

            DispatchQueue.main.async {
                isTranscribing = false

                if let error = error {
                    transcriptionText = "Erreur transcription : \(error.localizedDescription)"
                    return
                }

                guard let data = result?.data as? [String: Any] else {
                    transcriptionText = "Réponse invalide."
                    return
                }

                let transcribed = data["transcribedText"] as? String ?? ""
                var translated = data["translatedText"] as? String ?? ""

                translated = translated
                    .replacingOccurrences(of: "```json", with: "")
                    .replacingOccurrences(of: "```", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                transcriptionText =
                """
                📝 Message original

                \(transcribed)

                🌍 Traduction

                \(translated)
                """
            }
        }
    }
    
    func formatAudioTime(_ seconds: Double) -> String {
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60

        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%02d:%02d", m, s)
        }
    }
    
    func listenIncomingCalls() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("calls")
            .whereField("receiverId", isEqualTo: uid)
            .whereField("status", isEqualTo: "ringing")
            .addSnapshotListener { snapshot, _ in

                guard let doc = snapshot?.documents.first else {
                    showIncomingCall = false
                    return
                }

                let data = doc.data()
                let callConversationId = data["conversationId"] as? String ?? ""

                guard callConversationId == conversationId else { return }

                incomingCallId = doc.documentID
                incomingCallType = data["type"] as? String ?? "audio"
                showIncomingCall = true
            }
    }
    
    
    
}


struct EmojiCategory: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let emojis: [String]
}

struct EmojiData {
    static let categories: [EmojiCategory] = [
        EmojiCategory(title: "Récents", icon: "🕘", emojis: ["👍","❤️","😂","😮","😢","🙏","🔥","😍"]),
        EmojiCategory(title: "Smileys", icon: "😀", emojis: ["😀","😃","😄","😁","😆","😅","😂","🤣","😊","😇","🙂","🙃","😉","😍","🥰","😘","😗","😙","😚","😋","😛","😜","🤪","😝","🤑","🤗","🤭","🤫","🤔","🤐","🤨","😐","😑","😶","😏","😒","🙄","😬","😌","😔","😪","🤤","😴","😷","🤒","🤕","🤢","🤮","🤧","🥵","🥶","🥴","😵","🤯","🤠","🥳","😎","🤓","🧐","😕","😟","🙁","☹️","😮","😯","😲","😳","🥺","😦","😧","😨","😰","😥","😢","😭","😱","😖","😣","😞","😓","😩","😫","🥱","😤","😡","😠","🤬","😈","👿"]),
        EmojiCategory(title: "Gestes", icon: "👍", emojis: ["👍","👎","👏","🙌","👐","🤲","🙏","🤝","💪","👊","✊","🤛","🤜","👌","🤌","🤏","✌️","🤞","🤟","🤘","🤙","👈","👉","👆","👇","☝️","✋","🤚","🖐️","🖖","👋","💅"]),
        EmojiCategory(title: "Cœurs", icon: "❤️", emojis: ["❤️","🧡","💛","💚","💙","💜","🖤","🤍","🤎","💔","❣️","💕","💞","💓","💗","💖","💘","💝","💟"]),
        EmojiCategory(title: "Animaux", icon: "🐶", emojis: ["🐶","🐱","🐭","🐹","🐰","🦊","🐻","🐼","🐨","🐯","🦁","🐮","🐷","🐸","🐵","🙈","🙉","🙊","🐔","🐧","🐦","🦅","🦆","🦉","🐺","🐗","🐴","🦄","🐝","🪱","🐛","🦋","🐌","🐞","🐜","🪰","🪲","🦗","🕷️","🦂","🐢","🐍","🦎","🦖","🦕","🐙","🦑","🦐","🦞","🦀","🐡","🐠","🐟","🐬","🐳","🐋","🦈","🐊","🐅","🐆","🦓","🦍","🦧","🐘","🦛","🦏","🐪","🐫","🦒","🦘","🐃","🐂","🐄","🐎","🐖","🐏","🐑","🦙","🐐","🦌","🐕","🐩","🦮","🐕‍🦺","🐈","🐈‍⬛","🪶","🐓","🦃","🦤","🦚","🦜","🦢","🦩","🕊️","🐇","🦝","🦨","🦡","🦫","🦦","🦥","🐁","🐀","🐿️","🦔"]),
        EmojiCategory(title: "Nature", icon: "🌹", emojis: ["🌵","🎄","🌲","🌳","🌴","🪵","🌱","🌿","☘️","🍀","🎍","🪴","🎋","🍃","🍂","🍁","🍄","🐚","🪨","🌾","💐","🌷","🌹","🥀","🌺","🌸","🌼","🌻","🌞","🌝","🌛","🌜","🌚","🌕","🌖","🌗","🌘","🌑","🌒","🌓","🌔","🌙","🌎","🌍","🌏","🪐","💫","⭐️","🌟","✨","⚡️","☄️","💥","🔥","🌪️","🌈","☀️","🌤️","⛅️","🌥️","☁️","🌦️","🌧️","⛈️","🌩️","🌨️","❄️","☃️","⛄️","🌬️","💨","💧","💦","☔️","☂️","🌊"]),
        EmojiCategory(title: "Nourriture", icon: "🍔", emojis: ["🍏","🍎","🍐","🍊","🍋","🍌","🍉","🍇","🍓","🫐","🍈","🍒","🍑","🥭","🍍","🥥","🥝","🍅","🍆","🥑","🥦","🥬","🥒","🌶️","🫑","🌽","🥕","🫒","🧄","🧅","🥔","🍠","🥐","🥯","🍞","🥖","🥨","🧀","🥚","🍳","🧈","🥞","🧇","🥓","🥩","🍗","🍖","🦴","🌭","🍔","🍟","🍕","🫓","🥪","🥙","🧆","🌮","🌯","🫔","🥗","🥘","🫕","🥫","🍝","🍜","🍲","🍛","🍣","🍱","🥟","🦪","🍤","🍙","🍚","🍘","🍥","🥠","🥮","🍢","🍡","🍧","🍨","🍦","🥧","🧁","🍰","🎂","🍮","🍭","🍬","🍫","🍿","🍩","🍪","🌰","🥜","🍯","🥛","🍼","☕️","🫖","🍵","🧃","🥤","🧋","🍶","🍺","🍻","🥂","🍷","🥃","🍸","🍹","🧉","🍾","🧊"]),
        EmojiCategory(title: "Objets", icon: "💡", emojis: ["📱","💻","⌨️","🖥️","🖨️","🖱️","🖲️","💽","💾","💿","📀","📷","📸","📹","🎥","📽️","🎞️","📞","☎️","📟","📠","📺","📻","🎙️","🎚️","🎛️","🧭","⏱️","⏲️","⏰","🕰️","⌛️","⏳","📡","🔋","🪫","🔌","💡","🔦","🕯️","🪔","🧯","🛢️","💸","💵","💴","💶","💷","🪙","💰","💳","💎","⚖️","🪜","🧰","🪛","🔧","🔨","⚒️","🛠️","⛏️","🪚","🔩","⚙️","🪤","🧱","⛓️","🧲","🔫","💣","🧨","🪓","🔪","🗡️","⚔️","🛡️","🚬","⚰️","🪦","⚱️","🏺","🔮","📿","🧿","💈","⚗️","🔭","🔬","🕳️","🩹","🩺","💊","💉","🩸","🧬","🦠","🧫","🧪","🌡️","🧹","🧺","🧻","🚽","🚰","🚿","🛁","🛀","🧼","🪥","🪒","🧽","🪣","🧴","🛎️","🔑","🗝️","🚪","🪑","🛋️","🛏️","🛌","🧸","🪆","🖼️","🪞","🪟","🛍️","🛒","🎁","🎈","🎏","🎀","🪄","🪅","🎊","🎉","🪩","📩","📨","📧","💌","📥","📤","📦","🏷️","📪","📫","📬","📭","📮","📯","📜","📃","📄","📑","🧾","📊","📈","📉","🗒️","🗓️","📆","📅","🗑️","📇","🗃️","🗳️","🗄️","📋","📁","📂","🗂️","🗞️","📰","📓","📔","📒","📕","📗","📘","📙","📚","📖","🔖","🧷","🔗","📎","🖇️","📐","📏","🧮","📌","📍","✂️","🖊️","🖋️","✒️","🖌️","🖍️","📝","✏️","🔍","🔎","🔏","🔐","🔒","🔓"]),
        EmojiCategory(title: "Symboles", icon: "🔣", emojis: ["✅","❌","❗️","❓","⁉️","‼️","⚠️","🚫","🔴","🟠","🟡","🟢","🔵","🟣","⚫️","⚪️","🟤","🔺","🔻","🔸","🔹","🔶","🔷","🔳","🔲","▪️","▫️","◾️","◽️","◼️","◻️","⬛️","⬜️","🟥","🟧","🟨","🟩","🟦","🟪","🟫","❤️‍🔥","❤️‍🩹","💯","🔞","📵","🚭","🚯","🚱","🚷","📳","📴","☢️","☣️","⬆️","↗️","➡️","↘️","⬇️","↙️","⬅️","↖️","↕️","↔️","↩️","↪️","⤴️","⤵️","🔃","🔄","🔙","🔚","🔛","🔜","🔝"]),
        EmojiCategory(title: "Drapeaux", icon: "🏳️", emojis: ["🏳️","🏴","🏁","🚩","🏳️‍🌈","🏳️‍⚧️","🇫🇷","🇬🇳","🇸🇳","🇨🇮","🇲🇱","🇬🇲","🇸🇱","🇹🇬","🇧🇯","🇳🇪","🇳🇬","🇨🇲","🇨🇩","🇿🇦","🇲🇦","🇩🇿","🇹🇳","🇪🇬","🇪🇹","🇰🇪","🇬🇭","🇺🇸","🇨🇦","🇬🇧","🇪🇸","🇮🇹","🇩🇪","🇧🇪","🇨🇭","🇵🇹","🇧🇷","🇦🇷","🇨🇳","🇯🇵","🇰🇷","🇮🇳","🇹🇷","🇦🇪","🇸🇦"])
    ]

    static let all = categories.flatMap { $0.emojis }
}
struct EmojiPickerView: View {

    let emojis: [String]
    let onSelect: (String) -> Void

    let columns = Array(repeating: GridItem(.flexible()), count: 6)

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(emojis, id: \.self) { emoji in
                        Button {
                            onSelect(emoji)
                        } label: {
                            Text(emoji)
                                .font(.largeTitle)
                                .frame(width: 44, height: 44)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Choisir un emoji")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ChatVideoThumbnailView: View {

    let videoURL: URL
    @State private var thumbnail: UIImage?

    var body: some View {
        ZStack {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.black.opacity(0.85)
                ProgressView()
            }

            Image(systemName: "play.circle.fill")
                .font(.system(size: 58))
                .foregroundColor(.white)
                .shadow(radius: 4)
        }
        .frame(width: 260, height: 220)
        .clipped()
        .cornerRadius(16)
        .onAppear {
            generateThumbnail()
        }
    }

    func generateThumbnail() {
        let asset = AVAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true

        let time = CMTime(seconds: 1, preferredTimescale: 600)

        DispatchQueue.global().async {
            do {
                let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
                let image = UIImage(cgImage: cgImage)

                DispatchQueue.main.async {
                    self.thumbnail = image
                }
            } catch {
                print("❌ Thumbnail vidéo:", error.localizedDescription)
            }
        }
    }
}

struct ChatImageItem: Identifiable {
    let id = UUID()
    let url: String
    let message: Message
}
