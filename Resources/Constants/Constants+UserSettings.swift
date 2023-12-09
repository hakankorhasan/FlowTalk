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
    case lastSeenInfo = "isOpenLastseenInfo"
    case onlineInfo = "isOpenOnlineInfo"
    case profilePhoto = "isHiddenPF"
    case readReceipt = "isOpenReadInfo"
    
    var title: String {
        switch self {
        case .lastSeenInfo: return "Last seen"
        case .onlineInfo: return "Online"
        case .profilePhoto: return "Profile photo"
        case .readReceipt: return "Read receipt"
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
    .lastSeenInfo: true
]

var otherSettings: [UserSetting: Bool] = [
    .onlineInfo: true,
    .readReceipt: true,
    .profilePhoto: true,
    .lastSeenInfo: true
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
