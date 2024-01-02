//
//  ViewController.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 22.08.2023.
//

import UIKit
import FirebaseAuth
import JGProgressHUD
import FirebaseDatabase

/// Controller that show list of conversations
final class ConversationsViewController: UIViewController, UIScrollViewDelegate {
    
    private let spinner = JGProgressHUD(style: .light)
    
    private var conversations = [Conversation]()
    
    private let tableView: UITableView = {
       let tv = UITableView()
        tv.isHidden = true
        tv.register(ConversationTableViewCell.self, forCellReuseIdentifier: ConversationTableViewCell.identifier)
        return tv
    }()

    
    private let noConversationsLabel: UILabel = {
       let label = UILabel()
        label.text = "No Conversations!"
        label.textAlignment = .center
        label.textColor = .red
        label.font = .systemFont(ofSize: 21, weight: .medium)
        return label
    }()
    
    private let plusButton: UIButton = {
       let btn = UIButton()
        btn.setImage(UIImage(named: "newmsg"), for: .normal)
        return btn
    }()
    
    private let notificationButton: UIButton = {
        let notBtn = UIButton()
        notBtn.setImage(UIImage(named: "notification-bell-3"), for: .normal)
        return notBtn
    }()
    
    private var loginObserver: NSObjectProtocol?
    
    private var conversationPath = ""

    private var ref: DatabaseReference!
    var handle: UInt!
    var updateHandler: UInt!

    private let notificationCountLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        plusButton.addTarget(self, action: #selector(didTapComposeButton), for: .touchUpInside)
        
        view.addSubview(tableView)
        view.addSubview(noConversationsLabel)
        
        noConversationsLabel.isHidden = true
        
        setupUI()
        setupTableView()
        
        startListeningForConversations()
        
        fetchingIncomingRequests()
        
        loginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotification, object: nil, queue: .main, using: { [weak self] _ in
            guard let strongSelf = self else {
                return
            }

            strongSelf.startListeningForConversations()
        })
        
        NotificationCenter.default
                    .addObserver(self,
                                 selector: #selector(statusManager),
                                 name: .flagsChanged,
                                 object: nil)
        updateUserInterface()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.anchor(
            top: view.safeAreaLayoutGuide.topAnchor,
            leading: view.leadingAnchor,
            bottom: view.superview?.bottomAnchor,
            trailing: view.trailingAnchor
        )
        
        // Update the frame for noConversationsLabel
        noConversationsLabel.frame = CGRect(x: 10, y: (view.height-20)/2, width: view
            .width - 20, height: 100)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        startListeningForConversations()
        fetchingIncomingRequests()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showImage(true)
        validateAuth()
    }
    
    private func setupTableView() {
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.tableHeaderView = createTableHeader()
    }
    
    private func fetchingIncomingRequests() {
        
        guard let currentUser = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        DatabaseManager.shared.getFriendRequests(forUserEmail: currentUser, type: .incomingRequests) { result in
            switch result {
            case .success(let returnedData):
                self.notificationCountLabel.text = "\(returnedData.count)"
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    
                }
            case .failure(let failure):
                print("fetching error: \(failure)")
            case .none:
                print("none value")
            }
        }
    }
    
    func updateUserInterface() {
        print("Reachability Summary")
        print("Status:", Network.reachability.status)
        print("HostName:", Network.reachability.hostname ?? "nil")
        print("Reachable:", Network.reachability.isReachable)
        print("Wifi:", Network.reachability.isReachableViaWiFi)
    }
    
    @objc func statusManager(_ notification: Notification) {
        updateUserInterface()
    }
    
    public func createTableHeader() -> UIView? {
        let headerFrame = UIView(frame: CGRect(x: 0, y: 0, width: self.view.width, height: 40))
        headerFrame.backgroundColor = #colorLiteral(red: 0.1784554124, green: 0.2450254858, blue: 0.3119192123, alpha: 0.7805301171)
        let header = UIView()
        
        headerFrame.addSubview(header)
        header.anchor(top: headerFrame.topAnchor, leading: headerFrame.leadingAnchor, bottom: headerFrame.bottomAnchor, trailing: headerFrame.trailingAnchor)
        header.backgroundColor = .white
        header.layer.cornerRadius = 24
        header.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return headerFrame
    }
    
    private func moveAndResizeImage(for height: CGFloat) {
       
        let coeff: CGFloat = {
            let delta = height - Const.NavBarHeightSmallState
            let heightDifferenceBetweenStates = (Const.NavBarHeightLargeState - Const.NavBarHeightSmallState)
           
            return delta / heightDifferenceBetweenStates
        }()

        
        let factor = Const.ImageSizeForSmallState / Const.ImageSizeForLargeState

        let scale: CGFloat = {
            let sizeAddendumFactor = coeff * (1.0 - factor)
            return min(1.0, sizeAddendumFactor + factor)
        }()

        // Value of difference between icons for large and small states
        let sizeDiff = Const.ImageSizeForLargeState * (1.0 - factor) // 8.0
        let yTranslation: CGFloat = {
            
            let maxYTranslation = Const.ImageBottomMarginForLargeState - Const.ImageBottomMarginForSmallState + sizeDiff
            return max(0, min(maxYTranslation, (maxYTranslation - coeff * (Const.ImageBottomMarginForSmallState + sizeDiff))))
        }()

        let xTranslation = max(0, sizeDiff - coeff * sizeDiff)

        plusButton.transform = CGAffineTransform.identity
            .scaledBy(x: scale, y: scale)
            .translatedBy(x: xTranslation, y: yTranslation)
        
        notificationButton.transform = CGAffineTransform.identity.scaledBy(x: scale, y: scale).translatedBy(x: xTranslation, y: yTranslation)
       
    }
    
    private func startListeningForConversations() {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
    
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        print("starting conversation fetch...")
        let safeEmail = DatabaseManager.safeEmail(emaildAddress: email)
        
        spinner.show(in: view)
        
     
        
            DatabaseManager.shared.getAllConversations(for: safeEmail) { [weak self] result in
                print(result)
                switch result {
                case .success(let conversations):
                    print("successfully got conversation models")
                    guard !conversations.isEmpty else {
                        self?.tableView.isHidden = true
                        self?.noConversationsLabel.isHidden = false
                        return
                    }
                    
                    self?.spinner.dismiss()
                    self?.noConversationsLabel.isHidden = true
                    self?.tableView.isHidden = false
                    self?.conversations = conversations
                    
                    
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
                    }
                    
                case .failure(let error):
                    self?.spinner.dismiss()
                    self?.tableView.isHidden = true
                    self?.noConversationsLabel.isHidden = false
                    print("failed to get convos: \(error)")
                }
            }
      
        
        
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let height = navigationController?.navigationBar.frame.height else { return }
        let minHeight: CGFloat = 96.3
        let heightDifference = max(height - minHeight, 0)
        print("heigh", height)
        
        moveAndResizeImage(for: height)

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        showImage(false)
    }

    /// Show or hide the image from NavBar while going to next screen or back to initial screen
    ///
    /// - Parameter show: show or hide the image from NavBar
    private func showImage(_ show: Bool) {
        UIView.animate(withDuration: 0.2) {
            self.plusButton.alpha = show ? 1.0 : 0.0
            self.notificationButton.alpha = show ? 1.0 : 0.0
        }
    }
    
    @objc private func didTapComposeButton() {
        let vc = NewConversationsViewController()
        vc.completionForSearch = { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            
            let currentConversations = strongSelf.conversations
            
            if let targetConversations = currentConversations.first(where: {
                $0.otherUserEmail == DatabaseManager.safeEmail(emaildAddress: result.email)
            }) {
                let vc = ChatViewController(with: targetConversations.otherUserEmail, id: targetConversations.id)
                vc.isNewConversation = false
                vc.title = targetConversations.name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            } else {
                strongSelf.createNewConversation(result: result)
            }
    
        }
        
        vc.completionForFriends = { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            
            let currentConversations = strongSelf.conversations
            
            if let targetConversations = currentConversations.first(where: {
                $0.otherUserEmail == DatabaseManager.safeEmail(emaildAddress: result.email)
            }) {
                let vc = ChatViewController(with: targetConversations.otherUserEmail, id: targetConversations.id)
                vc.isNewConversation = false
                vc.title = targetConversations.name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            } else {
                strongSelf.createNewConversationFriend(result: result)
            }
    
        }
        
        
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true)
    }
    
    
    private func createNewConversation(result: SearchResult) {
        
        let name = result.name
        let email = DatabaseManager.safeEmail(emaildAddress: result.email)
        
        DatabaseManager.shared.conversationExists(iwth: email) { [weak self] results in
            guard let strongSelf = self else {
                return
            }
            
            switch results {
            case .success(let conversationId):
                let vc = ChatViewController(with: email, id: conversationId)
                vc.isNewConversation = false
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            case .failure(_):
                let vc = ChatViewController(with: email, id: "")
                vc.isNewConversation = true
                vc.title = name
                vc.navigationController?.navigationBar.prefersLargeTitles = true
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            }
        }
        
        
    }
    
    private func createNewConversationFriend(result: FriendRequest) {
        
        let name = result.name
        let email = DatabaseManager.safeEmail(emaildAddress: result.email)
        
        DatabaseManager.shared.conversationExists(iwth: email) { [weak self] results in
            guard let strongSelf = self else {
                return
            }
            
            switch results {
            case .success(let conversationId):
                let vc = ChatViewController(with: email, id: conversationId)
                vc.isNewConversation = false
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            case .failure(_):
                let vc = ChatViewController(with: email, id: "")
                vc.isNewConversation = true
                vc.title = name
                vc.navigationController?.navigationBar.prefersLargeTitles = true
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            }
        }
        
    }
    
    
    private func validateAuth() {
        if FirebaseAuth.Auth.auth().currentUser == nil {
            let loginvc = InitialScreenVC()
            let navControl = UINavigationController(rootViewController: loginvc)
            navControl.modalPresentationStyle = .fullScreen
            present(navControl, animated: true)
        }
    }
    
    @objc fileprivate func friendsRequests() {
        let vc = FriendRequestsController()
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true)
    }

}

extension ConversationsViewController {
    
    private func setupUI() {
        // Initial setup for image for Large NavBar state since the the screen always has Large NavBar once it gets opened
        self.view.addGlobalUnsafeAreaView()
        
        guard let navigationBar = self.navigationController?.navigationBar else { return }
        navigationBar.addSubview(plusButton)
        navigationBar.addSubview(notificationButton)
        
        plusButton.clipsToBounds = true
        plusButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            plusButton.rightAnchor.constraint(equalTo: navigationBar.rightAnchor,constant: -Const.ImageRightMargin),
            plusButton.bottomAnchor.constraint(equalTo: navigationBar.bottomAnchor, constant: -Const.ImageBottomMarginForLargeState),
            plusButton.heightAnchor.constraint(equalToConstant: Const.ImageSizeForLargeState*1.2),
            plusButton.widthAnchor.constraint(equalTo: plusButton.heightAnchor)
                ])
        
        notificationButton.clipsToBounds = true
        notificationButton.translatesAutoresizingMaskIntoConstraints = true
        notificationButton.anchor(top: nil, leading: nil, bottom: navigationBar.bottomAnchor, trailing: plusButton.leadingAnchor, padding: .init(top: 0, left: 0, bottom: Const.ImageBottomMarginForLargeState, right: Const.ImageRightMargin))
        notificationButton.heightAnchor.constraint(equalToConstant: Const.ImageSizeForLargeState*1.2).isActive = true
        notificationButton.widthAnchor.constraint(equalTo: notificationButton.heightAnchor).isActive = true
        notificationButton.addTarget(self, action: #selector(friendsRequests), for: .touchUpInside)
        
        notificationCountLabel.backgroundColor = UIColor(#colorLiteral(red: 0.3739683032, green: 0.6619769931, blue: 0.0885688886, alpha: 1))//.black
        notificationCountLabel.textColor = .black
        notificationCountLabel.textAlignment = .center
        notificationCountLabel.font = .systemFont(ofSize: 12, weight: .heavy)
        notificationCountLabel.clipsToBounds = true
        notificationCountLabel.layer.cornerRadius = 8
        notificationButton.addSubview(notificationCountLabel)
        notificationCountLabel.anchor(top: notificationButton.topAnchor, leading: nil, bottom: nil, trailing: notificationButton.trailingAnchor, padding: .init(top: 6, left: 0, bottom: 0, right: 6), size: .init(width: 17, height: 17))
        
    }
    
    func setupOnlineState(otherUserEmail: String, cell: ConversationTableViewCell) {
        let otherUserEm = otherUserEmail
        let otherUserSafeEmail = DatabaseManager.safeEmail(emaildAddress: otherUserEm)
       
        let usersRef = Database.database().reference().child("users")
            
        ref = usersRef
            
        let handleChildAdded: (DataSnapshot) -> Void = { snapshot in
            self.handleSnapshot(snapshot, otherUserEmail: otherUserEmail, cell: cell)
        }
            
        let handleChildChanged: (DataSnapshot) -> Void = { snapshot in
            self.handleSnapshot(snapshot, otherUserEmail: otherUserEmail, cell: cell)
        }
            
        handle = ref.observe(.childAdded, with: handleChildAdded)
        updateHandler = ref.observe(.childChanged, with: handleChildChanged)
       
    }
    
    func handleSnapshot(_ snapshot: DataSnapshot, otherUserEmail: String, cell: ConversationTableViewCell) {
        if let userData = snapshot.value as? [String: Any], let email = userData["email"] as? String {
            if email == otherUserEmail {
                if let isOnline = userData["isOnline"] as? Bool {
                    self.isOnlineCheck(isOnline: isOnline, cell: cell)
                }
            }
        }
    }
    
    func unreadedMessageCount(converId: String, otherUserEmail: String, cell: ConversationTableViewCell) {
        
        let otherUserSafeEmail = DatabaseManager.safeEmail(emaildAddress: otherUserEmail)
       
        let messagePath = converId
        
        let messageRef = Database.database().reference().child(messagePath).child("messages")
        
        messageRef.observeSingleEvent(of: .value) { snapshot in
            
            if let messagesData = snapshot.value as? [[String: Any]] {
                var unreadMsgCount = 0
                for messagesData in messagesData {
                    
                    if let messageSenderEmail = messagesData["sender_email"] as? String,
                       let isMessageRead = messagesData["is_read"] as? Bool,
                       messageSenderEmail == otherUserSafeEmail,
                       isMessageRead == false  {
                        unreadMsgCount += 1
                    }
                }
                
                if unreadMsgCount == 0 {
                    cell.unreadedMessageButton.isHidden = true
                } else {
                    cell.unreadedMessageButton.isHidden = false
                    cell.unreadedMessageButton.setTitle(String(unreadMsgCount), for: .normal)
                }
                print("unreaded message count \(unreadMsgCount)")
            }
            
           
        }
    }
    
    private func isOnlineCheck(isOnline: Bool, cell: ConversationTableViewCell) {
        
         if isOnline {
             UIView.animate(withDuration: 0.2) {
                // self.onlineDotView.backgroundColor = .green
                 cell.onlineInfoButton.backgroundColor = #colorLiteral(red: 0, green: 0.9388161302, blue: 0, alpha: 1)
             }
         } else {
             UIView.animate(withDuration: 0.2) {
                 cell.onlineInfoButton.backgroundColor = .gray
             }
         }
        
    }
    

}

extension ConversationsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifier, for: indexPath) as! ConversationTableViewCell
        
        cell.backgroundColor = .white
        cell.clipsToBounds = true
        
        let model = conversations[indexPath.row]
        setupOnlineState(otherUserEmail: model.otherUserEmail, cell: cell)
        unreadedMessageCount(converId: model.id, otherUserEmail: model.otherUserEmail, cell: cell)
        
        if Network.reachability.isReachable {
            // İnternet bağlantısı var, fetch işlemini gerçekleştir
            DatabaseManager.shared.fetchUserSettings(safeEmail: model.otherUserEmail, isCurrentUser: false) { 
                // closure içinde self'i weak olarak tanımlamak önemlidir, bu şekilde retain cycle'ı önlemiş olursunuz
                cell.configure(with: model)
            }
        } else {
            // İnternet bağlantısı yok, sadece cell'i yapılandır
            cell.configure(with: model)
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = conversations[indexPath.row]
        openConversations(model)
    }
    
    func openConversations(_ model: Conversation) {
        let vc = ChatViewController(with: model.otherUserEmail, id: model.id)
        vc.title = model.name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 115
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
 
        if editingStyle == .delete {
            let actionSheet = UIAlertController(title: "", message: "Are you sure you want to delete messages?", preferredStyle: .alert)
            
            actionSheet.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [weak self] _ in
                
                guard let strongSelf = self else {
                    return
                }
                
                let conversationId = strongSelf.conversations[indexPath.row].id
                tableView.beginUpdates()
                strongSelf.conversations.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .left)
                DatabaseManager.shared.deleteConversation(conversationId: conversationId) {  success in
                    if !success {
                        print("failed to delete")
                    }
                }
                
                
                tableView.endUpdates()
            }))
            
            actionSheet.addAction(UIAlertAction(title: "No", style: .cancel, handler: { _ in
                 
            }))
            present(actionSheet, animated: true)
        }
        
        
    }
    
}

extension UIView {
    
   func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
    
}
