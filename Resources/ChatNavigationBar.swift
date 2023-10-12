//
//  ChatNavigationBar.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 12.10.2023.
//

import UIKit

class ChatNavigationBar: UINavigationBar {
    
    private let userImageView: UIImageView = {
       let iv = UIImageView()
        iv.image = UIImage(named: "logo")
        return iv
    }()
    
    private let userNameLabel: UILabel = {
       let label = UILabel()
        label.text = "Name"
        return label
    }()
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        setupUI()
    }
    
    private func setupUI() {
    
        
        userImageView.layer.cornerRadius = Const.ImageSizeForLargeState / 2
        userImageView.clipsToBounds = true
        userImageView.backgroundColor = .red
        userImageView.translatesAutoresizingMaskIntoConstraints = false
            
        addSubview(userImageView)
        addSubview(userNameLabel)
        
        // userImageView için constraint'ler
        userImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Const.ImageLeftMargin).isActive = true
        userImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        userImageView.heightAnchor.constraint(equalToConstant: Const.ImageSizeForLargeState).isActive = true
        userImageView.widthAnchor.constraint(equalTo: userImageView.heightAnchor).isActive = true

        // userNameLabel için constraint'ler
        userNameLabel.leadingAnchor.constraint(equalTo: userImageView.trailingAnchor, constant: Const.ImageLeftMargin).isActive = true
        userNameLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            
    }
}
