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
        imageView.isUserInteractionEnabled = true
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = true
        imageView.clipsToBounds = true
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
    
    private let followButton: UIButton = {
        let button = UIButton(type: .system)
        return button
    }()
    
    private let messageButton: UIButton = {
        let button = UIButton(type: .system)
        return button
    }()
    
    private let backButton = UIButton(type: .custom)
    
    private let lineView = UIView()
    
    private var buttonsForFriendsUI = UIStackView()
    
    private var currentUserEmail: String
    private var otherUserEmail: String
    
    private var isSent = false
    
    public var profileState: ProfileState
    
    init(currentUserEmail: String, otherUserEmail: String, profileState: ProfileState) {
        self.profileState = profileState
        self.currentUserEmail = currentUserEmail
        self.otherUserEmail = otherUserEmail
        super.init(nibName: nil, bundle: nil)
        self.configureFollowButtonForState(self.profileState)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented, ")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        // Navigation bar'ın yüksekliğini ayarla
        print("current: \(currentUserEmail)")
        print("other: \(otherUserEmail)")
        
        backButtonConfigure()
        
        userImageUI()
        
        callButtonsUI()
        
        userInfoUI()
        
        buttonsUI()
        
        fetchUserInformation()
        
    }
    
    private func fetchUserInformation() {
        DatabaseManager.shared.fetchUserInformation(otherUserEmail: otherUserEmail) { result in
            switch result {
            case .success(let returnedUserData as [String: Any]?):
                guard let userData = returnedUserData,
                      let userName = userData["name"] as? String else {
                    return
                }
                
                
                
                self.userNameLabel.text = userName
                
            case .failure(let failure):
                print("failure ", failure)
            }
        }
        
        let path = "images/\(self.otherUserEmail)_profile_picture.png"
        
        StorageManager.shared.downloadUrl(for: path) { [weak self] result in
            switch result {
            case .success(let url):
                DispatchQueue.main.async {
                    self?.userImageView.sd_setImage(with: url)
                    self?.imageView.sd_setImage(with: url)
                   
                }
                self?.imageView.frame.size.height = (self?.view.height ?? 0)/4
            case .failure(let error):
                print("failed to get image: \(error)")
            }
        }
    }
    
    // State enum tanımlaması
    enum ProfileState {
        case inviteFriends
        case alreadyFriends
        case incominRequests
        case sendedRequests
    }

    // Follow button için işlevi belirle
    func configureFollowButtonForState(_ state: ProfileState) {
        switch state {
        case .inviteFriends:
            configureForInvite()
        case .alreadyFriends:
            configureForFriend()
        case .incominRequests:
            configureIncomingReq()
        case .sendedRequests:
            print("sended")
        }
    }
    
    private func configureIncomingReq() {
        voiceCallButton.isHidden = true
        videoCallButton.isHidden = true
        messageButton.isHidden = true
        
        followButton.setTitle("Accept the request", for: .normal)
    }
    
    private func configureForInvite() {
        voiceCallButton.isHidden = true
        videoCallButton.isHidden = true
        messageButton.isHidden = true
        backButton.isHidden = true
        
        DatabaseManager.shared.isSentRequest(currentUserEmail: currentUserEmail, otherUserEmail: otherUserEmail) { success in
            if success {
                self.followButton.setTitle("Response awaited", for: .normal)
                self.isSent = true
            } else {
                self.followButton.setTitle("Follow", for: .normal)
                self.isSent = false
            }
        }
        
    }
    
    private func configureForFriend() {
        followButton.setTitle("Unfollow", for: .normal)
        
    }
    
    private func buttonsUI() {
     
        followButton.backgroundColor = .link
        followButton.setTitleColor(.white, for: .normal)
        followButton.layer.cornerRadius = 18
        followButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        followButton.addTarget(self, action: #selector(handleUnf), for: .touchUpInside)

        messageButton.setTitle("Send message", for: .normal)
        messageButton.backgroundColor = .link
        messageButton.setTitleColor(.white, for: .normal)
        messageButton.layer.cornerRadius = 18
    
        lineView.widthAnchor.constraint(equalToConstant: 0.5).isActive = true
        lineView.backgroundColor = .lightGray
        
        buttonsForFriendsUI = HorizontalStackView(arrangedSubviews: [
            followButton,
            lineView,
            messageButton
        ], spacing: 15, distrubiton: .equalCentering)
        
        view.addSubview(buttonsForFriendsUI)
        buttonsForFriendsUI.anchor(top: bioLabel.bottomAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 15, left: 15, bottom: 0, right: 15), size: .init(width: 0, height: 40))
        
        followButton.widthAnchor.constraint(equalTo: messageButton.widthAnchor).isActive = true
        
    }
    
    @objc private func handleUnf() {
        
        guard let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
            return
        }
        
        if profileState == .inviteFriends {
            
            if isSent {
                
                DatabaseManager.shared.deleteAndCancelRequest(for: currentUserEmail, targetUserEmail: otherUserEmail, isDelete: false) { succs in
                    if succs {
                        self.followButton.setTitle("Follow", for: .normal)
                        self.isSent = false
                    }
                    
                }
                
            } else {
                
                DatabaseManager.shared.sendFriendsRequest(currentUserEmail: currentUserEmail, currentUserName: currentName, targetUserEmail: otherUserEmail) { success, isAlreadySent in
                    if success {
                        self.followButton.setTitle("Response awaited", for: .normal)
                        self.isSent = true
                    }
                }
                
            }
            
        } else if profileState == .alreadyFriends {
            
            self.messageButton.isHidden = true
            self.lineView.isHidden = true
            
            UIView.animate(withDuration: 0.5, animations: {
                   // followButton'ın yeni konumu
                self.followButton.setTitle("Follow", for: .normal)
                self.followButton.backgroundColor = #colorLiteral(red: 0.2253842354, green: 0.2760212123, blue: 0.3178661764, alpha: 1)
                self.followButton.center.x += self.view.frame.width / 2
                
            })
            
            DatabaseManager.shared.deleteFriends(for: currentUserEmail, targetUserEmail: otherUserEmail) { success in
                if success {
                    self.configureForInvite()
                } else {
                    
                }
            }
        } else if profileState == .incominRequests {
            
            self.messageButton.isHidden = false
            self.videoCallButton.isHidden = false
            self.voiceCallButton.isHidden = false
            print("istek kabul edildi")
        }
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
        
        view.addSubview(userImageView)
        userImageView.backgroundColor = .darkGray
        userImageView.anchor(top: nil, leading: nil, bottom: imageView.bottomAnchor, trailing: nil, padding: .init(top: 0, left: 0, bottom: -view.height/16, right: 0), size: .init(width: view.height/8, height: view.height/8))
        userImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        userImageView.layer.cornerRadius = view.height/16
        userImageView.layer.borderWidth = 1.0
        userImageView.layer.borderColor = UIColor.white.cgColor
    }
    
    private func backButtonConfigure() {
        view.addSubview(imageView)
        imageView.anchor(top: view.topAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, size: .init(width: view.width, height: view.height/4))
        imageView.alpha = 0.7
        
        
        backButton.backgroundColor = #colorLiteral(red: 0.2253842354, green: 0.2760212123, blue: 0.3178661764, alpha: 1)
        backButton.layer.cornerRadius = 8
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        navigationController?.navigationBar.isHidden = true
        backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        backButton.tintColor = .white
        
        view.addSubview(backButton)
        backButton.anchor(top: imageView.topAnchor, leading: imageView.leadingAnchor, bottom: nil, trailing: nil, padding: .init(top: 40, left: 20, bottom: 0, right: 0), size: .init(width: 40, height: 40))
        
    }
    
    @objc private func handleBack() {
        navigationController?.navigationBar.isHidden = false

        self.navigationController?.popViewController(animated: true)
    }
    
}
