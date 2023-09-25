//
//  ChatViewController.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 9.09.2023.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import SDWebImage
import AVKit
import AVFoundation

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

struct Media: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
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
    
    init(with email: String, id: String?) {
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
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        
        setupInputButton()
    }
    
    private func setupInputButton() {
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: true)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside { [weak self] _ in
            self?.presentInputActionSheet()
        }
        
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
        
    }
    
    private func presentInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Media", message: "What would you like to attach?", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Photo", style: .default, handler: { [weak self] _ in
            self?.presentPhotoInputActionsSheet()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: { [weak self] _ in
            self?.presentVideoInputActionsSheet()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: { _ in
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            
        }))
        
        present(actionSheet, animated: true)
    }
    
    private func presentPhotoInputActionsSheet() {
        let actionSheet = UIAlertController(title: "Attach Photo", message: "Where would you like to attach photo from?", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
             
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { [weak self] _ in
            
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            
        }))
        
        present(actionSheet, animated: true)
    }
    private func presentVideoInputActionsSheet() {
        let actionSheet = UIAlertController(title: "Attach Video", message: "Where would you like to attach a video from?", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
             
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Library", style: .default, handler: { [weak self] _ in
            
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            
        }))
        
        present(actionSheet, animated: true)
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
                print("failed to get messages: ",error.localizedDescription)
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

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true)
        guard let messageId = createMessageId(),
              let conversationId = conversationId,
              let name = self.title,
              let selfSender = self.selfSender else {
            return
        }
        
        if let image = info[.editedImage] as? UIImage, let imageData = image.pngData() {
            
            let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".png"
            // Upload image
            StorageManager.shared.uploadMessagePhoto(with: imageData, fileName: fileName) { [weak self] result in
                
                guard let strongSelf = self else {return}
                
                switch result {
                case .success(let urlString):
                    // ready to sent message
                    
                    guard let url = URL(string: urlString),
                          let placeholderImage = UIImage(systemName: "plus") else {
                        return
                    }
                    
                    let media = Media(url: url, image: nil, placeholderImage: placeholderImage, size: .zero)
                    
                    let message = Message(sender: selfSender,
                                          messageId: messageId,
                                          sentDate: Date(),
                                          kind: .photo(media))
                    
                    DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message) { success in
                        if success {
                            print("sent photo message")
                        }
                        else {
                            print("failed to sent photo message")
                        }
                    }
                    
                    
                case .failure(let error):
                    print("message photo upload error: ",error)
                }
            }
        }
        else if let videoUrl = info[.mediaURL] as? URL {
            let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".mov"
            
            // Upload Video
            StorageManager.shared.uploadMessageVideo(with: videoUrl, fileName: fileName) { [weak self] result in
                
                guard let strongSelf = self else {return}
                
                switch result {
                case .success(let urlString):
                    // ready to sent message
                    print("uploaded message video: \(urlString)")
                    guard let url = URL(string: urlString),
                          let placeholderImage = UIImage(systemName: "plus") else {
                        return
                    }
                    
                    let media = Media(url: url,
                                      image: nil,
                                      placeholderImage: placeholderImage,
                                      size: .zero)
                    
                    let message = Message(sender: selfSender,
                                          messageId: messageId,
                                          sentDate: Date(),
                                          kind: .video(media))
                    
                    DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message) { success in
                        if success {
                            print("sent photo message")
                        }
                        else {
                            print("failed to sent photo message")
                        }
                    }
                    
                    
                case .failure(let error):
                    print("message video upload error: ",error.localizedDescription)
                }
            }
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
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        
        guard let message = message as? Message else {
            return
        }
        
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            imageView.sd_setImage(with: imageUrl)
        default:
            break
        }
    }
    
}

extension ChatViewController: MessageCellDelegate {
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        print("tapped image")
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .photo(let media):
            
            guard let imageUrl = media.url else {
                return
            }
            
            let vc = PhotoViewerViewController(with: imageUrl)
            self.navigationController?.pushViewController(vc, animated: true)
            
        case .video(let media):
            
            guard let videoUrl = media.url else {
                return
            }
            
            let vc = AVPlayerViewController()
            vc.player = AVPlayer(url: videoUrl)
            vc.player?.play()
            present(vc, animated: true)
            
        default:
            break
        }
    }
    
    func didTapAccessoryView(in cell: MessageCollectionViewCell) {
       
    }
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        
        print("tapped text")
      
    }
}
