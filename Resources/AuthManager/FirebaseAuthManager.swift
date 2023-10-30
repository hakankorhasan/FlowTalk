//
//  FirebaseAuthManager.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 30.10.2023.
//

import FirebaseCore
import FirebaseAuth
import FirebaseDatabase
import JGProgressHUD

class FirebaseAuthManager {
    static func signInWithFirebase(viewController: UIViewController, email: String, password: String, completion: @escaping (Bool) -> Void) {
        
        let spinner = JGProgressHUD(style: .dark)
        
        guard !email.isEmpty, !password.isEmpty, password.count >= 6 else {
            return
        }
        
        spinner.show(in: viewController.view)
        
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            
            DispatchQueue.main.async {
                spinner.dismiss()
            }
            
            guard authResult != nil, error == nil else {
                print("login error: ", error)
                completion(false)
                return
            }
            
            let user = authResult?.user
            
            let safeEmail = DatabaseManager.safeEmail(emaildAddress: email)
            
            DatabaseManager.shared.getDataFor(path: safeEmail) { result in
                switch result {
                case .success(let data):
                    guard let userData = data as? [String:Any],
                          let firstName = userData["first_name"] as? String,
                          let lastName = userData["last_name"] as? String else {
                        completion(false)
                            return
                        }
                    
                    DatabaseReference.setUserOnlineStatus(isOnline: true, lastOnline: "")
                    
                    UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
                case .failure(let error):
                    print("result for data error: \(error)")
                }
            
            }
            
            UserDefaults.standard.set(email, forKey: "email")
            
            completion(true)
        }
    }
}
