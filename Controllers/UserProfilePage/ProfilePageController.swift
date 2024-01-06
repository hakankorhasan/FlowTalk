//
//  ProfilePageController.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 5.01.2024.
//

import UIKit

class ProfilePageController: UIViewController {
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = false
        imageView.image = UIImage(named: "wallpaperflare.com_wallpaper")
        return imageView
    }()
    
    private let userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    private let voiceCallButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(named: "circle-phone"), for: .normal)
        btn.tintColor = #colorLiteral(red: 0.2253842354, green: 0.2760212123, blue: 0.3178661764, alpha: 1)
        return btn
    }()
    
    private let videoCallButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(named: "circle-video"), for: .normal)
        btn.tintColor = #colorLiteral(red: 0.2253842354, green: 0.2760212123, blue: 0.3178661764, alpha: 1)
        return btn
    }()
    
    private let userNameLabel = UILabel(text: "Hakan Körhasan", font: .systemFont(ofSize: 18, weight: .medium), textAlignment: .center)
    
    private let bioLabel = UILabel(text: "No Pain, No Gain!", font: .systemFont(ofSize: 14, weight: .light), textColor: .darkGray, textAlignment: .center)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        // Navigation bar'ın yüksekliğini ayarla
        
        backButtonConfigure()
        
        userImageUI()
        
        callButtonsUI()
        
        userInfoUI()
    }
    
    private func userInfoUI() {
        view.addSubview(userNameLabel)
        userNameLabel.anchor(top: userImageView.bottomAnchor, leading: nil, bottom: nil, trailing: nil, padding: .init(top: 10, left: 0, bottom: 0, right: 0))
        userNameLabel.centerXAnchor.constraint(equalTo: userImageView.centerXAnchor).isActive = true
        
        view.addSubview(bioLabel)
        bioLabel.anchor(top: userNameLabel.bottomAnchor, leading: nil, bottom: nil, trailing: nil, padding: .init(top: 5, left: 0, bottom: 0, right: 0))
        bioLabel.centerXAnchor.constraint(equalTo: userImageView.centerXAnchor).isActive = true
    }
    
    private func callButtonsUI() {
        //voiceCallButton.setImage(UIImage(named: "circle-phone"), for: .normal)
        view.addSubview(voiceCallButton)
        
        voiceCallButton.anchor(top: nil, leading: userImageView.trailingAnchor, bottom: userImageView.bottomAnchor, trailing: nil, padding: .init(top: 0, left: 10, bottom: 0, right: 0), size: .init(width: 40, height: 40))
        
        view.addSubview(videoCallButton)
        videoCallButton.anchor(top: nil, leading: nil, bottom: userImageView.bottomAnchor, trailing: userImageView.leadingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 10), size: .init(width: 40, height: 40))
    }
    
    private func userImageUI() {
        
        imageView.addSubview(userImageView)
        userImageView.backgroundColor = .darkGray
        userImageView.anchor(top: nil, leading: nil, bottom: imageView.bottomAnchor, trailing: nil, padding: .init(top: 0, left: 0, bottom: -75, right: 0), size: .init(width: view.height/8, height: view.height/8))
        userImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        userImageView.layer.cornerRadius = view.height/16
        userImageView.layer.borderWidth = 1.0
        userImageView.layer.borderColor = UIColor.white.cgColor
    }
    
    private func backButtonConfigure() {
        view.addSubview(imageView)
        imageView.anchor(top: view.topAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, size: .init(width: view.width, height: view.height/4))
        
        let backButton = UIButton(type: .custom)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
        navigationController?.navigationBar.isHidden = true
        backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        backButton.tintColor = .white
        
        imageView.addSubview(backButton)
        backButton.anchor(top: imageView.topAnchor, leading: imageView.leadingAnchor, bottom: nil, trailing: nil, padding: .init(top: 60, left: 20, bottom: 0, right: 0))
    }
    
    @objc private func handleBack() {
        navigationController?.navigationBar.isHidden = false

        self.navigationController?.popViewController(animated: true)
    }
    
}
