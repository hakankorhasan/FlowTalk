//
//  Network.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 5.12.2023.
//

import Foundation

struct Network {
    static var reachability: Reachability!
    enum Status: String {
        case unreachable, wifi, wwan
    }
    enum Error: Swift.Error {
        case failedToSetCallout
        case failedToSetDispatchQueue
        case failedToCreateWith(String)
        case failedToInitializeWith(sockaddr_in)
    }
}
