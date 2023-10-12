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
 
final class ChatViewController: MessagesViewController {
    
    private var senderUserPhotoURL: URL?
    private var otherUserPhotoURL: URL?
    
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
    
    var longPressGesture: UILongPressGestureRecognizer!
    var audioFileName = ""
    var audioDuration: Date!
    
    public lazy var audioController = BasicAudioController(messageCollectionView: messagesCollectionView)
   
    public var isEmptyText: Bool = true
    
    public let otherUserEmail: String
    public var conversationId: String?
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

        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        navigationItem.hidesBackButton = true
        
        navBarSetupUI()
        configureGestureRecognizer()
        setupInputButton()
        setupTrashAnimation()
        
    }
    
    private func navBarSetupUI() {
        let backButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .done, target: self, action: #selector(handleBack))
        
        navigationItem.leftBarButtonItem = backButtonItem
        
        // Yeşil online nokta görünümünü oluşturun ve özelleştirin
        let onlineDotView = UIView()
        onlineDotView.backgroundColor = .green
        onlineDotView.layer.cornerRadius = 5 // 5 birimlik yarıçap, yani yuvarlak bir görünüm
        onlineDotView.layer.masksToBounds = true // Köşeleri kesecek şekilde sınırları sınırlandır
        onlineDotView.translatesAutoresizingMaskIntoConstraints = false
        onlineDotView.widthAnchor.constraint(equalToConstant: 10).isActive = true // Genişlik belirle
        onlineDotView.heightAnchor.constraint(equalToConstant: 10).isActive = true // Yükseklik belirle
        
        let onlineLabel = UILabel()
        onlineLabel.text = "Online"
        onlineLabel.font = .systemFont(ofSize: 12, weight: .regular)
        
        if let otherUserPhotoURL = self.otherUserPhotoURL {
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
                        self?.userImageView.sd_setImage(with: url)
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
        
        userImageView.layer.cornerRadius = Const.ImageSizeForLargeState / 2
        userImageView.clipsToBounds = true
        userImageView.translatesAutoresizingMaskIntoConstraints = false
        userImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        userImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        
        userNameLabel.text = title
        
        let stackViewOnline = UIStackView(arrangedSubviews: [onlineDotView, onlineLabel])
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
        
        let stackView = UIStackView(arrangedSubviews: [horizontalStackView, UIView()])
        stackView.distribution = .fillEqually
        stackView.alignment = .center
       
        // Özel bir boşluk ekleyerek backButton'un sağında 20 birimlik boşluk bırakabiliriz.
        let spacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        spacer.width = 10

        navigationItem.leftBarButtonItems = [spacer, backButtonItem]
        
        navigationItem.titleView = stackView
        
    }
    
    @objc private func handleBack() {
        self.navigationController?.popViewController(animated: true)
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
            startRecording(audiofilename: audioFileName)
        
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
                
                stopRecording()
                
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
                longPressGesture.isEnabled = true
            }
            
        default:
            break
        }
    }
    
    func handleSwipeGesture() {
        
        stopRecording()
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
            deleteAudioFileWithName(audioFileName)
            audioFileName = ""
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
        let height: CGFloat = 100 //whatever height you want to add to the existing height
            let bounds = self.navigationController!.navigationBar.bounds
            self.navigationController?.navigationBar.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height + height)
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
                        let mewConversationId = "conversation_\(message.messageId)"
                        self?.conversationId = mewConversationId
                        self?.listeningForMessages(id: mewConversationId, shouldScrollToBottom: true)
                        self?.messageInputBar.inputTextView.text = nil
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
                DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: otherUserEmail, name: name, newMessage: message) { [weak self] success in
                    if success {
                        self?.messageInputBar.inputTextView.text = nil
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
            //mesajı gönderenin mesaj balonunun rengi
            return .link
        }
        
        // mesajı alanın mesaj balonunun rengi
        return .secondarySystemBackground
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        
        let sender = message.sender
        
        if sender.senderId == selfSender?.senderId {
           // put avatarview sender user image
            if let currentUserPhotoURL = self.senderUserPhotoURL {
                avatarView.sd_setImage(with: currentUserPhotoURL)
            } else {
                guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
                    return
                }
                
                let safeEmail = DatabaseManager.safeEmail(emaildAddress: email)
                let path = "images/\(safeEmail)_profile_picture.png"
                StorageManager.shared.downloadUrl(for: path) { [weak self] result in
                    switch result {
                    case .success(let url):
                        DispatchQueue.main.async {
                            // tekrar tekrar indirme yapmaması için böyle bir yapı kullandık
                            self?.senderUserPhotoURL = url
                            avatarView.sd_setImage(with: url)
                        }
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }
            }
        } else {
            // put avatarview sender user image
             if let otherUserPhotoURL = self.otherUserPhotoURL {
                 avatarView.sd_setImage(with: otherUserPhotoURL)
             } else {
                 
                 let email = self.otherUserEmail
                 let safeEmail = DatabaseManager.safeEmail(emaildAddress: email)
                 let path = "images/\(safeEmail)_profile_picture.png"
                 StorageManager.shared.downloadUrl(for: path) { [weak self] result in
                     switch result {
                     case .success(let url):
                         DispatchQueue.main.async {
                             self?.otherUserPhotoURL = url
                             avatarView.sd_setImage(with: url)
                         }
                     case .failure(let error):
                         print(error.localizedDescription)
                     }
                 }
             }
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
