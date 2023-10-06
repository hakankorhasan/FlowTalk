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
import CoreLocation
import Lottie

struct Message: MessageType {
    public var sender: SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKind
    public var audioDur: Float?
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

struct Location: LocationItem {
    let location: CLLocation
    let size: CGSize
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
    
    var longPressGesture: UILongPressGestureRecognizer!
    var audioFileName = ""
    var audioDuration: Date!
    
    open lazy var audioController = BasicAudioController(messageCollectionView: messagesCollectionView)
        
   
    //open lazy var audioController = AudioController(messageCollectionView: messagesCollectionView)
    public var isEmptyText: Bool = true
    
    public let otherUserEmail: String
    public let conversationId: String?
    public var isNewConversation = false
    private let inputBarForButton = InputBarAccessoryView()
   
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
       
        
        configureGestureRecognizer()
        setupInputButton()
        setupTrashAnimation()
        
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        audioController.stopAnyOngoingPlaying()
    }
    
    let trashButton = InputBarButtonItem()
    let paperclipButton = InputBarButtonItem()
    var animationView = LottieAnimationView(name: "trashJson")

    private func setupTrashAnimation() {
        // Lottie animasyonu oluşturun
        animationView = LottieAnimationView(name: "trashJson")
        let animationSize = CGSize(width: 40, height: 50)
        animationView.animationSpeed = 0.5
            animationView.frame = CGRect(x: 0, y: 0, width: animationSize.width, height: animationSize.height)
        animationView.loopMode = .playOnce
       
        trashButton.setSize(CGSize(width: 40, height: 50), animated: true)// UIButton'in boyutunu ayarlayın
        trashButton.addSubview(animationView) // Lottie animasyonunu UIButton'a ekleyin
       
    }

    private func setupInputButton() {
       
        paperclipButton.setSize(CGSize(width: 25, height: 25), animated: true)
        paperclipButton.setImages(lightModeImage: UIImage(named: "paperclip-lightmode"), darkModeImage: UIImage(named: "paperclip-darkmode"))//setImage(UIImage(named: "paperclip"), for: .normal)
        paperclipButton.onTouchUpInside { [weak self] _ in
            self?.presentInputActionSheet()
        }
        
        //button.addTarget(self, action: #selector(inputButtonTapped), for: .touchUpInside
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([paperclipButton], forStack: .left, animated: false)
    
    }
    
    var recorder: AVAudioRecorder?
    var player: AVAudioPlayer?
    var timer: Timer?
    var url:URL?
    var audioLevel: Float = 0.0
    
    private func startRecording(audiofilename: String) {
        player?.stop()
        if let recorder = self.recorder{
            if recorder.isRecording{
                self.recorder?.pause()
            }
            else{
                self.recorder?.record()
            }
        }
        else{
            initializeRecorder(audioFile: audiofilename)
        }
        
    }
    
    private func stopRecording() {
        self.recorder?.stop()
        let session = AVAudioSession.sharedInstance()
        try! session.setActive(false)
        self.url = self.recorder?.url
        self.recorder = nil
        timer?.invalidate()
        timer = nil
    }
    
    func initializeRecorder(audioFile: String) {
        
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, options: .defaultToSpeaker)
        let directory =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        var recordSetting = [AnyHashable: Any]()
        recordSetting[AVFormatIDKey] = kAudioFormatMPEG4AAC
        recordSetting[AVSampleRateKey] = 16000.0
        recordSetting[AVNumberOfChannelsKey] = 1
        if let filePath = directory.first?.appendingPathComponent(audioFile), let audioRecorder = try? AVAudioRecorder(url: filePath, settings: (recordSetting as? [String : Any] ?? [:])){
            print(filePath)
            
            self.recorder = audioRecorder
            self.recorder?.delegate = self
            self.recorder?.isMeteringEnabled = true
            self.recorder?.prepareToRecord()
            self.recorder?.record()
        }
        //filepath is an optional URL
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object:  player?.currentTime)
    }
    
    @objc func playerDidFinishPlaying() {
        // Your code here
        self.player?.stop()
    }
    
    
    private func configureGestureRecognizer(){
        
        longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(recordAudio))
        longPressGesture.minimumPressDuration = 0.5
        longPressGesture.delaysTouchesBegan = true
    }
    
    
    @objc func recordAudio() {
        
        UIView.animate(withDuration: 0.2) {
            // Butonu büyüt
            self.messageInputBar.sendButton.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            self.messageInputBar.sendButton.backgroundColor = .green
        }
        
        switch longPressGesture.state {
        case .began:
            
            audioDuration = Date()
            audioFileName = Date().stringDate()
            audioFileName = audioFileName + ".m4a"
            startRecording(audiofilename: audioFileName)
            
        case .changed:
            
        // Bu bölümde parmağın ekranın 2/3'üne doğru kaydırılıp kaydırılmadığını kontrol ediyoruz.
            let translationX = longPressGesture.location(in: view).x
            let screenWidth = view.frame.size.width
            if translationX < (screenWidth - ((2.0/3.0) * screenWidth)) {
                
                longPressGesture.isEnabled = false
                // Parmağın ekranın 2/3'ünden fazlasına kaydırıldıysa kaydırmayı iptal et
                stopRecording()
                // Butonu eski haline getir
            UIView.animate(withDuration: 0.2) {
                 self.messageInputBar.inputTextView.isHidden = false
                 self.messageInputBar.sendButton.transform = .identity
                 self.messageInputBar.sendButton.backgroundColor = UIColor(#colorLiteral(red: 0.8045918345, green: 0.8646553159, blue: 0.9917096496, alpha: 1))
                }
                
            // Ardından ses kaydını sil
            if !audioFileName.isEmpty {
                longPressGesture.isEnabled = true
                messageInputBar.setLeftStackViewWidthConstant(to: 50, animated: true)
                messageInputBar.setStackViewItems([trashButton], forStack: .left, animated: false)
                deleteAudioFileWithName(audioFileName)
                animationView.play {(finished) in
                    if finished {
                        self.messageInputBar.setStackViewItems([self.paperclipButton], forStack: .left, animated: true)
                        self.messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: true)
                    } else {
                        
                    }
                }
                
                audioFileName = ""
                }
            }
        case .ended:
            longPressGesture.isEnabled = true
            stopRecording()
            
            UIView.animate(withDuration: 0.2) {
                // Butonu küçült
                self.messageInputBar.inputTextView.isHidden = false
                self.messageInputBar.sendButton.transform = .identity
                self.messageInputBar.sendButton.backgroundColor = UIColor(#colorLiteral(red: 0.8045918345, green: 0.8646553159, blue: 0.9917096496, alpha: 1))
            }
            
                guard let messageId = createMessageId(),
                    let conversationId = conversationId,
                    let name = title,
                    let selfSender = selfSender else {
                    return
                }
                
                let audioD = audioDuration.interval(ofComponent: .second, from: Date())
                let fileDirectory =  "message_audios/"
                StorageManager.shared.uploadAudio(audioFileName, directory: fileDirectory) { audioUrl in
                   
                    guard let url = URL(string: audioUrl ?? "") else {
                        return
                    }
                    
                    let media = Audio(url: url, duration: audioD, size: .zero)
                                             
                    let message = Message(sender: selfSender,
                                        messageId: messageId,
                                        sentDate: Date(),
                                        kind: .audio(media), audioDur: audioD)
                    
                    
                    DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: self.otherUserEmail, name: name, newMessage: message) { success in
                        if success {
                            print("Sesli mesaj gönderildi")
                        } else {
                            print("Sesli mesaj gönderme başarısız oldu")
                        }
                    }
                }
            
            audioFileName = ""
            
        default:
            break
        }
    }

    func deleteAudioFileWithName(_ fileName: String) {
        let fileManager = FileManager.default
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try fileManager.removeItem(at: fileURL)
            print("Dosya silindi: \(fileName)")
        } catch {
            print("Dosya silinemedi: \(error)")
        }
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
        
        actionSheet.addAction(UIAlertAction(title: "Location", style: .default, handler: { [weak self] _ in
            self?.presentLocationPicker()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            
        }))
        
        present(actionSheet, animated: true)
    }
    
    private func presentLocationPicker() {
        let vc = LocationPickerViewController(coordinates: nil)
        vc.isPickable = true
        vc.title = "Pick Location"
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.completion = { [weak self] selectedCoorinates in
            
            guard let strongSelf = self else { return }
            
            guard let messageId = strongSelf.createMessageId(),
                  let conversationId = strongSelf.conversationId,
                  let name = strongSelf.title,
                  let selfSender = strongSelf.selfSender else {
                return
            }
            
            let longitude: Double = selectedCoorinates.longitude
            let latitute: Double = selectedCoorinates.latitude
            
            print("longitude: \(longitude)")
            print("latitude: \(latitute)")
            
            let location = Location(location:
                                        CLLocation(latitude: latitute,
                                                   longitude: longitude),
                                    size: .zero)
            
            let message = Message(sender: selfSender, messageId: messageId, sentDate: Date(), kind: .location(location))
            
            DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message) { success in
                if success {
                    print("sended location")
                } else {
                    print("failed to send location message")
                }
            }
        }
        navigationController?.pushViewController(vc, animated: true)
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


extension ChatViewController: AVAudioRecorderDelegate, AVAudioPlayerDelegate{
    
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
    
    func inputBar(_ inputBar: InputBarAccessoryView, textViewTextDidChangeTo text: String) {
        if text.isEmpty {
            isEmptyText = true
        } else {
            isEmptyText = false
            print("dolu: ",text)
        }
    }
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        
       
        if !isEmptyText {
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
        else if isEmptyText {
            // send to audio message
            inputBar.sendButton.addGestureRecognizer(longPressGesture)
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
    
    
    func configureAudioCell(_ cell: AudioMessageCell, message: MessageType) {

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
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .location(let locationData):
            
            let coordinate = locationData.location.coordinate
            let vc = LocationPickerViewController(coordinates: coordinate)
            vc.isPickable = false
            vc.title = "Location"
            self.navigationController?.pushViewController(vc, animated: true)
            
        default:
            break
        }
    }
    
    func didTapPlayButton(in cell: AudioMessageCell) {
            guard let indexPath = messagesCollectionView.indexPath(for: cell),
                let message = messagesCollectionView.messagesDataSource?.messageForItem(at: indexPath, in: messagesCollectionView) else {
                    print("Failed to identify message when audio cell receive tap gesture")
                    return
            }
            guard audioController.state != .stopped else {
                // There is no audio sound playing - prepare to start playing for given audio message
                audioController.playSound(for: message, in: cell)
                return
            }
            if audioController.playingMessage?.messageId == message.messageId {
                // tap occur in the current cell that is playing audio sound
                if audioController.state == .playing {
                    audioController.pauseSound(for: message, in: cell)
                } else {
                    audioController.resumeSound()
                }
            } else {
                // tap occur in a difference cell that the one is currently playing sound. First stop currently playing and start the sound for given message
                audioController.stopAnyOngoingPlaying()
                audioController.playSound(for: message, in: cell)
            }
        }
}
