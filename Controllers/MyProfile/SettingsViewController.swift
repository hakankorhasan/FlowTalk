//
//  SettingsViewController.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 6.11.2023.
//

import UIKit

class SettingsViewController: UIViewController {
    
    
    private let tableView: UITableView = {
        let tv = UITableView()
        return tv
    }()
    
    var cells = [SettingsViewModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        
        tableViewConfigure()
        cellsArrayAppend()
        
        let backButton = UIButton(type: .custom)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
        
        let customButton = UIBarButtonItem(customView: backButton)
        backButton.tintColor = .black
        backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        view.backgroundColor = UIColor(#colorLiteral(red: 0.9638196826, green: 0.9687927365, blue: 1, alpha: 1))
        tabBarController?.tabBar.isHidden = true
    
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItem = customButton
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    private func tableViewConfigure() {
        view.addSubview(tableView)
        tableView.register(SettingsTableViewCell.self, forCellReuseIdentifier: SettingsTableViewCell.identifier)
        tableView.backgroundColor = UIColor(#colorLiteral(red: 0.9638196826, green: 0.9687927365, blue: 1, alpha: 1))
        tableView.separatorStyle = .none
    
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func cellsArrayAppend() {
        
        cells.append(SettingsViewModel(image: "lock.fill", settingTitle: "Privacy", settingContentTitle: "Last seen, user blocking", handler: {
            let privacyVC = PrivacySettingVC()
            privacyVC.navigationItem.hidesBackButton = true
            self.navigationController?.pushViewController(privacyVC, animated: true)
        }))
        
        cells.append(SettingsViewModel(image: "list.bullet.rectangle.fill", settingTitle: "Chats", settingContentTitle: "Theme, wallpapers", handler: {
            let chatSetting = ChatSettingVC()
            chatSetting.navigationItem.hidesBackButton = true
            self.navigationController?.pushViewController(chatSetting, animated: true)
        }))
        
        cells.append(SettingsViewModel(image: "bell.fill", settingTitle: "Notifications", settingContentTitle: "Message, call sounds", handler: {
            let notificationVC = NotificationSettingVC()
            notificationVC.navigationItem.hidesBackButton = true
            self.navigationController?.pushViewController(notificationVC, animated: true)
        }))
        
        cells.append(SettingsViewModel(image: "globe", settingTitle: "Application language", settingContentTitle: "English (device language)", handler: {
            
        }))
    }
    
    @objc fileprivate func handleBack() {
        tabBarController?.tabBar.isHidden = false
        self.navigationController?.popViewController(animated: true)
    }
    
    private func animateCellSelection(at indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }

        UIView.animate(withDuration: 0.2, animations: {
            cell.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            cell.backgroundColor = .white
            cell.contentView.backgroundColor = .white
        }) { _ in
            UIView.animate(withDuration: 0.2) {
                cell.transform = .identity
                cell.backgroundColor = .clear
                cell.contentView.backgroundColor = .clear
                
            } completion: { _ in
                self.cells[indexPath.row].handler?()
            }
        }
    }
}

extension SettingsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        cells.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true) // Hücre seçiminden sonra vurgulamayı kaldır
        // Animasyonu uygula
        animateCellSelection(at: indexPath)
       // cells[indexPath.row].handler?()
   }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = cells[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: SettingsTableViewCell.identifier, for: indexPath) as! SettingsTableViewCell
        cell.heightAnchor.constraint(equalToConstant: 54).isActive = true
        cell.clipsToBounds = true
        cell.setUP(with: viewModel)
        return cell
    }
    
    
}
