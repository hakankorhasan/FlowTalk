//
//  ChatViewController.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 9.09.2023.
//

import UIKit
import MessageKit
import InputBarAccessoryView

struct Message: MessageType {
    public var sender: SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKind
}

struct Sender: SenderType {
    public var photoURL: String
    public var displayName: String
    public var senderId: String
}

extension MessageKind {
    var messageKindString: String {
        switch self {
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributed_text"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "link_preview"
        case .custom(_):
            return "custom"
        }
    }
}


class ChatViewController: MessagesViewController {

    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    public let otherUserEmail: String
    public let conversationId: String?
    public var isNewConversation = false
    
    private var messages = [Message]()
    
    //selfSender adlı bir hesaplanmış özellik (computed property) kullanır.
    //Bu özellik, her çağrıldığında UserDefaults ile saklanan e-posta adresini alır ve
    //bu e-posta adresini kullanarak bir Sender nesnesi oluşturur. Bu nesneyi döndürür.
    //Bu kod, selfSender özelliğine her erişildiğinde yeni bir Sender nesnesi oluşturur.
    //Yani her çağrıldığında farklı bir Sender nesnesi dönebilir.
    private var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let safeEmail = DatabaseManager.safeEmail(emaildAddress: email)
        
        return Sender(photoURL: "",
               displayName: "me",
               senderId: safeEmail)
    }
    
    init(with email: String, id: String) {
        self.otherUserEmail = email
        self.conversationId = id
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .yellow
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
    }
    
    func listeningForMessages(id: String, shouldScrollToBottom: Bool) {
        DatabaseManager.shared.getAllMessagesForConversation(with: id) { [weak self] result in
            switch result {
            case .success(let messages):
                guard !messages.isEmpty else  {
                    return
                }
                self?.messages = messages
                
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    
                    if shouldScrollToBottom {
                        self?.messagesCollectionView.scrollToLastItem()
                    }
                }
            case .failure(let error):
                print("failed to get messages: ",error)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // bu sayfaya gelirken klavyenin direkt olarak açılmasını sağlar.
        messageInputBar.inputTextView.becomeFirstResponder()
        if let conversationId = conversationId {
            listeningForMessages(id: conversationId, shouldScrollToBottom: true)
        }
    }
    
}

extension ChatViewController: InputBarAccessoryViewDelegate {
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
              let selfSender = self.selfSender,
              let messageId = createMessageId() else {
            return
        }
        
        let message = Message(sender: selfSender,
                              messageId: messageId,
                              sentDate: Date(),
                              kind: .text(text))
        
        print("sending: \(text)")
        
        //Send message
        if isNewConversation {
            // create convo in database
            DatabaseManager.shared.createNewConversations(with: otherUserEmail, name: self.title ?? "", firstMessage: message) { [weak self] success in
                if success {
                    print("message send")
                    self?.isNewConversation = false
                }
                else {
                    print("failed to send")
                }
            }
        }
        else {
            
            guard let conversationId = conversationId,
            let name = self.title else {
                return
            }
            // append to existing conversation data
            DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: otherUserEmail, name: name, newMessage: message) { success in
                if success {
                    print("message sent")
                }
                else {
                    print("failed to sent")
                }
            }
        }
    }
    
    private func createMessageId() -> String? {
        // date, otheruseremail, senderEmail, randomInt
    
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let safeCurrentEmail = DatabaseManager.safeEmail(emaildAddress: currentUserEmail)
        
        let dateString = Self.dateFormatter.string(from: Date())
        
        let newIdentifier = "From\(safeCurrentEmail)_Tomk\(otherUserEmail)"
        print("created message id: \(newIdentifier)")
        return newIdentifier
    }
}

extension ChatViewController: MessagesDataSource, MessagesDisplayDelegate, MessagesLayoutDelegate {
    
    func currentSender() -> MessageKit.SenderType {
        if let sender = selfSender {
            return sender
        }
        
        fatalError("self sender is nil, email should be cached")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> MessageKit.MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        messages.count
    }
    
    
    
}
