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

    static func safeEmail(emaildAddress: String) -> String {
        var safeEmail = emaildAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
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
            
            self.database.child("users").observeSingleEvent(of: .value) { snapshot in
                if var usersCollection = snapshot.value as? [[String: String]] {
                    //append to use dictionary
                    let newElement: [[String: String]] = [
                        [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.safeEmail
                        ]
                    ]
                    usersCollection.append(contentsOf: newElement)
                    
                    self.database.child("users").setValue(usersCollection) { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        completion(true)
                    }
                    
                } else {
                    let newsCollection: [[String: String]] = [
                        [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.safeEmail
                        ]
                    ]
                    
                    self.database.child("users").setValue(newsCollection) { error, _ in
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
    
    public func getAllUsers(completion: @escaping (Result<[[String: String]], Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value) { snapshot in
            
            guard let value = snapshot.value as? [[String: String]] else  {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            completion(.success(value))
        }
    }
    
    public enum DatabaseError: Error {
        case failedToFetch
    }
    
    /*
     users =>
     
     [
        [
            "name":
            "safe_email":
        ],
        [
            "name":
            "safe_email:":
        ]
     ]
     
     "cnfchdfhfdbdf" {
          "messages": [
              {
                  "id": String,
                  "type": text,photo,video,
                  "content": String,
                  "date": Date(),
                  "sender_email": String,
                  "is_read": true/false,
              }
          ]
     }
     
     conversation => [
           [
               "conversation_id": "cnfchdfhfdbdf"
               "other_user_email":
               "latest_message": => {
                    "date": Date()
                    "latest_message": "message"
                    "is_read": true/false
                }
     
           ]
     ]
     
     
     */
}

/// MARK:   - Sending messages / conversations

extension DatabaseManager {
    
    /// Creates a new conversations with target user email and first message sent
    //Hedef kullanıcının e-postası ve gönderilen ilk mesajla yeni bir görüşme oluşturur
    public func createNewConversations(with otherUserEmail: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emaildAddress: currentEmail)
        let ref = database.child("\(safeEmail)")
        
        ref.observeSingleEvent(of: .value) { snapshot in
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
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
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
                "other_user_email": otherUserEmail,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
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
                    self?.finishCreateingCOnversations(conversationID: conversationID,
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
                    
                    self?.finishCreateingCOnversations(conversationID: conversationID,
                                                      firstMessage: firstMessage,
                                                      completion: completion)
                })
            }
        }
    }
    
    private func finishCreateingCOnversations(conversationID: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        
      /*  "cnfchdfhfdbdf" {
             "messages": [
                 {
                     "id": String,
                     "type": text,photo,video,
                     "content": String,
                     "date": Date(),
                     "sender_email": String,
                     "is_read": true/false,
                 }
             ]
        }*/
        
        var message = ""
        
        switch firstMessage.kind {
        case .text(let messageText):
                message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let currentUserEmail = DatabaseManager.safeEmail(emaildAddress: myEmail)
        
        let collectionMessage: [String: Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": message,
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
    public func getAllConversations(for email: String, completion: @escaping (Result<String, Error>) -> Void) {
        
    }
    
    /// Gets all messages for given conversations
    // Verilen konuşmalara ilişkin tüm mesajları alır
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<String, Error>) -> Void) {
        
    }
    
    /// Sends a message with targer conversation and message
    // Hedef konuşmayı ve mesajı içeren bir mesaj gönderir.
    // completion: İşlem tamamlandığında çağrılacak bir kapanış işlevini alır ve
    // işlemin başarılı olup olmadığını bildirmek için bir Bool değeri alır.
    public func sendMessage(to conversation: String, message: Message, completion: @escaping (Bool) -> Void) {
        
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
