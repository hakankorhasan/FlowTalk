//
//  SettingsViewController.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 6.11.2023.
//

import UIKit

class SettingsViewController: UIViewController{
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        navigationItem.largeTitleDisplayMode = .never

        view.backgroundColor = UIColor(#colorLiteral(red: 0.9638196826, green: 0.9687927365, blue: 1, alpha: 1))
    }
}
