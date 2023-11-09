//
//  GoogleSignInManager.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 30.10.2023.
//

import UIKit
import GoogleSignIn
import FirebaseAuth
import FirebaseDatabase
import FirebaseCore

class GoogleSignInManager {
   
    static func signInWithGoogle(viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
             return
        }
        
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        GIDSignIn.sharedInstance.signIn(withPresenting: viewController) { signInResult, error in
            guard error == nil else { return }
            
            guard let user = signInResult?.user,
                  let idToken = user.idToken?.tokenString else {
                print("missing auth object off of google user")
                return
            }
            
            print("did sign in with google \(user)")
            
            var isOnl: Bool? = false
            var lastOnl: String? = ""
            
            guard let email = user.profile?.email,
                  let firstName = user.profile?.givenName,
                  let lastName = user.profile?.familyName,
                  let isOnline = isOnl,
                  let lastOnline = lastOnl else { return }
            
            UserDefaults.standard.set(email, forKey: "email")
            UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
            
            DatabaseManager.shared.userExists(with: email) { exists in
                if !exists {
                    
                    let chatUser = ChatAppUser(firstName: firstName,
                                               lastName: lastName, countryCode: 00,
                                               phoneNumber: 0000000000,
                                               password: "google-password",
                                               emailAddress: email,
                                               isOnline: isOnline,
                                               lastOnline: lastOnline)
                    
                    DatabaseManager.shared.insertUser(with: chatUser) { success in
                        if success {
                            
                            DatabaseReference.setUserOnlineStatus(isOnline: true, lastOnline: "")
                            
                            if ((user.profile?.hasImage) != nil) {
                                guard let url = user.profile?.imageURL(withDimension: 200) else { return }
                                
                                URLSession.shared.dataTask(with: url) { data, _, _ in
                                    guard let data = data else { return }
                                    
                                    let fileName = chatUser.profilePictureFileName
                                    
                                    StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName) { result in
                                        switch result {
                                        case .success(let downloadUrl):
                                            UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                        case .failure(let error):
                                            print("storage manager error: \(error)")
                                        }
                                    }
                                }.resume()
                            }
                        }
                    }
                }
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
            
            FirebaseAuth.Auth.auth().signIn(with: credential) { authResult, error in
                DatabaseReference.setUserOnlineStatus(isOnline: true, lastOnline: "")
                
                guard authResult != nil, error == nil else {
                    print("failed to log in with google credential")
                    return
                }
                
                print("successfully signed in with google")
                NotificationCenter.default.post(name: .didLogInNotification, object: nil)
            }
            
        }
    }
}
