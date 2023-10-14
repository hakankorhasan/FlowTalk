//
//  ConversationsModel.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 10.10.2023.
//

import Foundation

struct Conversation {
    let id: String
    let name: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
}

struct LatestMessage {
    let date: String
    let isRead: Bool
    let text: String
}