//
//  Constants+UserSettings.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 15.11.2023.
//

import Foundation

// for the current user
var isCurrentOnlineInfo: Bool = true
var isCurrentReadInfo: Bool = true
var isCurrentPF: Bool = true
var isCurrentLastSeenInfo: Bool = true

// for the other user
var isOtherOnlineInfo: Bool = true
var isOtherReadInfo: Bool = true
var isOtherPF: Bool = true
var isOtherLastSeenInfo: Bool = true

var blackRatioConstants: CGFloat = 0.0

enum UserSetting: String {
    case lastSeenInfo = "last_seen"
    case onlineInfo = "online_information"
    case profilePhoto = "profile_visibility"
    case readReceipt = "read_receipt"
    case chatSounds = "chat_sounds"
    case highPrioNotification = "high_priority_notf"
    
    var title: String {
        switch self {
        case .lastSeenInfo: return "Last seen"
        case .onlineInfo: return "Online"
        case .profilePhoto: return "Profile photo"
        case .readReceipt: return "Read receipt"
        case .chatSounds: return "Chat sounds"
        case .highPrioNotification: return "High priority notifications"
        }
    }
}

enum UserStatus {
    case current
    case other
}

// Usage example:
var currentSettings: [UserSetting: Bool] = [
    .onlineInfo: true,
    .readReceipt: true,
    .profilePhoto: true,
    .lastSeenInfo: true,
    .chatSounds: true,
    .highPrioNotification: true
]

var otherSettings: [UserSetting: Bool] = [
    .onlineInfo: true,
    .readReceipt: true,
    .profilePhoto: true,
    .lastSeenInfo: true,
    .chatSounds: true,
    .highPrioNotification: true
]

func setUserSetting(status: UserStatus, setting: UserSetting, value: Bool) {
    switch status {
    case .current:
        currentSettings[setting] = value
    case .other:
        otherSettings[setting] = value
    }
}

func getUserSetting(status: UserStatus, setting: UserSetting) -> Bool {
    switch status {
    case .current:
        return currentSettings[setting] ?? false
    case .other:
        return otherSettings[setting] ?? false
    }
}
