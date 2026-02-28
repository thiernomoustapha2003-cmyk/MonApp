import Foundation

struct StripeConnectService {

    static func createAccountLink(barberId: String, email: String) async throws -> URL {

        guard let url = URL(string: "https://us-central1-afroconnect-7588d.cloudfunctions.net/createStripeAccount") else {
            throw URLError(.badURL)
        }

        let body: [String: Any] = [
            "barberId": barberId,
            "email": email
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)

        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let link = json["url"] as! String

        return URL(string: link)!
    }
}
