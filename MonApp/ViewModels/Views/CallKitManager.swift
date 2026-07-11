//
//  CallKitManager.swift
//  MonApp
//
//  CallKit UNIQUEMENT pour les appels privés.
//  Ne pas mélanger avec LiveAgoraManager.
//

import Foundation
import CallKit
import AVFoundation
import UIKit

final class CallKitManager: NSObject, CXProviderDelegate {

    static let shared = CallKitManager()

    private struct ActiveCall {
        let callId: String
        let conversationId: String
        let type: String
        let callerName: String
        var wasAccepted: Bool
        var startedAt: Date?
    }

    private let provider: CXProvider
    private let callController = CXCallController()

    private var callsByUUID: [UUID: ActiveCall] = [:]
    private var uuidByCallId: [String: UUID] = [:]

    override init() {
        let config = CXProviderConfiguration(localizedName: "Cutly")
        config.supportsVideo = true
        config.maximumCallsPerCallGroup = 1
        config.maximumCallGroups = 1
        config.supportedHandleTypes = [.generic]
        config.includesCallsInRecents = true

        self.provider = CXProvider(configuration: config)

        super.init()
        provider.setDelegate(self, queue: .main)
    }

    func reportIncomingCall(
        callId: String,
        callerName: String,
        conversationId: String,
        type: String
    ) {
        if let oldUUID = uuidByCallId[callId] {
            print("⚠️ CallKit appel déjà affiché, ignoré:", callId)
            return
        }

        let uuid = UUID()

        let activeCall = ActiveCall(
            callId: callId,
            conversationId: conversationId,
            type: type,
            callerName: callerName,
            wasAccepted: false,
            startedAt: nil
        )

        callsByUUID[uuid] = activeCall
        uuidByCallId[callId] = uuid

        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: callerName)
        update.localizedCallerName = callerName
        update.hasVideo = type == "video"

        provider.reportNewIncomingCall(with: uuid, update: update) { error in
            if let error = error {
                print("❌ CallKit incoming error:", error.localizedDescription)
                self.clearCall(uuid: uuid)
            } else {
                print("✅ CallKit appel entrant affiché:", callId)
            }
        }
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        let uuid = action.callUUID

        guard var call = callsByUUID[uuid] else {
            print("❌ CallKit accept ignoré : appel introuvable pour UUID", uuid)
            action.fail()
            return
        }

        print("✅ Appel accepté depuis CallKit:", call.callId)

        call.wasAccepted = true
        call.startedAt = Date()
        callsByUUID[uuid] = call

        prepareAudioSessionCategory()

        CallService.shared.acceptCall(callId: call.callId)

        DispatchQueue.main.async {
            CallNavigationManager.shared.openCall(
                callId: call.callId,
                conversationId: call.conversationId,
                type: call.type,
                callerName: call.callerName
            )
        }

        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        let uuid = action.callUUID

        guard let call = callsByUUID[uuid] else {
            print("⚠️ CallKit end ignoré : appel déjà nettoyé")
            action.fulfill()
            return
        }

        print("📴 Fin/refus appel depuis CallKit:", call.callId)

        if call.wasAccepted {
            let duration = currentDuration(for: call)

            CallService.shared.endCall(
                callId: call.callId,
                conversationId: call.conversationId,
                type: call.type,
                duration: duration
            )
        } else {
            CallService.shared.declineCall(callId: call.callId)
        }

        CallAgoraManager.shared.leaveCall()
        clearCall(uuid: uuid)

        action.fulfill()
    }

    func endCurrentCallFromApp(callId: String, duration: Int) {
        guard let uuid = uuidByCallId[callId],
              let call = callsByUUID[uuid] else {
            print("⚠️ endCurrentCallFromApp : CallKit call introuvable:", callId)
            CallAgoraManager.shared.leaveCall()
            return
        }

        CallService.shared.endCall(
            callId: call.callId,
            conversationId: call.conversationId,
            type: call.type,
            duration: duration
        )

        let action = CXEndCallAction(call: uuid)
        let transaction = CXTransaction(action: action)

        callController.request(transaction) { error in
            if let error = error {
                print("❌ CallKit end transaction error:", error.localizedDescription)
            } else {
                print("✅ CallKit appel terminé depuis app")
            }
        }

        CallAgoraManager.shared.leaveCall()
        clearCall(uuid: uuid)
    }

    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        print("🔊 CallKit audio activé")
        // Important : ne pas refaire setActive(true) ici.
        // CallKit a déjà activé la session.
    }

    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        print("🔇 CallKit audio désactivé")
    }

    func providerDidReset(_ provider: CXProvider) {
        print("♻️ CallKit reset")
        CallAgoraManager.shared.leaveCall()
        callsByUUID.removeAll()
        uuidByCallId.removeAll()
    }

    private func prepareAudioSessionCategory() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playAndRecord,
                mode: .voiceChat,
                options: [.allowBluetooth, .defaultToSpeaker]
            )

            print("✅ AudioSession catégorie préparée pour CallKit")
        } catch {
            print("❌ AudioSession CallKit category error:", error.localizedDescription)
        }
    }

    private func currentDuration(for call: ActiveCall) -> Int {
        guard let startedAt = call.startedAt else { return 0 }
        return max(0, Int(Date().timeIntervalSince(startedAt)))
    }

    private func clearCall(uuid: UUID) {
        if let call = callsByUUID[uuid] {
            uuidByCallId.removeValue(forKey: call.callId)
        }

        callsByUUID.removeValue(forKey: uuid)
    }
}
