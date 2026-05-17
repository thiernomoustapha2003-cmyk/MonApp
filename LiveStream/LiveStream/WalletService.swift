//
//  WalletService.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 10/05/2026.
//
//
// 
//

import Combine
import Foundation
import FirebaseFirestore
import FirebaseAuth

class WalletService: ObservableObject {
    
    static let shared = WalletService()
    
    private let db = Firestore.firestore()
    
    @Published var coins: Int = 0
    
    // Commission plateforme Cutly : 30%
    private let platformCommissionRate: Double = 0.30
    
    func loadCoins() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(uid).addSnapshotListener { snapshot, _ in
            if let data = snapshot?.data() {
                DispatchQueue.main.async {
                    self.coins = data["coins"] as? Int ?? 0
                }
            }
        }
    }
    
    func addCoins(_ amount: Int) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(uid).updateData([
            "coins": FieldValue.increment(Int64(amount))
        ])
    }
    
    func spendCoins(_ amount: Int, completion: @escaping (Bool) -> Void) {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        
        let userRef = db.collection("users").document(uid)
        
        db.runTransaction({ transaction, errorPointer -> Any? in
            do {
                let snapshot = try transaction.getDocument(userRef)
                let currentCoins = snapshot.data()?["coins"] as? Int ?? 0
                
                if currentCoins < amount {
                    return false
                }
                
                transaction.updateData([
                    "coins": currentCoins - amount
                ], forDocument: userRef)
                
                return true
                
            } catch {
                errorPointer?.pointee = error as NSError
                return false
            }
        }) { result, _ in
            completion((result as? Bool) == true)
        }
    }
    
    func recordGiftTransaction(
        liveId: String,
        creatorId: String,
        gift: Gift,
        completion: @escaping (Bool) -> Void
    ) {
        guard let senderId = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        
        let transactionRef = db.collection("giftTransactions").document()
        let creatorRef = db.collection("users").document(creatorId)
        let platformRef = db.collection("platformStats").document("wallet")
        
        let totalCoins = gift.coins
        let platformCoins = Int(Double(totalCoins) * platformCommissionRate)
        let creatorCoins = totalCoins - platformCoins
        
        let data: [String: Any] = [
            "liveId": liveId,
            "senderId": senderId,
            "creatorId": creatorId,
            "giftName": gift.name,
            "giftEmoji": gift.emoji,
            "totalCoins": totalCoins,
            "creatorCoins": creatorCoins,
            "platformCoins": platformCoins,
            "commissionRate": platformCommissionRate,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        db.runTransaction({ transaction, errorPointer -> Any? in
            do {
                transaction.setData(data, forDocument: transactionRef)
                
                transaction.updateData([
                    "giftEarningsCoins": FieldValue.increment(Int64(creatorCoins)),
                    "totalGiftReceivedCoins": FieldValue.increment(Int64(totalCoins))
                ], forDocument: creatorRef)
                
                transaction.setData([
                    "giftCommissionCoins": FieldValue.increment(Int64(platformCoins)),
                    "totalGiftVolumeCoins": FieldValue.increment(Int64(totalCoins)),
                    "updatedAt": FieldValue.serverTimestamp()
                ], forDocument: platformRef, merge: true)
                
                return true
                
            } catch {
                errorPointer?.pointee = error as NSError
                return false
            }
        }) { result, _ in
            completion((result as? Bool) == true)
        }
    }
}
