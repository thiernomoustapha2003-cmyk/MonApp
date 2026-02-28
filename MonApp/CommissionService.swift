import Foundation

class CommissionService {

    static let shared = CommissionService()
    private init() {}

    private let baseURL = "https://us-central1-afroconnect-7588d.cloudfunctions.net"

    func fetchCommission(barberId: String, completion: @escaping(Result<CommissionRule, Error>) -> Void) {

        guard let url = URL(string: "\(baseURL)/getCommission?barberId=\(barberId)") else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in

            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            guard let data = data else { return }

            do {
                let decoded = try JSONDecoder().decode(CommissionRule.self, from: data)
                DispatchQueue.main.async { completion(.success(decoded)) }
            }
            catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }

        }.resume()
    }

    func updateCommission(rule: CommissionRule, barberId: String, completion: @escaping(Result<Bool, Error>) -> Void) {

        guard let url = URL(string: "\(baseURL)/updateCommission") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "barberId": barberId,
            "percentage": rule.percentage,
            "fixedFee": rule.fixedFee,
            "active": rule.active
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        URLSession.shared.dataTask(with: request) { data, response, error in

            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            DispatchQueue.main.async { completion(.success(true)) }

        }.resume()
    }
}
