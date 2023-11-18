//
//  PhoneDesign.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 17.11.2023.
//

import UIKit

class PhoneDesign: UIView {
    
    let navBarDesign = UIView()
    let imageViewArea = UIImageView()
    let tabBarArea = UIView()
    let tintView = UIView()
    
    let textView = UIView()
    let sendButton = UIButton()
    
    let userImageView = UIImageView()
    let userLabel = UILabel(text: "User name", font: .systemFont(ofSize: 10, weight: .regular), textColor: .black)
    
    let messageBubble = UIView()
    let antiMessageBubble = UIView()
    
    func setupNavBar() {
        
        let lineView = UIView()
        lineView.translatesAutoresizingMaskIntoConstraints = false
        lineView.backgroundColor = .black
        navBarDesign.backgroundColor = .white
        
        userImageView.widthAnchor.constraint(equalToConstant: 30).isActive = true
        userImageView.layer.cornerRadius = 15
        userImageView.backgroundColor = .white
        userImageView.image = UIImage(systemName: "person.circle")
        userImageView.tintColor = .gray
        addSubview(navBarDesign)
        
        navBarDesign.translatesAutoresizingMaskIntoConstraints = false
        navBarDesign.anchor(top: topAnchor, leading: leadingAnchor, bottom: nil, trailing: trailingAnchor, padding: .init(top: 1, left: 1, bottom: 0, right: 1), size: .init(width: 0, height: 40))
        
        let stackView =
            HorizontalStackView(arrangedSubviews: [
                userImageView,
                userLabel
            ], spacing: 10, distrubiton: .fillProportionally)
            
        addSubview(stackView)
        stackView.anchor(top: navBarDesign.topAnchor, leading: leadingAnchor, bottom: navBarDesign.bottomAnchor, trailing: trailingAnchor, padding: .init(top: 5, left: 7, bottom: 5, right: 0))
        
        addSubview(lineView)
        lineView.anchor(top: stackView.bottomAnchor, leading: leadingAnchor, bottom: nil, trailing: trailingAnchor, padding: .init(top: 4, left: 0, bottom: 0, right: 0), size: .init(width: 0, height: 0.33))
        
    }
    
    func setupImageView() {
        imageViewArea.contentMode = .scaleAspectFill
        
        messageBubble.heightAnchor.constraint(equalToConstant: 20).isActive = true
        messageBubble.layer.cornerRadius = 8
        messageBubble.backgroundColor = UIColor.link.withAlphaComponent(0.6)
        
        antiMessageBubble.heightAnchor.constraint(equalToConstant: 30).isActive = true
        antiMessageBubble.layer.cornerRadius = 8
        antiMessageBubble.backgroundColor = UIColor.lightGray
        
        imageViewArea.backgroundColor = .white
        addSubview(imageViewArea)
        imageViewArea.translatesAutoresizingMaskIntoConstraints = false
        imageViewArea.anchor(top: navBarDesign.bottomAnchor, leading: leadingAnchor, bottom: nil, trailing: trailingAnchor, padding: .init(top: 0, left: 1, bottom: 0, right: 1), size: .init(width: 0, height: 260))
        
        imageViewArea.addSubview(tintView)
        tintView.fillSuperview()
        
        imageViewArea.addSubview(messageBubble)
        messageBubble.anchor(top: imageViewArea.topAnchor, leading: leadingAnchor, bottom: nil, trailing: trailingAnchor, padding: .init(top: 5, left: 5, bottom: 0, right: 60))
        
        imageViewArea.addSubview(antiMessageBubble)
        antiMessageBubble.anchor(top: messageBubble.bottomAnchor, leading: leadingAnchor, bottom: nil, trailing: trailingAnchor, padding: .init(top: 8, left: 40, bottom: 0, right: 10))
    }
    
    func setupTabBarArea() {
        tabBarArea.backgroundColor = .black
        textView.layer.cornerRadius = 12
        textView.backgroundColor = .white
        sendButton.widthAnchor.constraint(equalToConstant: 28).isActive = true
        sendButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
        sendButton.tintColor = .black
        addSubview(tabBarArea)
        tabBarArea.translatesAutoresizingMaskIntoConstraints = false
        tabBarArea.anchor(top: imageViewArea.bottomAnchor, leading: leadingAnchor, bottom: nil, trailing: trailingAnchor, padding: .init(top: 0, left: 1, bottom: 0, right: 1), size: .init(width: 0, height: 40))
        
        sendButton.layer.cornerRadius = 14
        sendButton.backgroundColor = .white
        
        let stackView = HorizontalStackView(arrangedSubviews: [
            textView,
            sendButton
        ], spacing: 5, distrubiton: .fillProportionally)
        
        addSubview(stackView)
        stackView.anchor(top: tabBarArea.topAnchor, leading: leadingAnchor, bottom: tabBarArea.bottomAnchor, trailing: trailingAnchor, padding: .init(top: 5, left: 10, bottom: 5, right: 10))
        
        
    }
   
}
