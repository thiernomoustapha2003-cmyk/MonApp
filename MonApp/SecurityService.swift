import FirebaseAuth
import FirebaseFunctions

final class SecurityService {

    static let shared = SecurityService()
    private let functions = Functions.functions(region: "us-central1")

    func logoutAllDevices() async throws {

        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "NoUser", code: 401)
        }

        _ = try await functions
            .httpsCallable("revokeAllSessions")
            .call(["uid": uid])
    }
}
