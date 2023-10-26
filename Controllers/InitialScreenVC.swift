//
//  InitialScreenVC.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 26.10.2023.
//

import UIKit

class InitialScreenVC: UIViewController {
    
    var ivBackground = UIImageView()
    var viewColor = UIView()
    var viewLogo = UIView()
    var ivLogo = UIImageView()
    var lbLogo = UILabel()
    var lbSol = UILabel()
    var btnRegister = UIButton()
    var btnLogin = UIButton()
    var lbVer = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func setupUI() {
        setupBackground()
        setupLogoView()
        setupButton()
        setupLabelVersion()
    }
    
    func setupBackground() {
        // add ivBackground
        // add viewColor
    }
    
    func setupLogoView() {
        // add labelLogo
    }
    
    func setupButton() {
        // add buttons
    }
    
    func setupLabelVersion() {
        // add label version
    }
}
