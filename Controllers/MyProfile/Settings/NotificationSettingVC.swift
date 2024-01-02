//
//  NotificationSettingVC.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 12.11.2023.
//

import UIKit
import FirebaseDatabase
 
class NotificationSettingVC: UIViewController {
    
    var notificationSettingsView: NotificationSettingsView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
       title = "Notifications"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = UIColor(#colorLiteral(red: 0.9638196826, green: 0.9687927365, blue: 1, alpha: 1))
        let backButton = UIButton(type: .custom)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
        self.view.addGlobalUnsafeAreaView()

        let customButton = UIBarButtonItem(customView: backButton)
        backButton.tintColor = .black
        backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        navigationItem.leftBarButtonItem = customButton
        
        notificationViewConfigure()
    }
   
    
    private func notificationViewConfigure() {
        
        notificationSettingsView = NotificationSettingsView()
        view.addSubview(notificationSettingsView)
        notificationSettingsView.translatesAutoresizingMaskIntoConstraints = false
        notificationSettingsView.anchor(top: view.safeAreaLayoutGuide.topAnchor,
                                        leading: view.leadingAnchor,
                                        bottom: view.bottomAnchor,
                                        trailing: view.trailingAnchor)
        
        let settings: [UserSetting] = [.chatSounds, .highPrioNotification]
        
        //let chatVoiceSwitchValue = settings[0].
        let chatVoiceSwitchValue = getUserSetting(status: .current, setting: .chatSounds)
        
        let highPrioSwitchValue = getUserSetting(status: .current, setting: .highPrioNotification)
        
        notificationSettingsView.chatVoiceSwitch.isOn = chatVoiceSwitchValue
        
        notificationSettingsView.highPriortySwitch.isOn = highPrioSwitchValue
        
        notificationSettingsView.chatVoiceSwitch.addTarget(self, action: #selector(chatSwitchValueChanged), for: .valueChanged)
        notificationSettingsView.highPriortySwitch.addTarget(self, action: #selector(prioritySwitchValueChanged), for: .valueChanged)
    }
    
    private func updateUserSetting(_ setting: UserSetting, _ sender: UISwitch) {
        guard let currentUser = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emaildAddress: currentUser)
        let usersRef = Database.database().reference().child("users")
        
        usersRef.observe(.childAdded) { (snapshot) in
            if let userData = snapshot.value as? [String: Any],
               let email = userData["email"] as? String,
               email == safeEmail {
               
                let lastOnlineRef = usersRef.child(snapshot.key).child("user_settings").child(setting.rawValue)
                print(lastOnlineRef)
                
                lastOnlineRef.setValue(sender.isOn) { (error, reference) in
                    if let error = error {
                        print("lastOnline error update error: ", error)
                    } else {
                        print("lastOnline successfully updated.")
                        setUserSetting(status: .current, setting: setting, value: sender.isOn)
                    }
                }
            }
        }
    }
    
    @objc private func chatSwitchValueChanged(_ sender: UISwitch) {
        updateUserSetting(.chatSounds, sender)
    }

    @objc private func prioritySwitchValueChanged(_ sender: UISwitch) {
        updateUserSetting(.highPrioNotification, sender)
    }
    
    @objc fileprivate func handleBack() {
        tabBarController?.tabBar.isHidden = false
        self.navigationController?.popViewController(animated: true)
    }
}

class NotificationSettingsView: UIView {
    
    let chatVoiceSwitch = UISwitch()
    let highPriortySwitch = UISwitch()
    let selectedNotifSound = UILabel()
    let selectedVibration = UILabel()
    let selectedRingtone = UILabel()
    let selectedVibrationCall = UILabel()
    
    var chatVoiceStackView = UIStackView()
    var messagesStackView = UIStackView()
    var callsStackView = UIStackView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureChatVoiceUI()
        configureMessagesUI()
        configureCallsUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureChatVoiceUI() {
        //... (previous implementation)
        let chatVoiceLabel = UILabel(text: "Chat sounds", font: .systemFont(ofSize: 14, weight: .bold), textColor: .black)
        
        let subtitle = UILabel(text: "The sound is played when you receive or send a message", font: .systemFont(ofSize: 11, weight: .regular), textColor: .darkGray, numberOfLines: 2)
        
        chatVoiceStackView = HorizontalStackView(arrangedSubviews: [
            VerticalStackView(arrangedSubviews: [
                chatVoiceLabel,
                subtitle,
            ]),
            chatVoiceSwitch
        ], distrubiton: .fillProportionally)
        
        addSubview(chatVoiceStackView)
        chatVoiceStackView.anchor(top: safeAreaLayoutGuide.topAnchor, leading: leadingAnchor, bottom: nil, trailing: trailingAnchor, padding: .init(top: 20, left: 20, bottom: 0, right: 20))
        
        let lineView = UIView()
        lineView.translatesAutoresizingMaskIntoConstraints = false
        lineView.backgroundColor = .black
        lineView.heightAnchor.constraint(equalToConstant: 0.33).isActive = true
        addSubview(lineView)
        lineView.anchor(top: chatVoiceStackView.bottomAnchor, leading: leadingAnchor, bottom: nil, trailing: trailingAnchor, padding: .init(top: 15, left: 0, bottom: 0, right: 0), size: .init(width: 0, height: 0.33))
       
    }
    
    private func configureMessagesUI() {
        //... (previous implementation)
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
        
        addSubview(messagesStackView)
        messagesStackView.anchor(top: chatVoiceStackView.bottomAnchor, leading: leadingAnchor, bottom: nil, trailing: trailingAnchor, padding: .init(top: 30, left: 20, bottom: 0, right: 20))
        
        let lineView = UIView()
        lineView.translatesAutoresizingMaskIntoConstraints = false
        lineView.backgroundColor = .black
        lineView.heightAnchor.constraint(equalToConstant: 0.33).isActive = true
        addSubview(lineView)
        lineView.anchor(top: messagesStackView.bottomAnchor, leading: leadingAnchor, bottom: nil, trailing: trailingAnchor, padding: .init(top: 15, left: 0, bottom: 0, right: 0), size: .init(width: 0, height: 0.33))
        
    }
    
    private func configureCallsUI() {
        //... (previous implementation)
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
        
        addSubview(callsStackView)
        callsStackView.anchor(top: messagesStackView.bottomAnchor, leading: leadingAnchor, bottom: nil, trailing: trailingAnchor, padding: .init(top: 30, left: 20, bottom: 0, right: 20))

    }
}
