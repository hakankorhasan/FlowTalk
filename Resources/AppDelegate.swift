//
//  AppDelegate.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 22.08.2023.
//

import UIKit
import FBSDKCoreKit
import FirebaseCore
import GoogleSignIn
import FirebaseAuth

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    

    func application(
        _ application: UIApplication,
          didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
    
        FirebaseApp.configure()
              
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if error != nil || user == nil {
              // Show the app's signed-out state.
            } else {
              // Show the app's signed-in state.
            }
          }
        
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
    
        return true
     }
    
      
    func application(
       _ app: UIApplication,
         open url: URL,
         options: [UIApplication.OpenURLOptionsKey : Any] = [:]
              ) -> Bool {
         ApplicationDelegate.shared.application(
            
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )
                  
        var handled: Bool

        handled = GIDSignIn.sharedInstance.handle(url)
        if handled {
            return true
        }

        // Handle other custom URL types.

        // If not handled by this app, return false.
        return false
    }
    
    
}

enum AuthenticationError: Error {
    
case tokenError(message: String)
}
