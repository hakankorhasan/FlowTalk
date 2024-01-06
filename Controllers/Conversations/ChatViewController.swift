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
import FirebaseDatabase
import CoreLocation
import Lottie
import UserNotifications
 
final class ChatViewController: MessagesViewController {
 
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
    
    private let userImageView: UIImageView = {
       let iv = UIImageView()
        return iv
    }()
    
    private let userNameLabel: UILabel = {
       let label = UILabel()
        label.text = "Name"
        return label
    }()
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    private let onlineDotView: UIView = {
       let dotView = UIView()
        dotView.backgroundColor = .darkGray
        return dotView
    }()
    
    private let onlineTextLabel: UILabel = {
        let label = UILabel()
        return label
    }()
    
    private let videoCallButton: UIButton = {
       let btn = UIButton()
        btn.setImage(UIImage(named: "video-calling"), for: .normal)
        return btn
    }()
    
    // These variables are used for the userImageView
    private var senderUserPhotoURL: URL?
    private var otherUserPhotoURL: URL?

    var longPressGesture: UILongPressGestureRecognizer!
   
    public var isEmptyText: Bool = true
    public let otherUserEmail: String
    public var conversationId: String?
    public var isNewConversation = false
    
    // these variables are used for the AudioRecorder class
    var handle: UInt!
    var updateHandler: UInt!
    var readUpdateHandler: UInt!
    private var ref: DatabaseReference!
    private var readRef: DatabaseReference!
    var audioFileName = ""
    private var conversationPath = ""
    var audioDuration: Date!
    public lazy var audioController = BasicAudioController(messageCollectionView: messagesCollectionView)
    
    private let trashButton = InputBarButtonItem()
    private let paperclipButton = InputBarButtonItem()
    private var animationView = LottieAnimationView(name: "trashJson")
   
    private var messages = [Message]()
    private var bombSoundEffect: AVAudioPlayer?
    
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
        navigationItem.hidesBackButton = true
        setupMessageCollectionViewDelegate()
        
        setupOnlineState()
        
        setupReadState()
        
        navBarSetupUI()
        
        configureGestureRecognizer()
        
        setupInputButton()
        
        setupTrashAnimation()
       
        let gesture = UITapGestureRecognizer(target: self, action: #selector(tappedUserImg))
        userImageView.isUserInteractionEnabled = true
        userImageView.addGestureRecognizer(gesture)
    }
    
    @objc private func tappedUserImg() {
        let profileContr = ProfilePageController()
        self.navigationController?.pushViewController(profileContr, animated: true)
    }
    
    @objc private func handleBack() {
    //    self.navigationController?.navigationBar.backgroundColor = .clear
        self.navigationController?.popViewController(animated: true)
    }
    
    var lastMessageDate: Date?
    var isFirstMessage = true
    
    func dataToBeListening(id: String, shouldScrollToBottom: Bool) {
        listeninForMessage(id: id, shouldScrollToBottom: shouldScrollToBottom)
        listeningForMessageSounds()
    }
    
    private func listeninForMessage(id: String, shouldScrollToBottom: Bool) {
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
    
    private var lastPlayedMessageId: String?

    private func listeningForMessageSounds() {
        let safeEmail = DatabaseManager.safeEmail(emaildAddress: currentSender().senderId)
        let messageRef = Database.database().reference().child(self.conversationPath).child("messages")
        // En son alınan mesajın tarihini saklayın
        messageRef.queryOrdered(byChild: "date").queryLimited(toLast: 1).observe(.childAdded) { [weak self] snapshot, _ in
            guard let self = self,
                  let messageId = snapshot.key as? String,
                  let messageData = snapshot.value as? [String: Any],
                  let sender = messageData["sender_email"] as? String else {
                return
            }
            
            // İlk çalıştığında işlemeyi atla
            guard !self.isFirstMessage else {
                self.isFirstMessage = false
                return
            }

            if messageId != self.lastPlayedMessageId {
                        // Mesaj daha önce çalınmadıysa
                self.lastPlayedMessageId = messageId

                if sender == safeEmail {
                    // Gönderen, kullanıcı ise bir ses çal
                    self.playNotifSound(named: "take-headphones-out-106535")
                } else {
                    // Gönderen, diğer kullanıcı ise başka bir ses çal
                    self.playNotifSound(named: "intuition-561")
                }
            }
        }
    }
   
    private func playNotifSound(named soundFileName: String) {
        if let path = Bundle.main.path(forResource: soundFileName, ofType: "mp3") {
            let url = URL(fileURLWithPath: path)

            do {
                bombSoundEffect = try AVAudioPlayer(contentsOf: url)
                bombSoundEffect?.play()
            } catch {
                print("Couldn't load sound file: \(error.localizedDescription)")
            }
        } else {
            print("Sound file not found.")
        }
    }
    
    private func setupMessageCollectionViewDelegate() {
        let viewBack = UIImageView()
        
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emaildAddress: email)
        StorageManager.shared.downloadUrl(for: "images/\(safeEmail)_chatBack.jpg") { result in
            switch result {
            case .success(let downloadUrl):
                DispatchQueue.main.async {
                    viewBack.sd_setImage(with: downloadUrl)
                }
            case .failure(let error):
                print("error", error)
            }
        }
        
        viewBack.contentMode = .scaleAspectFit
        messagesCollectionView.backgroundView = viewBack
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        maintainPositionOnKeyboardFrameChanged = true // default false
        showMessageTimestampOnSwipeLeft = true // default false
        messageInputBar.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showImage(true)
        // bu sayfaya gelirken klavyenin direkt olarak açılmasını sağlar.
        let height: CGFloat = 100 //whatever height you want to add to the existing height
            let bounds = self.navigationController!.navigationBar.bounds
            self.navigationController?.navigationBar.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height + height)
        messageInputBar.inputTextView.becomeFirstResponder()
        
        if let conversationId = conversationId {
            dataToBeListening(id: conversationId, shouldScrollToBottom: true)
        }
        
        if !isNewConversation {
            DatabaseManager.shared.updateConversationStatus(otherUserEmail: otherUserEmail)
        }
    }
    
    private func updateConversationStatus(otherUserEmail: String) {
        let ref = Database.database().reference()
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {return}
        
        let safeCurrEmail = DatabaseManager.safeEmail(emaildAddress: currentEmail)
        let safeOtherUserEmail = DatabaseManager.safeEmail(emaildAddress: otherUserEmail)
        
        let isRoomBeginRef = ref.child("\(safeCurrEmail)").child("conversations").child("0").child("isRoomBeginIn")
        isRoomBeginRef.setValue(true)
        
        isRoomBeginRef.observeSingleEvent(of: .value) { (snapshot) in
            guard let isRoomBeginValue = snapshot.value as? Bool else { return }
            
            let latestMesReadRef = ref.child(safeOtherUserEmail).child("conversations").child("0").child("latest_message").child("is_read")
            let currentUserUpdate = ref.child(safeCurrEmail).child("conversations").child("0").child("latest_message").child("is_read")
            
            if isRoomBeginValue {
                latestMesReadRef.setValue(true)
                currentUserUpdate.setValue(true)
                
            } else {
                print("\(safeOtherUserEmail) kullanıcısı oda da değil mesjaınızı göremez")
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Remove observer
        self.ref.removeObserver(withHandle: self.handle)
        self.ref.removeObserver(withHandle: self.updateHandler)
        
       // self.readRef.removeObserver(withHandle: self.readHandle)
        self.readRef.removeObserver(withHandle: self.readUpdateHandler)
        
        let ref = Database.database().reference()
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {return}
        let safeCurrEmail = DatabaseManager.safeEmail(emaildAddress: currentEmail)
        
        if !isNewConversation {
            let isRoomBeginRef = ref.child("\(safeCurrEmail)").child("conversations").child("0").child("isRoomBeginIn")
            isRoomBeginRef.setValue(false)
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        showImage(false)
        audioController.stopAnyOngoingPlaying()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        DatabaseManager.shared.fetchUserSettings(safeEmail: otherUserEmail, isCurrentUser: false) {
            
            if getUserSetting(status: .other, setting: .onlineInfo) {
                
                self.onlineDotView.isHidden = false
                
            } else {
                
                self.onlineDotView.isHidden = true
                
            }
            
            if getUserSetting(status: .other, setting: .profilePhoto) {
                self.userImageView.isHidden = false
            } else {
                self.userImageView.image = UIImage(systemName: "person.fill")
                self.userImageView.tintColor = .darkGray
            }
        }
        
        let databaseRef = Database.database().reference()
        let safeEmail = DatabaseManager.safeEmail(emaildAddress: selfSender?.senderId ?? "")
        let safeOther = DatabaseManager.safeEmail(emaildAddress: otherUserEmail)
        conversationPath = "conversation_From\(safeEmail)_Tomk\(safeOther)"
 
        // Belirli bir çocuk düğümün varlığını sorgula
        let childRef = databaseRef.child(conversationPath)

        childRef.observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists() {
                // Belirtilen çocuk düğüm mevcut
                print("Belirtilen çocuk düğüm mevcut.")
                self.makeRead()
            } else {
                // Belirtilen çocuk düğüm mevcut değil
                print("Belirtilen çocuk düğüm mevcut değil.")
                self.conversationPath = "conversation_From\(safeOther)_Tomk\(safeEmail)"
                print("conversationPath: ", self.conversationPath)
                self.makeRead()

            }
        }
        
        setupOnlineState()
    }
    
    /// - MARK:  Users' abilitiy to be online
    /// - It's updates and reads the user's online information.
    /// - It works as live data.
    /// - Instantly reflects online information on the screen.
    func setupOnlineState() {
        let otherUserEm = self.otherUserEmail
        let otherUserSafeEmail = DatabaseManager.safeEmail(emaildAddress: otherUserEm)
        
        let usersRef = Database.database().reference().child("users")
            
        ref = usersRef
            
        let handleChildAdded: (DataSnapshot) -> Void = { snapshot in
            self.handleSnapshot(snapshot)
        }
            
        let handleChildChanged: (DataSnapshot) -> Void = { snapshot in
            self.handleSnapshot(snapshot)
        }
            
        handle = ref.observe(.childAdded, with: handleChildAdded)
        updateHandler = ref.observe(.childChanged, with: handleChildChanged)
       
    }
    
    private func setupReadState() {
        let otherUserEm = self.otherUserEmail
        let otherUserSafeEmail = DatabaseManager.safeEmail(emaildAddress: otherUserEm)
        let conversationsRef = Database.database().reference().child("\(otherUserSafeEmail)").child("conversations").child("0")
        readRef = conversationsRef
        let readChildChanged: (DataSnapshot) -> Void = { snapshot in
            self.isReadCheckMessage(snapshot, refrence: self.readRef)
            
        }
        
        readUpdateHandler = readRef.observe(.childChanged, with: readChildChanged)
    }
    
    private func makeRead() {
        let messageRef = Database.database().reference().child(self.conversationPath).child("messages")
        
        let safeOtherEmail = DatabaseManager.safeEmail(emaildAddress: otherUserEmail)
        
        messageRef.observeSingleEvent(of: .value) { snapshot in
            
            if let messagesData = snapshot.value as? [[String: Any]] {
                var count = 0
                for messagesData in messagesData {
                    count += 1
                    if let messageSenderEmail = messagesData["sender_email"] as? String,
                       let isMessageRead = messagesData["is_read"] as? Bool,
                       messageSenderEmail == safeOtherEmail,
                       isMessageRead == false  {
                        let messageReadRef = messageRef.child("\(count-1)").child("is_read")
                        messageReadRef.setValue(true)
                    }
                }
            }
        }
    }
    
    private func isReadCheckMessage(_ snapshot: DataSnapshot, refrence: DatabaseReference) {
                
        let safeOtherEmail = DatabaseManager.safeEmail(emaildAddress: otherUserEmail)
        let updateMessageRef = Database.database().reference().child(self.conversationPath).child("messages")
        
        refrence.child("isRoomBeginIn").observeSingleEvent(of: .value) { snapshot in
            if let isRoom = snapshot.value as? Bool {
                print(isRoom)
                if isRoom {

                    updateMessageRef.observeSingleEvent(of: .value) { (snapshot) in
                        
                        if let messagesData = snapshot.value as? [[String: Any]] {
                            var count = 0
                            for messageData in messagesData {

                                count += 1
                                if let messageSenderEmail = messageData["sender_email"] as? String, messageSenderEmail == safeOtherEmail {
                                    
                                    let messageRef = updateMessageRef.child("\(count-1)").child("is_read")
                                    messageRef.setValue(true)
                                   
                                }
                            }
                        }
                       
                    }
                    
                } else {
                    print("Kullanıcı odada değil mesajları göremiyor")
                }
            }
           
        }
        
      
    }
    
    func handleSnapshot(_ snapshot: DataSnapshot) {
        if let userData = snapshot.value as? [String: Any], let email = userData["email"] as? String {
            if email == self.otherUserEmail {
                if let isOnline = userData["isOnline"] as? Bool,
                    var lastOnline = userData["lastOnline"] as? String {
                    self.isOnlineCheck(isOnline: isOnline, lastOnline: lastOnline)
                }
            }
        }
    }
    
    
    private func isOnlineCheck(isOnline: Bool, lastOnline: String) {
        
         if isOnline {
             UIView.animate(withDuration: 0.2) {
                 self.onlineDotView.backgroundColor = .green
                 if getUserSetting(status: .other, setting: .onlineInfo) {
                     self.onlineTextLabel.text = "Online"
                 } else {
                     self.onlineTextLabel.text = ""
                 }
                 
             }
         } else {
             UIView.animate(withDuration: 0.2) {
                 self.onlineDotView.backgroundColor = .lightGray
                 self.onlineTextLabel.text = "Last seen: " + lastOnline
             }
         }
        
    }
    
    
    private func showImage(_ show: Bool) {
        UIView.animate(withDuration: 0.2) {
            self.videoCallButton.alpha = show ? 1.0 : 0.0
        }
    }
    
    private func navBarSetupUI() {
        let backButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .done, target: self, action: #selector(handleBack))
        
        navigationItem.leftBarButtonItem = backButtonItem
        
        guard let navigationBar = self.navigationController?.navigationBar else { return }
        self.view.addGlobalUnsafeAreaView()

        navigationBar.addSubview(videoCallButton)
        videoCallButton.addTarget(self, action: #selector(handleVideoCall), for: .touchUpInside)
        videoCallButton.clipsToBounds = true
        videoCallButton.translatesAutoresizingMaskIntoConstraints = false
        
        videoCallButton.anchor(top: nil, leading: nil, bottom: navigationBar.bottomAnchor, trailing: navigationBar.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 10, right: Const.ImageRightMargin), size: .init(width: 32, height: 32))
        
        onlineDotView.layer.cornerRadius = 5
        onlineDotView.layer.masksToBounds = true
        onlineDotView.translatesAutoresizingMaskIntoConstraints = false
        onlineDotView.widthAnchor.constraint(equalToConstant: 10).isActive = true // Genişlik belirle
        onlineDotView.heightAnchor.constraint(equalToConstant: 10).isActive = true // Yükseklik belirle
        
        onlineTextLabel.font = .systemFont(ofSize: 12, weight: .regular)
        
        let otherPf = getUserSetting(status: .other, setting: .profilePhoto)
        
        if let otherUserPhotoURL = self.otherUserPhotoURL, otherPf {
              userImageView.sd_setImage(with: otherUserPhotoURL)
        } else {
            let email = self.otherUserEmail
            let safeEmail = DatabaseManager.safeEmail(emaildAddress: email)
            let path = "images/\(safeEmail)_profile_picture.png"
            StorageManager.shared.downloadUrl(for: path) { [weak self] result in
                switch result {
                case .success(let url):
                    DispatchQueue.main.async {
                        self?.otherUserPhotoURL = url
                        if otherPf {
                            self?.userImageView.sd_setImage(with: url)
                        } else {
                            self?.userImageView.image = UIImage(systemName: "person.fill")
                        }
                        
                    }
                case .failure(let error):
                   // self?.userImageView.image = UIImage(systemName: "questionmark")
                    print(error.localizedDescription)
                }
            }
        }
        
        userImageView.layer.cornerRadius = Const.ImageSizeForLargeState / 2
        userImageView.clipsToBounds = true
        userImageView.contentMode = .scaleAspectFill
        userImageView.layer.borderColor = UIColor.lightGray.cgColor
        userImageView.layer.borderWidth = 1.0
        userImageView.translatesAutoresizingMaskIntoConstraints = false
        userImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        userImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        
        userNameLabel.text = title
        
        let stackViewOnline = UIStackView(arrangedSubviews: [onlineDotView, onlineTextLabel])
        stackViewOnline.axis = .horizontal
        stackViewOnline.spacing = 4
        stackViewOnline.alignment = .center
        
        let verticalStackView = UIStackView(arrangedSubviews: [userNameLabel, stackViewOnline])
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 6
        verticalStackView.alignment = .leading
        
        let horizontalStackView = UIStackView(arrangedSubviews: [userImageView, verticalStackView])
        horizontalStackView.spacing = 15
        horizontalStackView.alignment = .center
       // horizontalStackView.distribution = .fillProportionally
        let spacer = UIView()
        let constraint = spacer.widthAnchor.constraint(greaterThanOrEqualToConstant: CGFloat.greatestFiniteMagnitude)
        constraint.isActive = true
        constraint.priority = .defaultLow
        
        let stackView = UIStackView(arrangedSubviews: [horizontalStackView, spacer])
        
        let spacer2 = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        spacer2.width = 10

        navigationItem.leftBarButtonItems = [spacer2, backButtonItem]
    
        navigationItem.titleView = stackView
        
    }
    
    @objc private func handleVideoCall() {
        let callVC = VideoCallController()
        let navControl = UINavigationController(rootViewController: callVC)
        navigationController?.pushViewController(callVC, animated: true)
    }
    
    private func setupTrashAnimation() {
        // Lottie animasyonu oluşturun
        animationView = LottieAnimationView(name: "trashJson")
        let animationSize = CGSize(width: 40, height: 50)
        animationView.animationSpeed = 0.5
        animationView.frame = CGRect(x: 0, y: 0, width: animationSize.width, height: animationSize.height)
        animationView.loopMode = .playOnce
        
        trashButton.setSize(CGSize(width: 40, height: 50), animated: true)
        trashButton.addSubview(animationView)
       
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
    
    private func configureGestureRecognizer(){
        longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(recordAudio))
        longPressGesture.minimumPressDuration = 0.5
        longPressGesture.delaysTouchesBegan = true
    }
    
    @objc func recordAudio() {
        var translationX = 0.0
        let screenWidth = view.frame.size.width
        UIView.animate(withDuration: 0.2) {
            // Butonu büyüt
            self.messageInputBar.sendButton.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            self.messageInputBar.sendButton.backgroundColor = .green
        }
        
        switch longPressGesture.state {
        case .began:
            
            messageInputBar.inputTextView.isEditable = false
            messageInputBar.inputTextView.placeholder = "〈〈〈 Swipe left to delete"
            messageInputBar.inputTextView.placeholderTextColor = .red
            
            audioDuration = Date()
            audioFileName = Date().stringDate()
            audioFileName = audioFileName + ".m4a"
            AudioRecorder.shared.startRecording(audiofilename: audioFileName)
        
        case .changed:
        
        // Bu bölümde parmağın ekranın 2/3'üne doğru kaydırılıp kaydırılmadığını kontrol ediyoruz.
            translationX = longPressGesture.location(in: view).x
            
            messageInputBar.sendButton.center.x = -screenWidth + translationX
            
            if translationX < (screenWidth - ((2.0/3.0) * screenWidth)) {
                handleSwipeGesture()
            }
            
        case .ended:
            if translationX > (screenWidth - ((2.0/3.0) * screenWidth)) {
                handleSwipeGesture()
            } else {
                longPressGesture.isEnabled = false
                
                AudioRecorder.shared.stopRecording()
                
                UIView.animate(withDuration: 0.2) {
                    // Butonu küçült
                    self.messageInputBar.inputTextView.placeholder = " "
                    self.messageInputBar.inputTextView.isEditable = true
                    self.messageInputBar.inputTextView.isHidden = false
                    self.messageInputBar.sendButton.transform = .identity
                    self.messageInputBar.sendButton.frame.origin.x = 0
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
                                              kind: .audio(media), audioDur: audioD, isRead: nil)
                        
                        
                        DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: self.otherUserEmail, name: name, newMessage: message) { success in
                            if success {
                                print("Sesli mesaj gönderildi")
                            } else {
                                print("Sesli mesaj gönderme başarısız oldu")
                            }
                        }
                    }
                
                audioFileName = ""
                longPressGesture.isEnabled = true
            }
            
        default:
            break
        }
    }
    
    func handleSwipeGesture() {
        
        AudioRecorder.shared.stopRecording()
        longPressGesture.isEnabled = false
        
        messageInputBar.setLeftStackViewWidthConstant(to: 50, animated: true)
        messageInputBar.setStackViewItems([trashButton], forStack: .left, animated: false)
        animationView.play {(finished) in
            if finished {
                self.messageInputBar.setStackViewItems([self.paperclipButton], forStack: .left, animated: true)
                self.messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: true)
            }
        }
        // Butonu eski haline getir
        UIView.animate(withDuration: 0.2) {
            // self.messageInputBar.inputTextView.isHidden = false
            self.messageInputBar.sendButton.backgroundColor = UIColor(#colorLiteral(red: 0.8045918345, green: 0.8646553159, blue: 0.9917096496, alpha: 1))
            self.messageInputBar.inputTextView.placeholder = " "
            self.messageInputBar.sendButton.transform = .identity
            self.messageInputBar.inputTextView.placeholderTextColor = .clear
            self.messageInputBar.inputTextView.isEditable = true
        }
        
        // Ardından ses kaydını sil
        if !audioFileName.isEmpty {
            longPressGesture.isEnabled = true
            AudioRecorder.shared.deleteAudioFileWithName(audioFileName)
            audioFileName = ""
        }
    }
    
    private func presentLocationPicker() {
        let vc = LocationPickerViewController(coordinates: nil)
        vc.isPickable = true
        vc.title = "Pick Location"
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.completion = { [weak self] selectedCoorinates in
            
            guard let strongSelf = self else { return }
            
            guard let messageId = strongSelf.createMessageId(),
                  let selfSender = strongSelf.selfSender else {
                return
            }
            
            let longitude: Double = selectedCoorinates.longitude
            let latitute: Double = selectedCoorinates.latitude
            
            let location = Location(location:
                                        CLLocation(latitude: latitute,
                                                   longitude: longitude),
                                    size: .zero)
            
            let message = Message(sender: selfSender, messageId: messageId, sentDate: Date(), kind: .location(location), isRead: nil)

            self?.send(message: message)
            
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func send(message: Message) {
        
        guard let selfSender = self.selfSender,
              let messageId = createMessageId() else {
            return
        }
       
        let newMessage = Message(sender: selfSender,
                                 messageId: messageId,
                                 sentDate: message.sentDate,
                                 kind: message.kind,
                                 isRead: nil)
        
        if isNewConversation
        {
            DatabaseManager.shared.createNewConversations(with: otherUserEmail, name: self.title ?? "", firstMessage: newMessage) { [weak self] success in
                
                guard let strongSelf = self else { return }
                if success
                {
                    print("message send")
                    strongSelf.isNewConversation = false
                    let mewConversationId = "conversation_\(message.messageId)"
                    strongSelf.conversationId = mewConversationId
                    converId = mewConversationId
                    strongSelf.dataToBeListening(id: mewConversationId, shouldScrollToBottom: true)
                    strongSelf.messageInputBar.inputTextView.text = nil
                }
                else
                {
                    print("failed to send")
                }
            }
        }
        else
        {
            guard let conversationId = conversationId,
                  let name = self.title else {
                return
            }
                    
            DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: self.otherUserEmail, name: name, newMessage: newMessage) { [weak self] success in
                if success {
                    self?.messageInputBar.inputTextView.text = nil
                    print("message sent")
                } else {
                    print("failed to send")
                }
            }
        }
    }
    
    private func presentInputActionSheet() {
        
        let actionSheet = UIAlertController(title: "Attach Media", message: "What would you like to attach?", preferredStyle: .actionSheet)
        
        let photoAction = UIAlertAction(title: "Photo", style: .default) { [weak self] _ in
            self?.presentPhotoInputActionsSheet()
        }
        let image = UIImage(systemName: "photo.on.rectangle.angled")
        photoAction.setValue(image, forKey: "image")
        photoAction.setValue(UIColor.black, forKey: "titleTextColor")
        actionSheet.addAction(photoAction)
        
        let videoAction = UIAlertAction(title: "Video", style: .default) { [weak self] _ in
            self?.presentVideoInputActionsSheet()
        }
        let videoImage = UIImage(systemName: "video")
        videoAction.setValue(videoImage, forKey: "image")
        videoAction.setValue(UIColor.black, forKey: "titleTextColor")
        actionSheet.addAction(videoAction)
        
        let locationAction = UIAlertAction(title: "Location", style: .default) { [weak self] _ in
            self?.presentLocationPicker()
        }
        let locationImage = UIImage(systemName: "mappin.and.ellipse")
        locationAction.setValue(locationImage, forKey: "image")
        locationAction.setValue(UIColor.black, forKey: "titleTextColor")
        actionSheet.addAction(locationAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let cancelImage = UIImage(systemName: "xmark")
        cancelAction.setValue(cancelImage, forKey: "image")
        cancelAction.setValue(UIColor.red, forKey: "titleTextColor")
        actionSheet.addAction(cancelAction)
        
        present(actionSheet, animated: true)
    }
    
    private func presentPhotoInputActionsSheet() {
        let actionSheet = UIAlertController(title: "Attach Photo", message: "Where would you like to attach photo from?", preferredStyle: .actionSheet)
        
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }
        let camImage = UIImage(systemName: "camera.viewfinder")
        cameraAction.setValue(camImage, forKey: "image")
        cameraAction.setValue(UIColor.black, forKey: "titleTextColor")
        actionSheet.addAction(cameraAction)
        
        let photoLibrAction = UIAlertAction(title: "Photo Library", style: .default) { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }
        let photoLibrImg = UIImage(systemName: "photo.stack")
        photoLibrAction.setValue(photoLibrImg, forKey: "image")
        photoLibrAction.setValue(UIColor.black, forKey: "titleTextColor")
        actionSheet.addAction(photoLibrAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let cancelImage = UIImage(systemName: "xmark")
        cancelAction.setValue(cancelImage, forKey: "image")
        cancelAction.setValue(UIColor.red, forKey: "titleTextColor")
        actionSheet.addAction(cancelAction)
        
        present(actionSheet, animated: true)
    }
    
    private func presentVideoInputActionsSheet() {
        let actionSheet = UIAlertController(title: "Attach Video", message: "Where would you like to attach a video from?", preferredStyle: .actionSheet)
        
        let cameraAct = UIAlertAction(title: "Camera", style: .default) { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
            
        }
        let videoCamImg = UIImage(systemName: "camera.viewfinder")
        cameraAct.setValue(videoCamImg, forKey: "image")
        cameraAct.setValue(UIColor.black, forKey: "titleTextColor")
        actionSheet.addAction(cameraAct)
        
        let libraryVideoAction = UIAlertAction(title: "Library", style: .default) { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }
        let videoLibraryImg = UIImage(systemName: "photo.stack")
        libraryVideoAction.setValue(videoLibraryImg, forKey: "image")
        libraryVideoAction.setValue(UIColor.black, forKey: "titleTextColor")
        actionSheet.addAction(libraryVideoAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let cancelImage = UIImage(systemName: "xmark")
        cancelAction.setValue(cancelImage, forKey: "image")
        cancelAction.setValue(UIColor.red, forKey: "titleTextColor")
        actionSheet.addAction(cancelAction)
        
        present(actionSheet, animated: true)
    }
    
    private func presentInputActionSheet(title: String, message: String, actions: [(String, UIAlertAction.Style, UIImage, UIColor, () -> Void)]) {
        let actionSheet = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        
        for (actionTitle, style, image, titleColor, handler) in actions {
            let action = UIAlertAction(title: actionTitle, style: style) { _ in
                handler()
            }
            action.setValue(image, forKey: "image")
            action.setValue(titleColor, forKey: "titleTextColor")
            actionSheet.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let cancelImage = UIImage(systemName: "xmark")
        cancelAction.setValue(cancelImage, forKey: "image")
        cancelAction.setValue(UIColor.red, forKey: "titleTextColor")
        actionSheet.addAction(cancelAction)
        
        present(actionSheet, animated: true)
    }
    
    
    func messageBottomLabelAttributedText(for message: MessageKit.MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        
        let dateString = Util.getStringFromDate(format: "HH:mm dd/MM/YYYY", date: message.sentDate)
        
        let attachment = NSTextAttachment()
        attachment.image = UIImage(named: "notRead")
        
        let currentUserReadInfo = getUserSetting(status: .current, setting: .readReceipt)
        let otherUserReadInfo = getUserSetting(status: .other, setting: .readReceipt)
        
        if let isRead = message.isRead, isRead == true, currentUserReadInfo, otherUserReadInfo {
            UIView.animate(withDuration: 0.2) {
                print(message)
                attachment.image = UIImage(named: "read")
            }
        } else {
            attachment.image = UIImage(named: "notRead")
        }
        
        attachment.bounds = CGRect(x: 0, y: -4, width: 18, height: 18) // İlk sembol

        let attachmentString = NSAttributedString(attachment: attachment)
        
        let font = UIFont(name: "Avenir-Medium", size: 10.0) // Özelleştirilmiş bir font oluşturun veya mevcut bir fontu kullanın
        let dateStringAttributes: [NSAttributedString.Key: Any] = [
            .font: font as Any, // Özelleştirilmiş fontu burada belirtin
        ]

        let dateStringAttributedString = NSAttributedString(string: dateString, attributes: dateStringAttributes)

        let finalString = NSMutableAttributedString()
        let otherFinalString = NSMutableAttributedString()
        
        if message.sender.senderId == selfSender?.senderId {
            finalString.append(dateStringAttributedString)
            finalString.append(NSAttributedString(string: " "))
            finalString.append(attachmentString)
            return finalString
        } else {
            otherFinalString.append(dateStringAttributedString)
            return otherFinalString
        }
        
    }
    
}

extension ChatViewController: MessagesDataSource, MessagesDisplayDelegate, MessagesLayoutDelegate {

    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 17
    }
    
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
        cell.progressView.trackTintColor = .darkGray
        cell.progressView.progressTintColor = .white
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
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        let sender = message.sender
        if sender.senderId == selfSender?.senderId {
            return .link
        }
        
        return .secondarySystemBackground
    }
    
    private func avatarCheck(userEmail: String, userPhotoUrl: URL?, avatarView: AvatarView) {
        if var userPhotoUrlLink = userPhotoUrl {
            avatarView.sd_setImage(with: userPhotoUrl)
        } else {
            let safeEmail = DatabaseManager.safeEmail(emaildAddress: userEmail)
            let path = "images/\(safeEmail)_profile_picture.png"
            StorageManager.shared.downloadUrl(for: path) { result in
                switch result {
                case .success(let url):
                    DispatchQueue.main.async {
                        avatarView.sd_setImage(with: url)
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        
        let sender = message.sender
        
        if sender.senderId == selfSender?.senderId {
            avatarCheck(userEmail: currentSender().senderId, userPhotoUrl: senderUserPhotoURL, avatarView: avatarView)
        } else {
            if getUserSetting(status: .other, setting: .profilePhoto) {
                avatarCheck(userEmail: otherUserEmail, userPhotoUrl: otherUserPhotoURL, avatarView: avatarView)
            
            } else {
                avatarView.image = UIImage(systemName: "person.fill")
            }
        }
    }

}

extension ChatViewController: AVAudioRecorderDelegate, AVAudioPlayerDelegate{}

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
                                          kind: .photo(media), isRead: nil)
                    
                    self?.send(message: message)
                    
                    
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
                                          kind: .video(media), isRead: nil)
                    
                    self?.send(message: message)
                    
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
                     let selfSender = self.selfSender else {
                   return
               }
            let message = Message(sender: selfSender, messageId: createMessageId() ?? "", sentDate: Date(), kind: .text(text), isRead: nil)
               send(message: message)
           } else if isEmptyText {
               // Handle sending audio message
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

extension ChatViewController: MessageCellDelegate {
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        //    let borderColor:UIColor = isFromCurrentSender(message: message) ? .black: .purple
        return .bubbleTail(corner, .curved)
    }
  
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
            navigationController?.pushViewController(vc, animated: true)
            
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
            navigationController?.pushViewController(vc, animated: true)
            
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
