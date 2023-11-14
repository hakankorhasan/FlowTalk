//
//  NotificationSettingVC.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 12.11.2023.
//

import UIKit
 
class NotificationSettingVC: UIViewController {
    
    let chatVoiceSwitch = UISwitch()
    let highPriortySwitch = UISwitch()
    let selectedNotifSound = UILabel(text: "Default", font: .systemFont(ofSize: 11, weight: .regular), textColor: .darkGray)
    let selectedVibration = UILabel(text: "Default", font: .systemFont(ofSize: 11, weight: .regular), textColor: .darkGray)
    
    let selectedRingtone = UILabel(text: "Default", font: .systemFont(ofSize: 11, weight: .regular), textColor: .darkGray)
    let selectedVibrationCall = UILabel(text: "Default", font: .systemFont(ofSize: 11, weight: .regular), textColor: .darkGray)
    
    
    var chatVoiceStackView = UIStackView()
    var messagesStackView = UIStackView()
    var callsStackView = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Notifications"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = UIColor(#colorLiteral(red: 0.9638196826, green: 0.9687927365, blue: 1, alpha: 1))
        let backButton = UIButton(type: .custom)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
        
        let customButton = UIBarButtonItem(customView: backButton)
        backButton.tintColor = .black
        backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        navigationItem.leftBarButtonItem = customButton
        
        configureChatVoiceUI()
        configureMessagesUI()
        configureCallsUI()
    }
    
    private func configureChatVoiceUI() {
        let chatVoiceLabel = UILabel(text: "Chat sounds", font: .systemFont(ofSize: 14, weight: .bold), textColor: .black)
        
        let subtitle = UILabel(text: "The sound is played when you receive or send a message", font: .systemFont(ofSize: 11, weight: .regular), textColor: .darkGray, numberOfLines: 2)
        
        chatVoiceStackView = HorizontalStackView(arrangedSubviews: [
            VerticalStackView(arrangedSubviews: [
                chatVoiceLabel,
                subtitle,
            ]),
            chatVoiceSwitch
        ], distrubiton: .fillProportionally)
        
        view.addSubview(chatVoiceStackView)
        chatVoiceStackView.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 20, left: 20, bottom: 0, right: 20))
        
        let lineView = UIView()
        lineView.translatesAutoresizingMaskIntoConstraints = false
        lineView.backgroundColor = .black
        lineView.heightAnchor.constraint(equalToConstant: 0.33).isActive = true
        view.addSubview(lineView)
        lineView.anchor(top: chatVoiceStackView.bottomAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 15, left: 0, bottom: 0, right: 0), size: .init(width: 0, height: 0.33))
       
    }
    
    private func configureMessagesUI() {
        let messagesLabel = UILabel(text: "Messages", font: .systemFont(ofSize: 16, weight: .heavy), textColor: .black)
        
        // first stack
        let notifSoundLabel = UILabel(text: "Notification sound", font: .systemFont(ofSize: 14, weight: .bold))
        
        // second stack
        let vibrationLabel = UILabel(text: "Vibration", font: .systemFont(ofSize: 14, weight: .bold))
        
        // third stack
        let useHighPriortyNotf = UILabel(text: "Use high priority notifications", font: .systemFont(ofSize: 14, weight: .bold))
        let subtitleHighPri = UILabel(text: "Previews of notifications are shown at the top of the screen", font: .systemFont(ofSize: 11, weight: .regular), textColor: .darkGray, numberOfLines: 2)
        
        let firstStack = VerticalStackView(arrangedSubviews: [
            notifSoundLabel,
            selectedNotifSound
        ], spacing: 3)
        
        let secondStack = VerticalStackView(arrangedSubviews: [
            vibrationLabel,
            selectedVibration
        ], spacing: 3)
        
        let thirdStack = HorizontalStackView(arrangedSubviews: [
            VerticalStackView(arrangedSubviews: [
                useHighPriortyNotf,
                subtitleHighPri
            ]),
            highPriortySwitch
        ], distrubiton: .fillProportionally)
        
        messagesStackView = VerticalStackView(arrangedSubviews: [
            messagesLabel,
            firstStack,
            secondStack,
            thirdStack
        ], spacing: 20)
        
        view.addSubview(messagesStackView)
        messagesStackView.anchor(top: chatVoiceStackView.bottomAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 30, left: 20, bottom: 0, right: 20))
        
        let lineView = UIView()
        lineView.translatesAutoresizingMaskIntoConstraints = false
        lineView.backgroundColor = .black
        lineView.heightAnchor.constraint(equalToConstant: 0.33).isActive = true
        view.addSubview(lineView)
        lineView.anchor(top: messagesStackView.bottomAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 15, left: 0, bottom: 0, right: 0), size: .init(width: 0, height: 0.33))
        
    }
    
    private func configureCallsUI() {
        let callsLabel = UILabel(text: "Calls", font: .systemFont(ofSize: 16, weight: .heavy), textColor: .black)
        
        // first stack
        let ringtoneLabel = UILabel(text: "Ringing sound", font: .systemFont(ofSize: 14, weight: .bold))
        
        // second stack
        let vibrationLabel = UILabel(text: "Vibration", font: .systemFont(ofSize: 14, weight: .bold))
        
        let firstStack = VerticalStackView(arrangedSubviews: [
            ringtoneLabel,
            selectedRingtone
        ], spacing: 3)
        
        let secondStack = VerticalStackView(arrangedSubviews: [
            vibrationLabel,
            selectedVibrationCall
        ], spacing: 3)
        
        callsStackView = VerticalStackView(arrangedSubviews: [
            callsLabel,
            firstStack,
            secondStack
        ], spacing: 20)
        
        view.addSubview(callsStackView)
        callsStackView.anchor(top: messagesStackView.bottomAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 30, left: 20, bottom: 0, right: 20))
        
    }
    
    @objc fileprivate func handleBack() {
        tabBarController?.tabBar.isHidden = false
        self.navigationController?.popViewController(animated: true)
    }
}
