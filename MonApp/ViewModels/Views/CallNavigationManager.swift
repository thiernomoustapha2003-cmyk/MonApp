//
//  CallNavigationManager.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 23/06/2026.
//

import Foundation
import SwiftUI
import Combine

final class CallNavigationManager: ObservableObject {

    static let shared = CallNavigationManager()

    @Published var activeCall: ActiveCall?

    private var lastOpenedCallId: String?
    private var lastOpenDate: Date?

    private init() {}

    func openCall(
        callId: String,
        conversationId: String,
        type: String,
        callerName: String
    ) {
        DispatchQueue.main.async {

            guard !callId.isEmpty else {
                print("❌ CallNavigationManager: callId vide")
                return
            }

            if self.activeCall?.callId == callId {
                print("⏭️ CallNavigationManager ignoré, appel déjà ouvert:", callId)
                return
            }

            if self.lastOpenedCallId == callId,
               let lastOpenDate = self.lastOpenDate,
               Date().timeIntervalSince(lastOpenDate) < 2 {
                print("⏭️ CallNavigationManager ignoré, double ouverture rapide:", callId)
                return
            }

            self.lastOpenedCallId = callId
            self.lastOpenDate = Date()

            self.activeCall = ActiveCall(
                callId: callId,
                conversationId: conversationId,
                type: type,
                callerName: callerName
            )

            print("📞 CallNavigationManager ouvre l'appel:", callId)
        }
    }

    func closeCall() {
        DispatchQueue.main.async {
            print("📴 CallNavigationManager ferme l'appel")
            self.activeCall = nil
        }
    }
}

struct ActiveCall: Identifiable, Equatable {
    var id: String { callId }

    let callId: String
    let conversationId: String
    let type: String
    let callerName: String
}
