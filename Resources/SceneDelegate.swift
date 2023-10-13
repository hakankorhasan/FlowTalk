//
//  SceneDelegate.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 22.08.2023.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
    }

    
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Kullanıcının güvenli e-posta adresini alın
        /*guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emaildAddress: currentEmail)

        // "users" düğümüne erişim
        let usersRef = Database.database().reference().child("users")
        let refOnline = Database.database().reference().child(safeEmail).child("isOnline")
        refOnline.setValue(true)
        // "users" düğümü içindeki her kullanıcı verisini döngü ile gezme
        usersRef.observe(.childAdded) { (snapshot) in
            if let userData = snapshot.value as? [String: Any], let email = userData["email"] as? String, email == safeEmail {
                // E-posta adresi güvenli e-posta ile eşleşiyor, "isOnline" değerini "true" yapın
                let isOnlineRef = usersRef.child(snapshot.key).child("isOnline")
                
                isOnlineRef.setValue(true) { (error, reference) in
                    if let error = error {
                        print("isOnline güncelleme hatası: \(error)")
                    } else {
                        print("isOnline başarıyla güncellendi.")
                    }
                }
            }
        }*/
        DatabaseReference.setUserOnlineStatus(isOnline: true)
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Kullanıcının güvenli e-posta adresini alın
      /*  guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emaildAddress: currentEmail)

        // "users" düğümüne erişim
        let usersRef = Database.database().reference().child("users")
        let refOnline = Database.database().reference().child(safeEmail).child("isOnline")
               refOnline.setValue(false)
        // "users" düğümü içindeki her kullanıcı verisini döngü ile gezme
        usersRef.observe(.childAdded) { (snapshot) in
            if let userData = snapshot.value as? [String: Any], let email = userData["email"] as? String, email == safeEmail {
                // E-posta adresi güvenli e-posta ile eşleşiyor, "isOnline" değerini "true" yapın
                let isOnlineRef = usersRef.child(snapshot.key).child("isOnline")
                
                isOnlineRef.setValue(false) { (error, reference) in
                    if let error = error {
                        print("isOnline güncelleme hatası: \(error)")
                    } else {
                        print("isOnline başarıyla güncellendi.")
                    }
                }
            }
        }*/
        DatabaseReference.setUserOnlineStatus(isOnline: false)
    }


    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

