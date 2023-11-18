//
//  ChatSettingVC.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 12.11.2023.
//

import UIKit

class ChatSettingVC: UIViewController {
    
    let selectedTheme = UILabel(text: "Light", font: .systemFont(ofSize: 11, weight: .regular), textColor: .darkGray)
    let switchButton = UISwitch()
    
    var themeStackView = UIStackView()
    var wallpaperStackView = UIStackView()
    var chatStackView = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Chats"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = UIColor(#colorLiteral(red: 0.9638196826, green: 0.9687927365, blue: 1, alpha: 1))
        let backButton = UIButton(type: .custom)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
        
        let customButton = UIBarButtonItem(customView: backButton)
        backButton.tintColor = .black
        backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        navigationItem.leftBarButtonItem = customButton
        
        
        configureVisualUI()
        configureChatUI()
    }
    
    @objc fileprivate func handleBack() {
        tabBarController?.tabBar.isHidden = false
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func handleWallpaper() {
        let chatThemeVC = ChatThemeSetting()

        self.navigationController?.pushViewController(chatThemeVC, animated: true)
    }
    
}

// UI Design codes
extension ChatSettingVC {
    private func configureVisualUI() {
        let visualizationLabel = UILabel(text: "Visualization", font: .systemFont(ofSize: 16, weight: .heavy), textColor: .black)
        
        view.addSubview(visualizationLabel)
        let themeIcon = UIImageView()
        let themeTitle = UILabel(text: "Theme", font: .systemFont(ofSize: 13, weight: .bold))
        
        let wallpaperIcon = UIImageView()
        let wallpaperLabel = UILabel(text: "Wallpaper", font: .systemFont(ofSize: 13, weight: .bold))
        
        visualizationLabel.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 15, left: 20, bottom: 0, right: 20))
        
        themeIcon.widthAnchor.constraint(equalToConstant: 36).isActive = true
        themeIcon.image = UIImage(systemName: "moonphase.last.quarter")
        themeIcon.tintColor = .black

        themeStackView = HorizontalStackView(arrangedSubviews: [
            themeIcon,
            VerticalStackView(arrangedSubviews: [
                themeTitle,
                selectedTheme
            ], spacing: 3)
        ], spacing: 15, distrubiton: .fillProportionally)
        
        view.addSubview(themeStackView)
        themeStackView.anchor(top: visualizationLabel.bottomAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 10, left: 20, bottom: 0, right: 20), size: .init(width: 0, height: 36))
    
        wallpaperIcon.widthAnchor.constraint(equalToConstant: 36).isActive = true
        wallpaperIcon.image = UIImage(systemName: "camera.viewfinder")
        wallpaperIcon.tintColor = .black
        
        wallpaperStackView = HorizontalStackView(arrangedSubviews: [
            wallpaperIcon,
            wallpaperLabel
        ], spacing: 15, distrubiton: .fillProportionally)
        
        view.addSubview(wallpaperStackView)
        wallpaperStackView.anchor(top: themeStackView.bottomAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 20, left: 20, bottom: 0, right: 20), size: .init(width: 0, height: 36))
        wallpaperStackView.isUserInteractionEnabled = true
        let wallpaperGesture = UITapGestureRecognizer(target: self, action: #selector(handleWallpaper))
        wallpaperStackView.addGestureRecognizer(wallpaperGesture)
        
        let lineView = UIView()
        lineView.translatesAutoresizingMaskIntoConstraints = false
        lineView.backgroundColor = .black
        lineView.heightAnchor.constraint(equalToConstant: 0.33).isActive = true
        view.addSubview(lineView)
        lineView.anchor(top: wallpaperStackView.bottomAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 15, left: 0, bottom: 0, right: 0))

    }
    
    private func configureChatUI() {
        let chatSettingLabel = UILabel(text: "Chat settings", font: .systemFont(ofSize: 16, weight: .heavy), textColor: .black)
        
        let title = UILabel(text: "Sends enter key", font: .systemFont(ofSize: 13, weight: .bold))
        let subtitle = UILabel(text: "The enter key sends your message.", font: .systemFont(ofSize: 11, weight: .regular), textColor: .darkGray)
        
        view.addSubview(chatSettingLabel)
        
        chatSettingLabel.anchor(top: wallpaperStackView.bottomAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 30, left: 20, bottom: 0, right: 20))
        
        chatStackView = HorizontalStackView(arrangedSubviews: [
            VerticalStackView(arrangedSubviews: [
                title,
                subtitle
            ]),
            switchButton
        ], distrubiton: .fillProportionally)
        
        view.addSubview(chatStackView)
        chatStackView.anchor(top: chatSettingLabel.bottomAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 15, left: 40, bottom: 0, right: 20), size: .init(width: 0, height: 41))
    }
    
}
