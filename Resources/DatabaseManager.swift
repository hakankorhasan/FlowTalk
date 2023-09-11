//
//  DatabaseManager.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 30.08.2023.
//

import UIKit
import FirebaseDatabase

class DatabaseManager {
    
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()

}

extension DatabaseManager {
    
    public func userExists(with email: String, completion: @escaping ((Bool) -> Void)) {
        
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        database.child(safeEmail).observeSingleEvent(of: .value) { snapshot in
            
            // sıfıra eşit değilse yani aynı mail de başka bir tane daha var ise false döndürür
            guard snapshot.value as? String != nil else {
                completion(false)
                return
            }
            
            completion(true)
        }
        
    }
    
    public func insertUser(with user: ChatAppUser, completion: @escaping (Bool) -> Void) {
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name": user.firstName
        ]) { error, _ in
            guard error == nil else {
                print("failed at write to database")
                completion(false)
                return
            }
            completion(true)
        }
    }
}


struct ChatAppUser {
    let firstName: String
    let lastName: String
    let emailAddress: String
    
    var safeEmail: String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    var profilePictureFileName: String {
        //hakan-gmail-com_profile_picture.png
        return "\(safeEmail)_profile_picture.png"
    }
}
