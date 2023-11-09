//
//  FacebookSignInManager.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 30.10.2023.
//

import UIKit
import FBSDKLoginKit
import FBSDKCoreKit
import FirebaseCore
import FirebaseDatabase
import FirebaseAuth

class FacebookSignInManager {
    
    static func signWithFacebook(viewController: UIViewController,completion: @escaping (Bool) -> Void) {
        
        var token = ""
        let loginManager = LoginManager()
        loginManager.logIn(permissions: ["public_profile", "email"], from: viewController) { result, error in
            if let error = error {
                print("error: ", error.localizedDescription)
                completion(false)
            } else if let result = result, result.isCancelled {
                print("cancelled")
            } else {
                token = result?.token?.tokenString ?? ""
                
                let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me",
                                                                 parameters: ["fields": "email, first_name, last_name, picture.type(large)"],
                                                                 tokenString: token,
                                                                 version: nil,
                                                                 httpMethod: .get)
                
                facebookRequest.start { _, result, error in
                    guard let result = result as? [String: Any],
                          error == nil else {
                        print("failed to make faceb graph request ")
                        return
                    }
                    
                    guard let firstName = result["first_name"] as? String,
                          let lastName = result["last_name"] as? String,
                          let email = result["email"] as? String,
                          let picture = result["picture"] as? [String: Any],
                          let data = picture["data"] as? [String: Any],
                          let pictureUrl = data["url"] as? String else {
                          print("failed to get email and name from fb result")
                        return
                    }
                    
                    UserDefaults.standard.set(email, forKey: "email")
                    UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
                    
                    DatabaseManager.shared.userExists(with: email) { exists in
                        if !exists {
                            
                            let chatUser = ChatAppUser(firstName: firstName, lastName: lastName, countryCode: 00, phoneNumber: 0000000000, password: "facebook-password", emailAddress: email, isOnline: false, lastOnline: "")
                            DatabaseManager.shared.insertUser(with: chatUser) { success in
                                if success {
                                 
                                    DatabaseReference.setUserOnlineStatus(isOnline: true, lastOnline: "")
                                    guard let url = URL(string: pictureUrl) else { return }
                                    
                                    print("Downloading data from facebook image")
                                    
                                    URLSession.shared.dataTask(with: url) { data, _, _ in
                                        //response ve error ile işimiz olmadığı için _ koyuyoruz
                                        //sadece data verisinin indirilmesi işlemi gerçekliyor
                                        guard let data = data else {
                                            print("failed to get data from facebook")
                                            return
                                        }
                                        
                                        print("get data from FB, uploading...")
                                        
                                        let fileName = chatUser.profilePictureFileName
                                        StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName) { result in
                                            
                                            switch result {
                                            case .success(let downloadUrl):
                                                UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                                print("download urllllllllllllllllll")
                                                print(downloadUrl)
                                            case .failure(let error):
                                                
                                                print("storage manager error: \(error)")
                                            }
                                        }
                                    }.resume()
                                
                                }
                            }
                        }
                    }
                    
                    let credential = FacebookAuthProvider.credential(withAccessToken: token)
                    
                    FirebaseAuth.Auth.auth().signIn(with: credential) { authResult, error in
                        
                        DatabaseReference.setUserOnlineStatus(isOnline: true, lastOnline: "")
                        
                        guard result != nil, error == nil else {
                            
                            if let error = error {
                                print("Facebook credential login failed, MFA may be needed - \(error)")
                            }
                            completion(false)
                            return
                        }
                        
                        
                        print("Succesfully logged user in")
                        completion(true)
                    }
                }
                
            }
            
        }
    
        
    }
}

