//
//  ProfileViewModel.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 10.10.2023.
//

import Foundation

enum ProfileViewModelType {
    case info, logout
}

struct ProfileViewModel {
    let viewModelType: ProfileViewModelType
    let title: String
    let handler: () -> Void
}
