//
//  ProfileViewController.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 22.08.2023.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import SDWebImage
import FirebaseDatabase

final class ProfileViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!

    var data = [ProfileViewModel]()
    
    var label = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: ProfileTableViewCell.identifier)
        tableView.separatorStyle = .none
        dataArrayUpdate()
        view.backgroundColor = UIColor(#colorLiteral(red: 0.9638196826, green: 0.9687927365, blue: 1, alpha: 1))
        tableView.backgroundColor = UIColor(#colorLiteral(red: 0.9638196826, green: 0.9687927365, blue: 1, alpha: 1))
        self.view.addGlobalUnsafeAreaView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = createTableHeader()
        label.text = "\(UserDefaults.standard.value(forKey: "name") as? String ?? "No name")"

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        print("dis appear çalıştı")
    }
    
    @IBAction func LogOutAndExit(_ sender: Any) {
        let actionSheet = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Log out and Exit", style: .destructive, handler: { [weak self] _ in
            
            guard let strongSelf = self else { return }
            
            DatabaseReference.setUserOnlineStatus(isOnline: false, lastOnline: lastOnlineConstant)
            
            UserDefaults.standard.setValue(nil, forKey: "email")
            UserDefaults.standard.setValue(nil, forKey: "name")
            //logout facebook
           
            FBSDKLoginKit.LoginManager().logOut()
            
            //google log out
            GIDSignIn.sharedInstance.signOut()
            
            do {
                try FirebaseAuth.Auth.auth().signOut()
               // self?.data.removeAll()
                let vc = InitialScreenVC()
              //  exit(0)
                let navControl = UINavigationController(rootViewController: vc)
                navControl.modalPresentationStyle = .fullScreen
                strongSelf.present(navControl, animated: false)
                
                
            } catch {
                print("failed to sign out")
            }
            
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        self.present(actionSheet, animated: true)
    }
    
    
    private func dataArrayUpdate() {
        
        data.append(ProfileViewModel(viewModelType: .info, title: "Invite a friend", titleResult: "add-user-2", handler: {
            let inviteVC = InviteFriendViewController()
            self.navigationController?.pushViewController(inviteVC, animated: true)
        }, padding: 20))
        
        data.append(ProfileViewModel(viewModelType: .info, title: "Edit Profile", titleResult: "edit-4", handler: {
            let editVC = EditProfileViewController()
            editVC.navigationItem.hidesBackButton = true
            self.navigationController?.pushViewController(editVC, animated: true)
        }, padding: 20))
        
        data.append(ProfileViewModel(viewModelType: .info, title: "Settings", titleResult: "wheel", handler: {
            let settingsVC = SettingsViewController()
            settingsVC.navigationItem.hidesBackButton = true
            self.navigationController?.pushViewController(settingsVC, animated: true)
        }, padding: 20))
        
        data.append(ProfileViewModel(viewModelType: .info, title: "About us", titleResult: "about-2", handler: {
            let aboutVC = InviteFriendViewController()
            self.navigationController?.pushViewController(aboutVC, animated: true)
        }, padding: 20))
        
        
        
    }

    public func createTableHeader() -> UIView? {
        
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        print("email", email)
        let safeEmail = DatabaseManager.safeEmail(emaildAddress: email)
        let fileName = safeEmail + "_profile_picture.png"
        let path = "/images/"+fileName
        
        let headerView = UIView(frame: CGRect(x: 0,
                                              y: 0,
                                              width: self.view.width,
                                              height: 180))
        
        let imageView = UIImageView(frame: CGRect(x: (headerView.width - 100) / 2,
                                                  y: 20,
                                                  width: 100,
                                                  height: 100))
        
        label = UILabel(frame: CGRect(x: 0,
                                          y: 130,
                                          width: self.view.width,
                                          height: 30))
        
        label.text = "\(UserDefaults.standard.value(forKey: "name") as? String ?? "No name")"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        
        imageView.contentMode = .scaleAspectFill
        imageView.layer.borderColor = UIColor.gray.cgColor
        imageView.layer.borderWidth = 3
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = imageView.width/2
        headerView.addSubview(imageView)
        headerView.addSubview(label)
        
        StorageManager.shared.downloadUrl(for: path) { result in
            switch result {
            case .success(let url):
                print("Profile view URL: \(url)")
                imageView.sd_setImage(with: url)
            case .failure(let error):
                print("Failed to get download url: \(error)")
            }
        }
        
        return headerView
        
    }
    
    private func animateCellSelection(at indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }

        UIView.animate(withDuration: 0.2, animations: {
            cell.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            
        }) { _ in
            UIView.animate(withDuration: 0.2) {
                cell.transform = .identity
                
            }
        }
    }

}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewmodel = data[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ProfileTableViewCell.identifier, for: indexPath) as! ProfileTableViewCell
        cell.heightAnchor.constraint(equalToConstant: 60).isActive = true
        cell.setUP(with: viewmodel)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        animateCellSelection(at: indexPath)
        data[indexPath.row].handler?()
       
    }
    

   
}


