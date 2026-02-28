import Foundation
import FirebaseAuth

class PayoutScheduleService {

    static let shared = PayoutScheduleService()
    private init() {}

    private let baseURL = "https://setpayoutschedule-jzvik52b6a-uc.a.run.app"

    func updateSchedule(_ schedule: PayoutSchedule,
                        completion: @escaping(Result<Void,Error>) -> Void) {

        guard let uid = Auth.auth().currentUser?.uid else { return }

        guard let url = URL(string: baseURL + "?barberId=\(uid)") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(schedule)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { _,_,error in
            if let error = error { completion(.failure(error)) }
            else { completion(.success(())) }
        }.resume()
    }
}
