//
//  FirebaseRegisterManager.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 4.11.2023.
//

import UIKit
import FirebaseCore
import FirebaseDatabase
import FirebaseAuth
import JGProgressHUD

class FirebaseRegisterManager {
    
    var spinner = JGProgressHUD(style: .dark)
    
    static let shared = FirebaseRegisterManager()
    
    public func registerWithFirebase(viewController: UIViewController, userImageView: UIImageView? ,email: String?,
                                     password: String?,
                                     firstName: String?,
                                     lastName: String?, completion: @escaping (Bool) -> Void) {
        
        guard let email = email,
              let password = password,
              let firstName = firstName,
              let lastName = lastName,
              !email.isEmpty,
              !firstName.isEmpty,
              !lastName.isEmpty,
              !password.isEmpty,
              password.count >= 6 else {
            completion(false)
            return
        }
        
        spinner.show(in: viewController.view)
        
        DatabaseManager.shared.userExists(with: email) { exists in
            
            DispatchQueue.main.async {
                self.spinner.dismiss()
            }
            
            guard !exists else {
                completion(false)
                return
            }
            
            FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                
                guard authResult != nil, error == nil else {
                    print("error creating user")
                    return
                }
                
                UserDefaults.standard.setValue(email, forKey: "email")
                UserDefaults.standard.setValue("\(firstName) \(lastName)", forKey: "name")
                
                
                let chatUser = ChatAppUser(firstName: firstName, lastName: lastName, emailAddress: email, isOnline: false, lastOnline: "")
                
                DatabaseManager.shared.insertUser(with: chatUser) { success in
                    if success {
                        DatabaseReference.setUserOnlineStatus(isOnline: true, lastOnline: lastOnlineConstant)
                        
                        //upload image
                        guard let image = userImageView?.image,
                              let data = image.pngData() else {
                            return
                        }
                        
                        let fileName = chatUser.profilePictureFileName
                        
                        StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName) { result in
                            
                            switch result {
                            case .success(let downloadUrl):
                                UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                print(downloadUrl)
                            case .failure(let error):
                                print("storage maanger error: \(error)")
                            }
                        }
                    }
                }
                
                completion(true)
            }
        }
        
    }
}
