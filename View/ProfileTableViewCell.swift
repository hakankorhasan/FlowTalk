//
//  ProfileTableViewCell.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 10.10.2023.
//

import UIKit

class ProfileTableViewCell: UITableViewCell {

    static let identifier = "ProfileTableViewCell"
    
    public func setUP(with viewModel: ProfileViewModel) {
        self.textLabel?.text = viewModel.title
        switch viewModel.viewModelType {
        case .info:
            textLabel?.textAlignment = .left
        case .logout:
            textLabel?.textColor = .red
            textLabel?.textAlignment = .center
        }
    }


}
