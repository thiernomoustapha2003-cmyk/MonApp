import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ConnectedDevicesView: View {

    @State private var devices: [DeviceSession] = []
    @State private var loading = true

    var body: some View {
        VStack {
            if loading {
                ProgressView("Chargement...")
                    .padding(.top, 40)
            } else if devices.isEmpty {
                Text("Aucun appareil connecté")
                    .foregroundColor(.gray)
                    .padding(.top, 40)
            } else {
                List {
                    ForEach(devices) { device in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(device.deviceName)
                                    .font(.headline)

                                Text("iOS \(device.iosVersion)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)

                                Text(device.lastActiveFormatted)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            Button(role: .destructive) {
                                removeDevice(device)
                            } label: {
                                Image(systemName: "trash")
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
        .navigationTitle("Appareils connectés")
        .onAppear(perform: fetchDevices)
    }
}

// MARK: - Firestore
extension ConnectedDevicesView {

    func fetchDevices() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("sessions")
            .getDocuments { snapshot, _ in

                loading = false

                guard let docs = snapshot?.documents else { return }

                devices = docs.compactMap { DeviceSession(document: $0) }
                    .sorted { $0.lastActive > $1.lastActive }
            }
    }

    func removeDevice(_ device: DeviceSession) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("sessions")
            .document(device.id)
            .delete()

        devices.removeAll { $0.id == device.id }
    }
}
