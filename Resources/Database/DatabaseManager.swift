//
//  DatabaseManager.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 30.08.2023.
//

import UIKit
import FirebaseDatabase
import MessageKit
import AVFoundation
import CoreLocation
import FirebaseAuth

/// Manager object to read and write data to real time firebase database
class DatabaseManager {
    
    /// Shared instance of class
    public static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    let cache = NSCache<AnyObject, AnyObject>()
    
    let lastSeen = getUserSetting(status: .current, setting: .lastSeenInfo)
    let readInfo = getUserSetting(status: .current, setting: .readReceipt)
    let onlineInfo = getUserSetting(status: .current, setting: .onlineInfo)
    let profilePhoto = getUserSetting(status: .current, setting: .profilePhoto)
    let chatSounds = getUserSetting(status: .current, setting: .chatSounds)
    let highPriNotf = getUserSetting(status: .current, setting: .highPrioNotification)
    
    static func safeEmail(emaildAddress: String) -> String {
        var safeEmail = emaildAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
}

/// MARK: - Account Managment

extension DatabaseManager {
    
    /// Returns dictionary node at child path
    public func getDataFor(path: String, completion: @escaping (Result<Any, Error>) -> Void) {
        self.database.child("\(path)").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value else  {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
}

enum FriendRequestType {
    case sendedRequests
    case incomingRequests
}

extension DatabaseManager {
    
    /// Checks if user exists for given email
    ///  Parameter:
    ///  - `email`:                Target email to be check
    ///  - `completion`:     Async closure to return with result
    public func userExists(with email: String, completion: @escaping ((Bool) -> Void)) {
        
        var safeEmail = DatabaseManager.safeEmail(emaildAddress: email)
        
        database.child(safeEmail).observeSingleEvent(of: .value) { snapshot in
            
            // sıfıra eşit değilse yani aynı mail de başka bir tane daha var ise false döndürür
            // aynı kullanıcıdan var ise users koleksiyonuna bir daha eklemez
            guard snapshot.value as? [String: Any] != nil else {
                
                completion(false)
                return
            }
            
            completion(true)
        }
        
    }
    
    public func updateProfileInformation(with user: ChatAppUser, completion: @escaping (Bool) -> Void) {
        
        Auth.auth().currentUser?.updatePassword(to: user.password, completion: { error in
            if let error = error {
                print("password is not updated")
            } else {
                print("password is successfully updated")
            }
        })
        
        let lastSeen = getUserSetting(status: .current, setting: .lastSeenInfo)
        let readInfo = getUserSetting(status: .current, setting: .readReceipt)
        let onlineInfo = getUserSetting(status: .current, setting: .onlineInfo)
        let profilePhoto = getUserSetting(status: .current, setting: .profilePhoto)
        let chatSounds = getUserSetting(status: .current, setting: .chatSounds)
        let highPriNot = getUserSetting(status: .current, setting: .highPrioNotification)
        
        database.child(user.safeEmail).updateChildValues([
            "first_name": user.firstName,
            "last_name": user.lastName,
            "isOnline": user.isOnline,
            "lastOnline": user.lastOnline,
            "country_code": user.countryCode,
            "phone_number": user.phoneNumber,
            "user_password": user.password,
            "user_settings": [
                "read_receipt": lastSeen,
                "last_seen": readInfo,
                "profile_visibility": profilePhoto,
                "online_information": onlineInfo,
                "chat_sounds": chatSounds,
                "high_priority_notf": highPriNot
            ]
        ]) { [weak self] error, _ in
             
            guard let strongSelf = self else {
                return
            }
            
            let userName = "\(user.firstName) \(user.lastName)"
            UserDefaults.standard.set(userName, forKey: "name")
            
            guard error == nil else {
                print("failed st write to database for updated")
                completion(false)
                return
            }
            
            strongSelf.database.child("users").observeSingleEvent(of: .value) { [weak self] snapshot in
                print("snapshota geldi, ", snapshot)
                guard let strongSelf = self else {
                    return
                }
                
                if var usersCollection = snapshot.value as? [[String: Any]] {
                    print("USERSS: ", usersCollection)
                    
                    for (index, existingUser) in usersCollection.enumerated() {
                        if let email = existingUser["email"] as? String,
                           email == user.safeEmail {
                            // Kullanıcı bulundu güncelleme işlemine alınabilir
                            usersCollection[index] = [
                                "name": user.firstName + " " + user.lastName,
                                "email": user.safeEmail,
                                "isOnline": user.isOnline,
                                "lastOnline": user.lastOnline,
                                "country_code": user.countryCode,
                                "phone_number": user.phoneNumber,
                                "user_password": user.password,
                                "user_settings": [
                                    "read_receipt": readInfo,
                                    "last_seen": lastSeen,
                                    "profile_visibility": profilePhoto,
                                    "online_info": onlineInfo,
                                    "chat_sounds": chatSounds,
                                    "high_priority_notf": highPriNot
                                ]
                            ]
                            break
                        }
                    }
                    
                    // Güncellenmiş 'usersCollection' listesini yaz
                    strongSelf.database.child("users").setValue(usersCollection) { error, _ in
                        guard error == nil else {
                            print("failed to write updated 'usersCollection' to database")
                            completion(false)
                            return
                        }
                                       
                        print("successfully updated 'usersCollection'")
                            completion(true)
                    }
                } else {
                    print("failed to get 'usersCollection' from database")
                    completion(false)
                }
            }
        }
        
        

    }
    
    public func insertUser(with user: ChatAppUser, completion: @escaping (Bool) -> Void) {
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName,
            "isOnline": user.isOnline,
            "lastOnline": user.lastOnline,
            "country_code": user.countryCode,
            "phone_number": user.phoneNumber,
            "user_password": user.password,
            "user_settings": [
                "read_receipt": readInfo,
                "last_seen": lastSeen,
                "profile_visibility": profilePhoto,
                "online_information": onlineInfo,
                "chat_sounds": chatSounds,
                "high_priority_notf": highPriNotf
            ]
        ]) { [weak self] error, _ in
            
            guard let strongSelf = self else {
                return
            }
            
            guard error == nil else {
                print("failed at write to database")
                completion(false)
                return
            }
            
            strongSelf.database.child("users").observeSingleEvent(of: .value) { (snapshot, error) in
                
                if let error = error {
                    print("observeSingleEvent error: \(error)")
                    completion(false)
                    return
                }
                
                if var usersCollection = snapshot.value as? [[String: Any]] {
                    //append to use dictionary
                    let newElement: [[String: Any]] = [
                        [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.safeEmail,
                            "isOnline": user.isOnline,
                            "lastOnline": user.lastOnline,
                            "country_code": user.countryCode,
                            "phone_number": user.phoneNumber,
                            "user_password": user.password,
                            "user_settings": [
                                "read_receipt": self?.readInfo,
                                "last_seen": self?.lastSeen,
                                "profile_visibility": self?.profilePhoto,
                                "online_information": self?.onlineInfo,
                                "chat_sounds": self?.chatSounds,
                                "high_priority_notf": self?.highPriNotf
                            ]
                        ]
                    ]
                    usersCollection.append(contentsOf: newElement)
                    
                    strongSelf.database.child("users").setValue(usersCollection) { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        completion(true)
                    }
                    
                } else {
                    let newsCollection: [[String: Any]] = [
                        [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.safeEmail,
                            "isOnline": user.isOnline,
                            "lastOnline": user.lastOnline,
                            "country_code": user.countryCode,
                            "phone_number": user.phoneNumber,
                            "user_password": user.password,
                            "user_settings": [
                                "read_receipt": self?.readInfo,
                                "last_seen": self?.lastSeen,
                                "profile_visibility": self?.profilePhoto,
                                "online_information": self?.onlineInfo,
                                "chat_sounds": self?.chatSounds,
                                "high_priority_notf": self?.highPriNotf
                            ]
                        ]
                    ]
                    
                    strongSelf.database.child("users").setValue(newsCollection) { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        completion(true)
                    }
                }
            }
            
        }
    }
    
    /// Get user settings
    public func fetchUserSettings(safeEmail: String, isCurrentUser: Bool, completion: @escaping () -> Void) {
        let safeEmail = DatabaseManager.safeEmail(emaildAddress: safeEmail)
        let usersRef = Database.database().reference().child("users")

        usersRef.observeSingleEvent(of: .value) { snapshot, error in
            guard error == nil, let usersDataArray = snapshot.value as? [[String: Any]] else {
                print("Error fetching user data or user data not found in snapshot")
                return
            }

            for userDataDict in usersDataArray {
                guard let email = userDataDict["email"] as? String, email == safeEmail,
                      let userSettings = userDataDict["user_settings"] as? [String: Any] else {
                    continue
                }
                
                let settings: [UserSetting] = [.lastSeenInfo, .onlineInfo,
                                               .profilePhoto, .readReceipt,
                                               .chatSounds, .highPrioNotification]
                
                let status: UserStatus = isCurrentUser ? .current : .other
                
                for setting in settings {
                    setUserSetting(status: status, setting: setting, value: userSettings[setting.rawValue] as? Bool ?? false)
                }
                
                completion()
                return
            }
        }
    }

    
    /// Gets all users from database
    public func getAllUsers(completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value) { snapshot in
            
            guard let value = snapshot.value as? [[String: Any]] else  {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            completion(.success(value))
        }
    }
    
    public func getAllFriends(completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emaildAddress: currentUserEmail)
        
        database.child("users").observeSingleEvent(of: .value) { snapshot in
            
            
            guard let value = snapshot.value as? [[String: Any]] else  {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            guard let userId = self.findUserId(for: safeEmail, in: value) else {
                print("user ıd not found")
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            let userFriendsRef = self.database.child("users").child(userId).child("friends")
            
            userFriendsRef.observeSingleEvent(of: .value) { friendSnapshot in
                guard let friendValues = friendSnapshot.value as? [[String: Any]] else {
                    return
                }
                
                completion(.success(friendValues))
            }

        }
    }
    
    public func getIncomingRequests(type: FriendRequestType, completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emaildAddress: currentUserEmail)
        let users = database.child("users")
        let safeCurrentEmail = DatabaseManager.safeEmail(emaildAddress: currentUserEmail)
        users.observeSingleEvent(of: .value) { snapshot in
            guard let usersValue = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            guard let userId = self.findUserId(for: safeCurrentEmail, in: usersValue) else {
                print("user ıd not found")
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            let userRef = users.child(userId)
            
            var requestsRef: DatabaseReference
            
            switch type {
            case .sendedRequests:
                requestsRef = userRef.child("sended_requests")
            case .incomingRequests:
                requestsRef = userRef.child("incoming_requests")
            }
            
            requestsRef.observeSingleEvent(of: .value) { requestSnapshot in
                guard let requestsData = requestSnapshot.value as? [[String: Any]] else {
                    return
                }
                completion(.success(requestsData))
            }
        }
    }
    
    public func getAllUnfollowedUsers(completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value) { snapshot in
            
            guard let value = snapshot.value as? [[String: Any]] else  {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            // buradan gelen value yu filtrelicez
            // current user ı bul
            // sended requestine git
            // içinde bulunan e-maillerri value dan ayır/çıkar
            // value yı geri dön
            completion(.success(value))
        }
    }
    
    public func deleteRequest(for currentUserEmail: String, targetUserEmail: String, completion: @escaping (Bool) -> Void) {
        
        let safeCurrentEmail = DatabaseManager.safeEmail(emaildAddress: currentUserEmail)
        let safeTargetEmail = DatabaseManager.safeEmail(emaildAddress: targetUserEmail)
        let usersRef = database.child("users")
        
        usersRef.observeSingleEvent(of: .value) { [self] snapshot in
            
            guard let usersValue = snapshot.value as? [[String: Any]] else {
                print("Unexpected data format in 'users' collection")
                completion(false)
                return
            }
            
            let currentUserId = self.findUserId(for: safeCurrentEmail, in: usersValue)
            let targetUserId = self.findUserId(for: targetUserEmail, in: usersValue)
            
            guard let currentId = currentUserId, let targetId = targetUserId else {
                completion(false)
                return
            }
            let currentIncomingRef = usersRef.child(currentId).child("incoming_requests")
            let targetSendedRef = usersRef.child(targetId).child("sended_requests")
            
            removeFriendRequest(currentIncomingRef, email: safeTargetEmail) { success in
                completion(success)
            }
            
            removeFriendRequest(targetSendedRef, email: safeCurrentEmail) { success in
                completion(success)
            }
        }
       
    }
    
     func removeFriendRequest(_ userRef: DatabaseReference, email: String, completion: @escaping (Bool) -> Void) {
        userRef.observeSingleEvent(of: .value) { snapshot in
            guard var requestData = snapshot.value as? [[String: Any]] else {
                completion(false)
                return
            }
            
            if let index = requestData.firstIndex(where: { $0["email"] as? String == email }) {
                requestData.remove(at: index)
                
                userRef.setValue(requestData) { error, _ in
                    if let error = error {
                        print("Error updating requests: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        print("Request removed successfully")
                        completion(true)
                    }
                }
            } else {
                completion(false)
            }
        }
    }
    
    func addFriend(_ userRef: DatabaseReference, email: String, name: String, completion: @escaping (Bool) -> Void) {
        userRef.observeSingleEvent(of: .value) { snapshot in
            var requestsArray = snapshot.value as? [[String: Any]] ?? []
            
            guard !requestsArray.contains(where: {$0["email"] as? String == email}) else {
                print("Friendship request already sent")
                completion(false)
                return
            }
            
            let friendData: [String: Any] = [
                "email": email,
                "name": name
            ]
            
            requestsArray.append(friendData)
            
            userRef.setValue(requestsArray) { error, _ in
                if let error = error {
                    print("Error sending friendship request: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("Friendship request sent successfully")
                    completion(true)
                }
            }
        }
    }
    
    
    public func saveToMyFriends(forUserEmail currentUserEmail: String, currentUsername: String, targetUserEmail: String, targetUsername: String, completion: @escaping (Bool) -> Void) {
        
        let safeCurrentEmail = DatabaseManager.safeEmail(emaildAddress: currentUserEmail)
        let usersRef = database.child("users")
        
        usersRef.observeSingleEvent(of: .value) { snapshot in
            
            guard let usersValue = snapshot.value as? [[String: Any]] else {
                print("Unexpected data format in 'users' collection")
                completion(false)
                return
            }
            
            let currentUserId = self.findUserId(for: safeCurrentEmail, in: usersValue)
            let targetUserId = self.findUserId(for: targetUserEmail, in: usersValue)
            
            guard let currentId = currentUserId, let targetId = targetUserId else {
                completion(false)
                return
            }
            
            let currentFriendsRef = usersRef.child(currentId).child("friends")
            let targetFriendsRef = usersRef.child(targetId).child("friends")
            let currentIncomingRef = usersRef.child(currentId).child("incoming_requests")
            let targetSendedRef = usersRef.child(targetId).child("sended_requests")
            
            self.addFriend(currentFriendsRef, email: targetUserEmail, name: targetUsername) { success in
                guard success else {
                    completion(false)
                    return
                }
                
                self.addFriend(targetFriendsRef, email: currentUserEmail, name: currentUsername) { success in
                    guard success else {
                        completion(false)
                        return
                    }
                    
                    self.removeFriendRequest(targetSendedRef, email: currentUserEmail) { success in
                        guard success else {
                            completion(false)
                            return
                        }
                        
                        self.removeFriendRequest(currentIncomingRef, email: targetUserEmail) { success in
                            completion(success)
                        }
                    }
                }
            }
        }
        
    }

    public func fetchMyFriends(completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let safeCurrEmail = DatabaseManager.safeEmail(emaildAddress: currentUserEmail)
        
        let usersRef = database.child("users")
        
        usersRef.observeSingleEvent(of: .value) { snapshot in
            
            guard let usersData = snapshot.value as? [[String: Any]] else {
                return
            }
            
            guard let findUserId = self.findUserId(for: safeCurrEmail, in: usersData) else {
                return
            }
            
            let currUserFriendsRef = usersRef.child(findUserId).child("friends")
            
            currUserFriendsRef.observeSingleEvent(of: .value) { friendSnapshot in
                guard let userFriendsData = friendSnapshot.value as? [[String: Any]] else {
                    return
                }
                
                completion(.success(userFriendsData))
            }
        }
        
    }
    
    public func fetchUserInformation(otherUserEmail: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        
        let usersRef = database.child("users")
        
        usersRef.observeSingleEvent(of: .value) { snapshot in
            
            guard let userData = snapshot.value as? [[String: Any]] else {
                return
            }
            
            guard let findUserId = self.findUserId(for: otherUserEmail, in: userData) else {
                return
            }
            
            let desiredUser = usersRef.child(findUserId)
            
            desiredUser.observeSingleEvent(of: .value) { desiredSnapshot in
                
                guard let desiredUserData = desiredSnapshot.value as? [String: Any] else {
                    return
                }
                
                completion(.success(desiredUserData))
            }
        }
    }
    
    
    public func sendFriendsRequest(currentUserEmail: String,
                                   currentUserName: String,
                                   targetUserEmail: String,
                                   completion: @escaping (Bool, Bool) -> Void) {
        
        let usersRef = database.child("users")

        usersRef.observeSingleEvent(of: .value) { snapshot in
            guard let usersValue = snapshot.value as? [[String: Any]] else {
                print("Unexpected data format in 'users' collection")
                completion(false, false)
                return
            }
            
            var targetUserID: String?
            var senderUserID: String?
            
            
            var targetUserName: String?
            for (index, userData) in usersValue.enumerated() {
                if let email = userData["email"] as? String,
                   let name = userData["name"] as? String,
                   email == targetUserEmail {
                    targetUserID = String(index)
                    targetUserName = name
                    break
                }
            }
            
            guard let foundUser = targetUserID else {
                return
            }
            
            
            let targetUserRef = usersRef.child(foundUser)
            
            
            let requestRef = targetUserRef.child("incoming_requests")
            
            requestRef.observeSingleEvent(of: .value) { requestSnapshot in
                
                var requestsArray = requestSnapshot.value as? [[String: Any]] ?? []
                
                guard !requestsArray.contains(where: {$0["email"] as? String == currentUserEmail}) else {
                    print("friendship request already sent")
                    completion(false, true)
                    return
                }
                
                let requesterData: [String: Any] = [
                    "email": currentUserEmail,
                    "name": currentUserName,
                ]
                
                requestsArray.append(requesterData)
                
                requestRef.setValue(requestsArray) { error, _ in
                    if let error = error {
                        print("Error sending friendship request: \(error.localizedDescription)")
                        completion(false, false)
                    } else {
                        
                        print("Friendship request sent successfully")
                        completion(true, false)
                    }
                }
                
            }
            
            for (index, userData) in usersValue.enumerated() {
                if let email = userData["email"] as? String,
                   email == currentUserEmail {
                    senderUserID = String(index)
                    break
                }
            }
            
            guard let foundSenderUser = senderUserID else {
                return
            }
            
            let senderUserRef = usersRef.child(foundSenderUser)
            let sentRequestsRef = senderUserRef.child("sended_requests")
            
            sentRequestsRef.observeSingleEvent(of: .value) { sendedRequestSnapshot in
                
                var sendedRequests = sendedRequestSnapshot.value as? [[String: Any]] ?? []
                
                guard !sendedRequests.contains(where: {$0["email"] as? String == targetUserEmail}) else {
                    print("friendship request already sent")
                    
                    completion(false, true)
                    return
                }
                
                let requesterOtherData: [String: Any] = [
                    "email": targetUserEmail,
                    "name": targetUserName,
                ]
                
                sendedRequests.append(requesterOtherData)
                
                sentRequestsRef.setValue(sendedRequests) { error, _ in
                    if let error = error {
                        print("Error sending friendship request: \(error.localizedDescription)")
                        completion(false, false)
                    } else {
                        
                        print("Friendship request sent successfully")
                        completion(true, false)
                    }
                }
            }
            
        }
            
    }
    
    public func getFriendRequests(forUserEmail userEmail: String, type: FriendRequestType, completion: @escaping ((Result<[FriendRequest], Error>)?) -> Void) {
        let usersRef = database.child("users")
        
        let safeCurrentEmail = DatabaseManager.safeEmail(emaildAddress: userEmail)
        
        usersRef.observeSingleEvent(of: .value) { snapshot in
            guard let usersValue = snapshot.value as? [[String: Any]] else {
                print("Unexpected data format in 'users' collection")
                completion(nil)
                return
            }
            
            guard let userId = self.findUserId(for: safeCurrentEmail, in: usersValue) else {
                completion(nil)
                return
            }
            
            let userRef = usersRef.child(userId)
            var requestsRef: DatabaseReference
            
            switch type {
            case .sendedRequests:
                requestsRef = userRef.child("sended_requests")
            case .incomingRequests:
                requestsRef = userRef.child("incoming_requests")
            }
            
            requestsRef.observeSingleEvent(of: .value) { requestsSnapshot in
            
                guard let requestsArray = requestsSnapshot.value as? [[String: Any]] else {
                    completion(.success([]))
                    return
                }
                
                let friendRequest: [FriendRequest] = requestsArray.compactMap { requestDict in
                    guard let email = requestDict["email"] as? String,
                          let name = requestDict["name"] as? String else {
                        return nil
                    }
                    return FriendRequest(email: email, name: name)
                }
                completion(.success(friendRequest))
            }
    
        }
        
    }
    
    private func findUserId(for email: String, in users: [[String: Any]]) -> String? {
        for (index, userData) in users.enumerated() {
            if let userEmail = userData["email"] as? String,
               userEmail == email {
                return String(index)
            }
        }
        return nil
    }

    
    public enum DatabaseError: Error {
        case failedToFetch
        
        public var localizedDescription: String {
            switch self {
            case .failedToFetch:
                return "This means blah failed"
            }
        }
    }
    
   
}

struct FriendshipRequest {
    let requesterName: String
    let requesterEmail: String
}

/// MARK:   - Sending messages / conversations

extension DatabaseManager {
    
    /// Creates a new conversations with target user email and first message sent
    //Hedef kullanıcının e-postası ve gönderilen ilk mesajla yeni bir görüşme oluşturur
    public func createNewConversations(with otherUserEmail: String, name: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String,
        let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emaildAddress: currentEmail)
        let ref = database.child("\(safeEmail)")
        
        ref.observeSingleEvent(of: .value) { [weak self] snapshot, _  in
            guard var userNode = snapshot.value as? [String: Any] else {
                return
            }
            
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
            var message = ""
            
            switch firstMessage.kind {
            case .text(let messageText):
                    message = messageText
            case .attributedText(_):
                break
            case .photo(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString {
                    message = targetUrlString
                }
                break
            case .video(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString {
                    message = targetUrlString
                }
                break
            case .location(let locationData):
                let location = locationData.location
                message = "\(location.coordinate.longitude),\(location.coordinate.latitude)"
                break
            case .emoji(_):
                break
            case .audio(let audioItem):
                let audioFileURL = audioItem.url.absoluteString
                   message = audioFileURL
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            
            let conversationID = "conversation_\(firstMessage.messageId)"
            
            let newConversationsData: [String: Any] = [
                "id": conversationID,
                "isRoomBeginIn": false,
                "other_user_email": otherUserEmail,
                "name": name,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false,
                    "type": firstMessage.kind.messageKindString
                ]
            ]
            
            
            let recipient_newConversationsData: [String: Any] = [
                "id": conversationID,
                "isRoomBeginIn": false,
                "other_user_email": safeEmail,
                "name": currentName,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false,
                    "type": firstMessage.kind.messageKindString
                ]
            ]
            
            // Update recipient conversations entry
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { [weak self] snapshot in
                if var conversations = snapshot.value as? [[String: Any]] {
                    //append
                    conversations.append(recipient_newConversationsData)
                    self?.database.child("\(otherUserEmail)/conversations").setValue(conversations)
                } else {
                    // create conversations
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipient_newConversationsData])
                }
            }
            
            
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                // conversations array exists for current user
                // you should append
                conversations.append(newConversationsData)
                userNode["conversations"] = conversations
                
                ref.setValue(userNode, withCompletionBlock: { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreateingCOnversations(name: name, conversationID: conversationID,
                                                      firstMessage: firstMessage,
                                                      completion: completion)
                })
                
                //[weak self] kullanımı, kapanışın içinde self (yani mevcut sınıfın örneği) referansını yakalar,
                //ancak bu referans zayıf bir referanstır. Bu da demek oluyor ki,
                //eğer mevcut sınıfın örneği bellekten silinirse (deinit çağrıldığında),
                //bu referans otomatik olarak nil olur. Bu sayede döngüsel bağımlılıkların önüne geçilir ve bellek sızıntıları engellenmiş olur.
            }
            else {
                // conversation array does not exist
                // create it
                userNode["conversations"] = [
                    newConversationsData
                ]
                
                ref.setValue(userNode, withCompletionBlock: { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    
                    self?.finishCreateingCOnversations(name: name, conversationID: conversationID,
                                                      firstMessage: firstMessage,
                                                      completion: completion)
                })
            }
        }
    }
    
    private func finishCreateingCOnversations(name: String, conversationID: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
    
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        var message = ""
        
        switch firstMessage.kind {
        case .text(let messageText):
                message = messageText
        case .attributedText(_):
            break
        case .photo(let mediaItem):
            if let targetUrlString = mediaItem.url?.absoluteString {
                message = targetUrlString
            }
            break
        case .video(let mediaItem):
            if let targetUrlString = mediaItem.url?.absoluteString {
                message = targetUrlString
            }
            break
        case .location(let locationData):
            let location = locationData.location
            message = "\(location.coordinate.longitude),\(location.coordinate.latitude)"
            break
        case .emoji(_):
            break
        case .audio(let audioItem):
            let audioFileURL = audioItem.url.absoluteString
               message = audioFileURL
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let currentUserEmail = DatabaseManager.safeEmail(emaildAddress: myEmail)
        
        let collectionMessage: [String: Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "audioDuration": firstMessage.audioDur ?? 0.0,
            "name": name,
            "date": dateString,
            "sender_email": currentUserEmail,
            "is_read": false,
        ]
        
        let value: [String: Any] = [
            "messages": [
               collectionMessage
            ]
        ]
        
        database.child("\(conversationID)").setValue(value) { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            
            completion(true)
        }
    }
    
    /// Fetches and returns all conversations for the user with passed in email
    //Kullanıcının e-postayla iletilen tüm konuşmalarını getirir ve döndürür
    //Result türünde bir değer olarak iletmek için Result<String, Error> kullanır.
    //Başarılı bir sonuçta bir dize (String) veya bir hata (Error) döndürülür.
    
    public func getAllConversationsFromCache(for email: String) -> [Conversation]? {
        let cacheKey = "\(email)/conversationsCache"
        if let cachedData = UserDefaults.standard.data(forKey: cacheKey) {
            do {
                let conversations = try? JSONDecoder().decode([Conversation].self,
                                                       from: cachedData)
                return conversations
            } catch {
                print("Error decoding conversations from cache \(error)")
                return nil
            }
        }
        return nil
    }
    
    public func saveConversationsToCache(_ conversations: [Conversation], for email: String) {
        let cacheKey = "\(email)/conversationsCache"
        do {
            let encodedData = try? JSONEncoder().encode(conversations)
            UserDefaults.standard.set(encodedData, forKey: cacheKey)
        } catch {
            print("Error encoding conversations data for cache \(error)")
        }
    }
    
    public func getAllConversations(for email: String, completion: @escaping (Result<[Conversation], Error>) -> Void) {
        let path = "\(email)/conversations"
        database.child(path).observe(.value) { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                print("error")
                
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            let conversations: [Conversation] = value.compactMap { dictionary in
                guard let conversationId = dictionary["id"] as? String,
                      let name = dictionary["name"] as? String,
                      let isRoomBeginIn = dictionary["isRoomBeginIn"] as? Bool,
                      let otherUserEmail = dictionary["other_user_email"] as? String,
                      let latestMessage = dictionary["latest_message"] as? [String: Any],
                      let date = latestMessage["date"] as? String,
                      let message = latestMessage["message"] as? String,
                      let isRead = latestMessage["is_read"] as? Bool,
                      let type = latestMessage["type"] as? String
                       else {
                    return nil
                }
                
                let latestMessageObject = LatestMessage(date: date, isRead: isRead, text: message, type: LatestMessageTpyes(rawValue: type) ?? .text)
                
                return Conversation(id: conversationId, name: name, otherUserEmail: otherUserEmail, isRoomBeginIn: isRoomBeginIn, latestMessage: latestMessageObject)
            }
            
            //self.saveConversationsToCache(conversations, for: email)
            
            completion(.success(conversations))
        }
    }
    
    func videoPreviewImage(url: URL) -> UIImage? {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        if let cgImage = try? generator.copyCGImage(at: CMTime(seconds: 2, preferredTimescale: 60), actualTime: nil) {
            return UIImage(cgImage: cgImage)
        }
        else {
            return nil
        }
    }
    /// Gets all messages for given conversations
    // Verilen konuşmalara ilişkin tüm mesajları alır
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        database.child("\(id)/messages").observe(.value) { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            let messages: [Message] = value.compactMap { dictionary in
                guard let name = dictionary["name"] as? String,
                      let content = dictionary["content"] as? String,
                      let date = dictionary["date"] as? String,
                      let dateString = ChatViewController.dateFormatter.date(from: date),
                      let messageId = dictionary["id"] as? String,
                      let isRead = dictionary["is_read"] as? Bool,
                      let audioDuration = dictionary["audioDuration"] as? Float,
                      let senderEmail = dictionary["sender_email"] as? String,
                      let type = dictionary["type"] as? String else {
                    return nil
                }
                
                var kind: MessageKind?
                
                if type == "photo" {
                    guard let url = URL(string: content),
                          let placeholder = UIImage(systemName: "plus") else {
                        return nil 
                    }
                    let media = Media(url: url, image: nil, placeholderImage: placeholder, size: CGSize(width: 250, height: 250))
                    
                    kind = .photo(media)
                }
                else if type == "video" {
                    guard let videoUrl = URL(string: content),
                          let placeholder = self.videoPreviewImage(url: videoUrl) else {
                        return nil
                    }
                    
                   
                    let media = Media(url: videoUrl,
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size: CGSize(width: 250, height: 250))
                    
                    kind = .video(media)
                }
                else if type == "location" {
                    let locationComponents = content.components(separatedBy: ",")
                    guard let longitude = Double(locationComponents[0]),
                          let latitude = Double(locationComponents[1]) else {
                        return nil
                    }
                    
                    let location = Location(location: CLLocation(latitude: latitude, longitude: longitude), size: CGSize(width: 250, height: 250))
                    
                    kind = .location(location)
                } else if type == "audio" {
                    
                    guard let audioUrl = URL(string: content) else { return nil }
                    let duration = audioDuration
                    
                    // Sesin süresine göre width değerini hesapla (örneğin, her saniye için belirli bir genişlik)
                    let widthPerSecond: CGFloat = 20.0 // Örnek olarak, her saniye için 50 birim genişlik
                   
                    var calculatedWidth = CGFloat(duration) * widthPerSecond
                   // print("audio dur. :", ChatViewController.audioD)
                    if duration >= 10 {
                        calculatedWidth = 300
                    } else if duration <= 5 {
                        calculatedWidth = 125
                    }
                    let audio = Audio(url: audioUrl, duration: audioDuration, size: CGSize(width: calculatedWidth, height: 35))
                    
                    kind = .audio(audio)
                }
                else {
                    kind = .text(content)
                }
                
                guard let finalKind = kind else {
                    return nil
                }
                
                let sender = Sender(photoURL: "", displayName: name, senderId: senderEmail)
                                
                return Message(sender: sender, messageId: messageId, sentDate: dateString, kind: finalKind, isRead: isRead)
            }
            
            completion(.success(messages))
        }
    }
    
    /// Sends a message with targer conversation and message
    // Hedef konuşmayı ve mesajı içeren bir mesaj gönderir.
    // completion: İşlem tamamlandığında çağrılacak bir kapanış işlevini alır ve
    // işlemin başarılı olup olmadığını bildirmek için bir Bool değeri alır.
    public func sendMessage(to conversation: String, otherUserEmail: String, name: String, newMessage: Message, completion: @escaping (Bool) -> Void) {
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        var isReadDatabaseValue: Bool = false
        var isCurrentUserRoom: Bool = false
        var isOtherUserRoom: Bool = false
        
        let currentEmail = DatabaseManager.safeEmail(emaildAddress: myEmail)
        let safeOtherEmail = DatabaseManager.safeEmail(emaildAddress: otherUserEmail)
       
        
        let otherUserIsRoom = database.child("\(safeOtherEmail)").child("conversations").child("0").child("isRoomBeginIn")
        let currentUserIsRoom = database.child("\(currentEmail)").child("conversations").child("0").child("isRoomBeginIn")
        
        let dispatchGroup = DispatchGroup()

        // currentUserIsRoom değerini al
        // bu işlemleri bitirmeden veri tabanına data'yı işleyen kod çalışmayacaktır
        // önceki yapıda çalıştığı için is_read değişkenini doğru bir şekilde işleyemiyorduk
        // bu yapı ile doğru forma getirildi
        dispatchGroup.enter()
        currentUserIsRoom.observeSingleEvent(of: .value) { (snapshot) in
            guard let currentuserRoomValue = snapshot.value as? Bool else {
                return
            }
            
            isCurrentUserRoom = currentuserRoomValue
            dispatchGroup.leave() // DispatchGroup'tan çık
        }

        // otherUserIsRoom değerini al
        dispatchGroup.enter()
        otherUserIsRoom.observeSingleEvent(of: .value) { (snapshot) in
            guard let otherUserRoomValue = snapshot.value as? Bool else {
                return
            }
            
            isOtherUserRoom = otherUserRoomValue
            
            if isOtherUserRoom {
                isReadDatabaseValue = true
            } else {
                isReadDatabaseValue = false
            }
            
            dispatchGroup.leave() // DispatchGroup'tan çık
        }

        // Her iki değer de alındığında devam et
        dispatchGroup.notify(queue: .main) {
            // Veriler alındıktan sonra geri kalan kodu burada çalıştır
            // add new message to messages array
            self.database.child("\(conversation)/messages").observeSingleEvent(of: .value) { [weak self] snapshot in
                guard let strongSelf = self else { return }
                guard var currentMessages = snapshot.value as? [[String: Any]] else {
                    completion(false)
                    return
                }
                
                //add new message
                let messageDate = newMessage.sentDate
                let audioDur = newMessage.audioDur
                print("auido dur: ",audioDur)
                let dateString = ChatViewController.dateFormatter.string(from: messageDate)
                var message = ""
                
                switch newMessage.kind {
                case .text(let messageText):
                        message = messageText
                case .attributedText(_):
                    break
                case .photo(let mediaItem):
                    if let targetUrlString = mediaItem.url?.absoluteString {
                        message = targetUrlString
                    }
                    break
                case .video(let mediaItem):
                    if let targetUrlString = mediaItem.url?.absoluteString {
                        message = targetUrlString
                    }
                    break
                case .location(let locationData):
                    let location = locationData.location
                    message = "\(location.coordinate.longitude),\(location.coordinate.latitude)"
                    break
                case .emoji(_):
                    break
                case .audio(let audioItem):
                    let audioFileURL = audioItem.url.absoluteString
                       message = audioFileURL
                    break
                case .contact(_):
                    break
                case .linkPreview(_):
                    break
                case .custom(_):
                    break
                }
                
                guard let myEmmail = UserDefaults.standard.value(forKey: "email") as? String else {
                    completion(false)
                    return
                }
                
                let currentUserEmail = DatabaseManager.safeEmail(emaildAddress: myEmmail)
                print(isReadDatabaseValue)
                let newMessageEntry: [String: Any] = [
                    "id": newMessage.messageId,
                    "type": newMessage.kind.messageKindString,
                    "content": message,
                    "name": name,
                    "date": dateString,
                    "audioDuration": newMessage.audioDur ?? 0.0,
                    "sender_email": currentUserEmail,
                    "is_read": isReadDatabaseValue,
                ]
                
                // update sender latest message
                currentMessages.append(newMessageEntry)
                print(isReadDatabaseValue)
                strongSelf.database.child("\(conversation)/messages").setValue(currentMessages) { error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    
                    strongSelf.database.child("\(currentEmail)/conversations").observeSingleEvent(of: .value) { snapshot in
                        print(isReadDatabaseValue)
                        var databaseEntryConversations = [[String: Any]]()
                        
                        let updatedValue: [String: Any] = [
                            "date": dateString,
                            "is_read": isReadDatabaseValue,
                            "message": message,
                            "type": newMessage.kind.messageKindString
                        ]
                        
                        if var currentUserConversations = snapshot.value as? [[String: Any]] {
                            
                            var targetConversation: [String: Any]?
                            var position = 0
                            
                            for conversationDictionary in currentUserConversations {
                                if let currentId = conversationDictionary["id"] as? String, currentId == conversation {
                                    targetConversation = conversationDictionary
                                    break
                                }
                                position += 1
                            }
                            
                            if var targetConversation = targetConversation {
                                targetConversation["latest_message"] = updatedValue
                              
                                currentUserConversations[position] = targetConversation
                                databaseEntryConversations = currentUserConversations
                            } else {
                                let newConversationsData: [String: Any] = [
                                    "id": conversation,
                                    "isRoomBeginIn": isOtherUserRoom,
                                    "other_user_email": DatabaseManager.safeEmail(emaildAddress: otherUserEmail),
                                    "name": name,
                                    "latest_message": updatedValue
                                ]
                                currentUserConversations.append(newConversationsData)
                                databaseEntryConversations = currentUserConversations
                            }
                            
                        } else {
                            let newConversationsData: [String: Any] = [
                                "id": conversation,
                                "isRoomBeginIn": isOtherUserRoom,
                                "other_user_email": DatabaseManager.safeEmail(emaildAddress: otherUserEmail),
                                "name": name,
                                "latest_message": updatedValue
                            ]
                            
                            databaseEntryConversations =
                            [
                               newConversationsData
                            ]
                        }
                        
                       
                        strongSelf.database.child("\(currentEmail)/conversations").setValue(databaseEntryConversations) { error, _ in
                            guard error == nil else {
                                completion(false)
                                return
                            }
                            
                            //update latest message for recepient user
                            strongSelf.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { snapshot in
                                
                                var databaseEntryConversations = [[String: Any]]()
                                
                                let updatedValue: [String: Any] = [
                                    "date": dateString,
                                    "is_read": isReadDatabaseValue,
                                    "message": message,
                                    "type": newMessage.kind.messageKindString
                                ]
                                
                                guard let currentName = UserDefaults.standard.value(forKey: "name") else {
                                    return
                                }
                                
                                if var otherUserConversations = snapshot.value as? [[String: Any]] {
                                    var targetConversation: [String: Any]?
                                    var position = 0
                                    
                                    for conversationDictionary in otherUserConversations {
                                        if let currentId = conversationDictionary["id"] as? String, currentId == conversation {
                                            targetConversation = conversationDictionary
                                            break
                                        }
                                        position += 1
                                    }
                                    
                                    if var targetConversation = targetConversation {
                                        targetConversation["latest_message"] = updatedValue
                                       
                                        otherUserConversations[position] = targetConversation
                                        databaseEntryConversations = otherUserConversations
                                    } else {
                                        let newConversationsData: [String: Any] = [
                                            "id": conversation,
                                            "isRoomBeginIn": isCurrentUserRoom,
                                            "other_user_email": DatabaseManager.safeEmail(emaildAddress: currentEmail),
                                            "name": currentName,
                                            "latest_message": updatedValue
                                        ]
                                        otherUserConversations.append(newConversationsData)
                                        databaseEntryConversations = otherUserConversations
                                    }
                                    
                                } else {
                                    let newConversationsData: [String: Any] = [
                                        "id": conversation,
                                        "isRoomBeginIn": isCurrentUserRoom,
                                        "other_user_email": DatabaseManager.safeEmail(emaildAddress: currentEmail),
                                        "name": currentName,
                                        "latest_message": updatedValue
                                    ]
                                    
                                    databaseEntryConversations =
                                    [
                                       newConversationsData
                                    ]
                                }
                                
                               
                                strongSelf.database.child("\(otherUserEmail)/conversations").setValue(databaseEntryConversations) { error, _ in
                                    guard error == nil else {
                                        completion(false)
                                        return
                                    }
                                    
                                    completion(true)
                                }
                            }
                            
                            completion(true)
                        }
                    }
                    
                }
                // update recepient latest message

            }
        }

    }
    
    public func conversationExists(iwth targetRecipientEmail: String, completion: @escaping (Result<String, Error>) -> Void) {
        
        let safeRecipientEmail = DatabaseManager.safeEmail(emaildAddress: targetRecipientEmail)
        guard let senderEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        
        let safeSenderEmail = DatabaseManager.safeEmail(emaildAddress: senderEmail)
        
        database.child("\(safeRecipientEmail)/conversations").observeSingleEvent(of: .value) { snapshot in
            guard let collection = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            // iterate and find conversation with target sender
            if let conversation = collection.first(where: {
                guard let targetSenderEmail = $0["other_user_email"] as? String else {
                    return false
                }
                
               return safeSenderEmail == targetSenderEmail
            }) {
                // get id
                guard let id = conversation["id"] as? String else {
                    completion(.failure(DatabaseError.failedToFetch))
                    return
                }
                completion(.success(id))
                return
            }
            completion(.failure(DatabaseError.failedToFetch))
            return
        }
    }
    
    public func deleteConversation(conversationId: String, completion: @escaping (Bool) -> Void) {
        
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emaildAddress: email)
        
        print("deleting conv with id: \(conversationId)")
        
        // Get all convers. for current user
        // delete conversat in collection with target id
        // reset those convers for the user in database
        
        //kullanıcının covnersation koleksiyonuna erişim
        let ref = database.child("\(safeEmail)/conversations")
        
        ref.observeSingleEvent(of: .value) { snapshot in
            
            //conversation koleksiyonundaki değerleri aldık
            if var conversations = snapshot.value as? [[String: Any]] {
                /* mesaage [
                   0,
                   1,
                   2,
                   3
                ]
                 , şekline sıralanıyor mesajlar bundan dolayı silinecek mesajın numarası diye bir değişken tuttuk ve bunu sıfırdan başlattık
                 */
                var positionToRemove = 0
                for conversation in conversations {
                    // mesajların olduğu diziyi dolaştık tek tek ve
                    // her mesajın id sini alarak işleme devam ettik
                    if let id = conversation["id"] as? String,
                       id == conversationId {
                        // mesajı bulunca break diyerek bu döngüden çıkar
                        print("found convers. to delete")
                        break
                        // 0. indeks silindi tekrar kontrole girince bulamaz ve
                        // bir sonraki komut olan positionToRemove += 1 komutu ile
                        // indeksi arttırır bir sonraki mesajın varlığına bakar
                    }
                    positionToRemove += 1
                }
                
                // ve buraya gelir burada da 0. indeksi siler
                // true döndürür
                conversations.remove(at: positionToRemove)
                ref.setValue(conversations) { error, _ in
                    guard error == nil else {
                        completion(false)
                        print("Failed to write new conv array")
                        return
                    }
                    print("deleted conv")
                    completion(true)
                }
            }
        }
    }
    
    public func updateConversationStatus(otherUserEmail: String) {
        
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {return}
        
        let safeCurrEmail = DatabaseManager.safeEmail(emaildAddress: currentEmail)
        let safeOtherUserEmail = DatabaseManager.safeEmail(emaildAddress: otherUserEmail)
        
        let isRoomBeginRef = database.child("\(safeCurrEmail)").child("conversations").child("0").child("isRoomBeginIn")
        isRoomBeginRef.setValue(true)
        
        isRoomBeginRef.observeSingleEvent(of: .value) { (snapshot) in
            guard let isRoomBeginValue = snapshot.value as? Bool else { return }
            
            let latestMesReadRef = self.database.child(safeOtherUserEmail).child("conversations").child("0").child("latest_message").child("is_read")
            let currentUserUpdate = self.database.child(safeCurrEmail).child("conversations").child("0").child("latest_message").child("is_read")
            
            if isRoomBeginValue {
                latestMesReadRef.setValue(true)
                currentUserUpdate.setValue(true)
                
            } else {
                print("\(safeOtherUserEmail) kullanıcısı oda da değil mesjaınızı göremez")
            }
        }
    }
    
}

struct ChatAppUser {
    let firstName: String
    let lastName: String
    let countryCode: Int
    let phoneNumber: Int
    let password: String
    let emailAddress: String
    var isOnline: Bool?
    var lastOnline: String?
    var friends: [MyFriends]
    var requests: [MyFriendshipRequests]
    
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

struct MyFriends {
    let otherUserEmail: String
    var safeEmail: String {
        var safeEmail = otherUserEmail.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
}

struct MyFriendshipRequests {
    let userEmailAddress: String
    var safeEmail: String {
        var safeEmail = userEmailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
}
