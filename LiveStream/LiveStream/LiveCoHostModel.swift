//
//  LiveCoHostModel.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 17/05/2026.
//

//
//  LiveCoHostModel.swift
//  MonApp
//

import Foundation
import FirebaseFirestore

struct LiveCoHost: Identifiable, Hashable {
    
    let id: String
    let userId: String
    let username: String
    let avatar: String
    
    let role: LiveCoHostRole
    let status: LiveCoHostStatus
    
    let cameraEnabled: Bool
    let micEnabled: Bool
    let mutedByHost: Bool
    
    let canModerate: Bool
    let timerSeconds: Int
    let joinedAt: Date?
    
    var isHost: Bool {
        role == .host
    }
    
    var isGuest: Bool {
        role == .guest
    }
    
    var canSpeak: Bool {
        micEnabled && !mutedByHost && status == .active
    }
    
    var displayName: String {
        username.isEmpty ? "Invité" : username
    }
}

enum LiveCoHostRole: String, Codable {
    case host
    case guest
    case moderator
}

enum LiveCoHostStatus: String, Codable {
    case active
    case pending
    case muted
    case removed
    case disconnected
}

extension LiveCoHost {
    
    static func fromFirestore(id: String, data: [String: Any]) -> LiveCoHost {
        
        let roleRaw = data["role"] as? String ?? "guest"
        let statusRaw = data["status"] as? String ?? "active"
        
        let joinedTimestamp = data["joinedAt"] as? Timestamp
        
        return LiveCoHost(
            id: id,
            userId: data["userId"] as? String ?? id,
            username: data["username"] as? String ?? "Invité",
            avatar: data["avatar"] as? String ?? "",
            role: LiveCoHostRole(rawValue: roleRaw) ?? .guest,
            status: LiveCoHostStatus(rawValue: statusRaw) ?? .active,
            cameraEnabled: data["cameraEnabled"] as? Bool ?? false,
            micEnabled: data["micEnabled"] as? Bool ?? true,
            mutedByHost: data["mutedByHost"] as? Bool ?? false,
            canModerate: data["canModerate"] as? Bool ?? false,
            timerSeconds: data["timerSeconds"] as? Int ?? 300,
            joinedAt: joinedTimestamp?.dateValue()
        )
    }
}
