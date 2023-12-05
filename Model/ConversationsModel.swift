//
//  ConversationsModel.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 10.10.2023.
//

import Foundation

struct Conversation: Codable {
    let id: String
    let name: String
    let otherUserEmail: String
    var isRoomBeginIn: Bool
    let latestMessage: LatestMessage
}

struct LatestMessage: Codable {
    let date: String
    let isRead: Bool
    let text: String
}
