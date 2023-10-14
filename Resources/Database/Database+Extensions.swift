//
//  Database+Extensions.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 14.10.2023.
//

import Foundation
import FirebaseDatabase

extension DatabaseReference {
    static func setUserOnlineStatus(isOnline: Bool, lastOnline: String) {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emaildAddress: currentEmail)
        
        let usersRef = Database.database().reference().child("users")
        let refOnline = Database.database().reference().child(safeEmail).child("isOnline")
        let lastOnlRef = Database.database().reference().child(safeEmail).child("lastOnline")
        lastOnlRef.setValue(lastOnline)
        refOnline.setValue(isOnline)
        
        usersRef.observe(.childAdded) { (snapshot) in
            if let userData = snapshot.value as? [String: Any],
               let email = userData["email"] as? String,
               email == safeEmail {
                let isOnlineRef = usersRef.child(snapshot.key).child("isOnline")
                let lastOnlineRef = usersRef.child(snapshot.key).child("lastOnline")
                
                isOnlineRef.setValue(isOnline) { (error, reference) in
                    if let error = error {
                        print("isOnline error update error: ", error)
                    } else {
                        print("isOnline successfully updated.")
                    }
                }
                
                lastOnlineRef.setValue(lastOnline) { (error, reference) in
                    if let error = error {
                        print("lastOnline error update error: ", error)
                    } else {
                        print("lastOnline successfully updated.")
                    }
                }
            }
        }
       /* if let currentEmail = UserDefaults.standard.value(forKey: "email") as? String {
            let safeEmail = DatabaseManager.safeEmail(emaildAddress: currentEmail)
            let usersRef = Database.database().reference().child("users")
            let userRef = usersRef.child(safeEmail).child("isOnline")
            
            userRef.setValue(isOnline) { (error, reference) in
                if let error = error {
                    print("isOnline güncelleme hatası: \(error)")
                } else {
                    print("isOnline başarıyla güncellendi.")
                }
            }
        }*/
    }
}
