//
//  ReportService.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 23/06/2026.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

final class ReportService {

    static let shared = ReportService()

    private let db = Firestore.firestore()

    func sendReport(
        reason: String,
        details: String,
        callId: String?,
        conversationId: String?
    ) {

        guard let reporterId = Auth.auth().currentUser?.uid else {
            return
        }

        let reportData: [String: Any] = [
            "reporterId": reporterId,
            "reason": reason,
            "details": details,
            "callId": callId ?? "",
            "conversationId": conversationId ?? "",
            "status": "pending",
            "createdAt": Timestamp(date: Date())
        ]

        db.collection("reports")
            .addDocument(data: reportData)

        print("🚨 Report Firestore enregistré")
    }
}
