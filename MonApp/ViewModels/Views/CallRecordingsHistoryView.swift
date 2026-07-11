import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct CallRecordingItem: Identifiable {
    let id: String
    let callId: String
    let status: String
    let durationSeconds: Int
    let downloadURL: String
    let createdAt: Date?
}

struct CallRecordingsHistoryView: View {
    @State private var recordings: [CallRecordingItem] = []
    @State private var isLoading = true

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(red: 0.08, green: 0.08, blue: 0.10)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Enregistrements")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)

                    Text("Retrouve ici les appels enregistrés avec accord des deux personnes.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.65))

                    if isLoading {
                        ProgressView()
                            .padding(.top, 40)
                    } else if recordings.isEmpty {
                        emptyState
                    } else {
                        ForEach(recordings) { recording in
                            recordingCard(recording)
                        }
                    }
                }
                .padding(20)
            }
        }
        .onAppear {
            loadRecordings()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "record.circle")
                .font(.system(size: 58))
                .foregroundColor(.white.opacity(0.35))

            Text("Aucun enregistrement")
                .font(.headline)
                .foregroundColor(.white)

            Text("Les appels enregistrés apparaîtront ici après acceptation.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    private func recordingCard(_ recording: CallRecordingItem) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.18))
                        .frame(width: 46, height: 46)

                    Image(systemName: "record.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.red)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Appel enregistré")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(formatDate(recording.createdAt))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.55))
                }

                Spacer()

                statusBadge(recording.status)
            }

            HStack(spacing: 14) {
                infoPill(icon: "clock", text: formatDuration(recording.durationSeconds))
                infoPill(icon: "lock.shield", text: "Consentement OK")
            }

            Divider()
                .background(Color.white.opacity(0.12))

            HStack {
                if recording.downloadURL.isEmpty {
                    Label("Fichier en préparation", systemImage: "icloud.and.arrow.up")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else {
                    Label("Fichier disponible", systemImage: "play.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.35))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    private func statusBadge(_ status: String) -> some View {
        Text(statusText(status))
            .font(.caption.bold())
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(statusColor(status).opacity(0.85))
            .clipShape(Capsule())
    }

    private func infoPill(icon: String, text: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption)
            .foregroundColor(.white.opacity(0.75))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.white.opacity(0.08))
            .clipShape(Capsule())
    }

    private func loadRecordings() {
        guard Auth.auth().currentUser != nil else {
            isLoading = false
            return
        }

        Firestore.firestore()
            .collection("callRecordings")
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .getDocuments { snapshot, error in
                isLoading = false

                if let error = error {
                    print("❌ Erreur chargement enregistrements:", error.localizedDescription)
                    return
                }

                recordings = snapshot?.documents.map { doc in
                    let data = doc.data()

                    return CallRecordingItem(
                        id: doc.documentID,
                        callId: data["callId"] as? String ?? "",
                        status: data["status"] as? String ?? "",
                        durationSeconds: data["durationSeconds"] as? Int ?? 0,
                        downloadURL: data["downloadURL"] as? String ?? "",
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue()
                    )
                } ?? []
            }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return "\(minutes)m \(remainingSeconds)s"
    }

    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Date inconnue" }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func statusText(_ status: String) -> String {
        switch status {
        case "recording":
            return "REC"
        case "stopped":
            return "Terminé"
        default:
            return status.capitalized
        }
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "recording":
            return .red
        case "stopped":
            return .green
        default:
            return .gray
        }
    }
}
