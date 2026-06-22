//
//  CallKitManager.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 21/06/2026.
//

import Foundation
import CallKit
import AVFoundation
import UIKit

final class CallKitManager: NSObject, CXProviderDelegate {

    static let shared = CallKitManager()

    private let provider: CXProvider
    private let callController = CXCallController()

    var currentCallId: String?
    var currentConversationId: String?
    var currentCallType: String?

    override init() {
        let config = CXProviderConfiguration(localizedName: "Cutly")
        config.supportsVideo = true
        config.maximumCallsPerCallGroup = 1
        config.supportedHandleTypes = [.generic]
        config.iconTemplateImageData = nil
        config.includesCallsInRecents = true

        self.provider = CXProvider(configuration: config)
        super.init()
        provider.setDelegate(self, queue: nil)
    }

    func reportIncomingCall(
        callId: String,
        callerName: String,
        conversationId: String,
        type: String
    ) {
        currentCallId = callId
        currentConversationId = conversationId
        currentCallType = type

        let uuid = UUID(uuidString: callId) ?? UUID()

        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: callerName)
        update.localizedCallerName = callerName
        update.hasVideo = type == "video"

        provider.reportNewIncomingCall(with: uuid, update: update) { error in
            if let error = error {
                print("❌ CallKit incoming error:", error.localizedDescription)
            } else {
                print("✅ CallKit appel entrant affiché")
            }
        }
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        print("✅ Appel accepté CallKit")

        if let callId = currentCallId {
            CallService.shared.acceptCall(callId: callId)
        }

        NotificationCenter.default.post(
            name: Notification.Name("OpenAcceptedCall"),
            object: nil
        )

        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        print("❌ Appel refusé/raccroché CallKit")

        if let callId = currentCallId {
            CallService.shared.declineCall(callId: callId)
        }

        action.fulfill()
    }

    func providerDidReset(_ provider: CXProvider) {
        currentCallId = nil
        currentConversationId = nil
        currentCallType = nil
    }
}
