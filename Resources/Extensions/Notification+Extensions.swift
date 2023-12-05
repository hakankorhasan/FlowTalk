//
//  Notification+Extensions.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 14.10.2023.
//

import Foundation

extension Notification.Name {
    /// Notification when user logs in
    static let didLogInNotification = Notification.Name("didLogInNotification")
}

extension Notification.Name {
    static let flagsChanged = Notification.Name("FlagsChanged")
}
