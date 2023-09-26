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
                "name": name,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            let recipient_newConversationsData: [String: Any] = [
                "id": conversationID,
                "other_user_email": safeEmail,
                "name": currentName,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            // Update recipient conversations entry
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { [weak self] snapshot in
                if var conversations = snapshot.value as? [[String: Any]] {
                    //append
                    conversations.append(recipient_newConversationsData)
                    self?.database.child("\(otherUserEmail)/conversations").setValue(conversationID)
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
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let currentUserEmail = DatabaseManager.safeEmail(emaildAddress: myEmail)
        
        let collectionMessage: [String: Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": message,
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
    public func getAllConversations(for email: String, completion: @escaping (Result<[Conversation], Error>) -> Void) {
        database.child("\(email)/conversations").observe(.value) { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                print("error")
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            let conversations: [Conversation] = value.compactMap { dictionary in
                guard let conversationId = dictionary["id"] as? String,
                      let name = dictionary["name"] as? String,
                      let otherUserEmail = dictionary["other_user_email"] as? String,
                      let latestMessage = dictionary["latest_message"] as? [String: Any],
                      let date = latestMessage["date"] as? String,
                      let message = latestMessage["message"] as? String,
                      let isRead = latestMessage["is_read"] as? Bool
                       else {
                    return nil
                }
                
                let latestMessageObject = LatestMessage(date: date, isRead: isRead, text: message)
                
                return Conversation(id: conversationId, name: name, otherUserEmail: otherUserEmail, latestMessage: latestMessageObject)
            }
            
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
                    let media = Media(url: url, image: nil, placeholderImage: placeholder, size: CGSize(width: 300, height: 300))
                    
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
                                      size: CGSize(width: 200, height: 200))
                    
                    kind = .video(media)
                }
                else {
                    kind = .text(content)
                }
                
                guard let finalKind = kind else {
                    return nil
                }
                
                let sender = Sender(photoURL: "", displayName: name, senderId: senderEmail)
                                
                return Message(sender: sender, messageId: messageId, sentDate: dateString, kind: finalKind)
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
        
        let currentEmail = DatabaseManager.safeEmail(emaildAddress: myEmail)
        
        // add new message to messages array
        self.database.child("\(conversation)/messages").observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let strongSelf = self else { return }
            guard var currentMessages = snapshot.value as? [[String: Any]] else {
                completion(false)
                return
            }
            
            //add new message
            let messageDate = newMessage.sentDate
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
            
            guard let myEmmail = UserDefaults.standard.value(forKey: "email") as? String else {
                completion(false)
                return
            }
            
            
            let currentUserEmail = DatabaseManager.safeEmail(emaildAddress: myEmmail)
            
            let newMessageEntry: [String: Any] = [
                "id": newMessage.messageId,
                "type": newMessage.kind.messageKindString,
                "content": message,
                "name": name,
                "date": dateString,
                "sender_email": currentUserEmail,
                "is_read": false,
            ]
            
            // update sender latest message
            currentMessages.append(newMessageEntry)
            
            strongSelf.database.child("\(conversation)/messages").setValue(currentMessages) { error, _ in
                guard error == nil else {
                    completion(false)
                    return
                }
                
                strongSelf.database.child("\(currentEmail)/conversations").observeSingleEvent(of: .value) { snapshot in
                    guard var currentUserConversations = snapshot.value as? [[String: Any]] else {
                        completion(false)
                        return
                    }
                    
                    let updatedValue: [String: Any] = [
                        "date": dateString,
                        "is_read": false,
                        "message": message
                    ]
                    
                    var targetConversation: [String: Any]?
                    var position = 0
                    
                    for conversationDictionary in currentUserConversations {
                        if let currentId = conversationDictionary["id"] as? String, currentId == conversation {
                            targetConversation = conversationDictionary
                            break
                        }
                        position += 1
                    }
                    targetConversation?["latest_message"] = updatedValue
                    guard let finalConversation = targetConversation else {
                        completion(false)
                        return
                    }
                    currentUserConversations[position] = finalConversation
                    strongSelf.database.child("\(currentEmail)/conversations").setValue(currentUserConversations) { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        //update latest message for recepient user
                        strongSelf.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { snapshot in
                            guard var otherUserConversations = snapshot.value as? [[String: Any]] else {
                                completion(false)
                                return
                            }
                            
                            let updatedValue: [String: Any] = [
                                "date": dateString,
                                "is_read": false,
                                "message": message
                            ]
                            
                            var targetConversation: [String: Any]?
                            var position = 0
                            
                            for conversationDictionary in otherUserConversations {
                                if let currentId = conversationDictionary["id"] as? String, currentId == conversation {
                                    targetConversation = conversationDictionary
                                    break
                                }
                                position += 1
                            }
                            targetConversation?["latest_message"] = updatedValue
                            guard let finalConversation = targetConversation else {
                                completion(false)
                                return
                            }
                            otherUserConversations[position] = finalConversation
                            strongSelf.database.child("\(otherUserEmail)/conversations").setValue(otherUserConversations) { error, _ in
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
    
    public func deleteConversation(conversationId: String, completion: @escaping (Bool) -> Void) {
        
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emaildAddress: email)
        
        print("deleting conv with id: \(conversationId)")
        
        // Get all convers. for current user
        // delete conversat in collection with target id
        // reset those convers for the user in database
        let ref = database.child("\(safeEmail)/conversations")
        ref.observeSingleEvent(of: .value) { snapshot in
            if var conversations = snapshot.value as? [[String: Any]] {
                var positionToRemove = 0
                for conversation in conversations {
                    if let id = conversation["id"] as? String,
                       id == conversationId {
                        print("found convers. to delete")
                        break
                    }
                    positionToRemove += 1
                }
                
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
