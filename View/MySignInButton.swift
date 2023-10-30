//
//  MySignInButton.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 27.10.2023.
//

import GoogleSignIn

class MySignInButton: GIDSignInButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInit() {
       // self.setTitle("Sign In With Google", for: .normal)
       // setTitleColor(UIColor(#colorLiteral(red: 0.1999999881, green: 0.1999999881, blue: 0.1999999881, alpha: 1)), for: .normal)
        self.heightAnchor.constraint(equalToConstant: 60).isActive = true
        self.backgroundColor = UIColor.white.withAlphaComponent(0.6)
      //  titleLabel?.font = UIFont(name: "Gratina", size: 20)
    }
}
