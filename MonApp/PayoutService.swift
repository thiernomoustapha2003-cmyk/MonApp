import Foundation

class PayoutService {
    
    static let shared = PayoutService()
    private init() {}
    
    private let baseURL =
    "https://us-central1-afroconnect-7588d.cloudfunctions.net/getPayouts"
    
    func fetchPayouts(barberId: String,
                      completion: @escaping(Result<PayoutResponse, Error>) -> Void) {
        
        print("🧠 fetchPayouts START")
        print("👤 barberId:", barberId)
        
        guard let url = URL(string: "\(baseURL)?barberId=\(barberId)") else {
            print("❌ URL INVALID")
            return
        }
        
        print("🌍 URL:", url.absoluteString)
        print("🚀 SENDING REQUEST...")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            print("📬 RESPONSE RECEIVED")
            
            if let error = error {
                print("❌ NETWORK ERROR:", error.localizedDescription)
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            
            guard let http = response as? HTTPURLResponse else {
                print("❌ NO HTTP RESPONSE")
                return
            }
            
            print("📡 STATUS CODE:", http.statusCode)
            
            guard let data = data else {
                print("❌ DATA NIL")
                return
            }
            
            let raw = String(data: data, encoding: .utf8) ?? "EMPTY BODY"
            print("📦 RAW JSON:")
            print(raw)
            print("📦 END JSON")
            
            do {
                let decoded = try JSONDecoder().decode(PayoutResponse.self, from: data)
                print("✅ DECODE SUCCESS")
                DispatchQueue.main.async { completion(.success(decoded)) }
            }
            catch {
                print("❌ DECODE ERROR:", error)
                DispatchQueue.main.async { completion(.failure(error)) }
            }
            
        }.resume()
    }
    
    // ===============================
    // NEXT STRIPE PAYOUT
    // ===============================
    
    func fetchNextPayout(barberId: String,
                         completion: @escaping(Result<NextPayoutResponse, Error>) -> Void) {
        
        let urlString = "https://getnextpayout-jzvik52b6a-uc.a.run.app?barberId=\(barberId)"
        
        guard let url = URL(string: urlString) else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else { return }
            
            do {
                let decoded = try JSONDecoder().decode(NextPayoutResponse.self, from: data)
                completion(.success(decoded))
            }
            catch {
                completion(.failure(error))
            }
            
        }.resume()
    }
}
