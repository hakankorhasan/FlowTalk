//
//  ViewController.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 22.08.2023.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

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
        btn.setImage(UIImage(named: "add"), for: .normal)
        return btn
    }()
    
    private var loginObserver: NSObjectProtocol?

    
    override func viewDidLoad() {
        super.viewDidLoad()

        plusButton.addTarget(self, action: #selector(didTapComposeButton), for: .touchUpInside)
        
        view.addSubview(tableView)
        tableView.backgroundColor = .clear
        view.addSubview(noConversationsLabel)
        
        noConversationsLabel.isHidden = true
        setupUI()
        setupTableView()
        startListeningForConversations()
        
        
       
       // tableView.backgroundColor = .clear
        tableView.tableHeaderView = createTableHeader()
        tableView.backgroundColor = .white
        
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

    }
  
    private func setupUI() {
        // Initial setup for image for Large NavBar state since the the screen always has Large NavBar once it gets opened
        self.view.addGlobalUnsafeAreaView()
        
        guard let navigationBar = self.navigationController?.navigationBar else { return }
        navigationBar.addSubview(plusButton)
      //  plusButton.layer.cornerRadius = Const.ImageSizeForLargeState / 2
        plusButton.clipsToBounds = true
        plusButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            plusButton.rightAnchor.constraint(equalTo: navigationBar.rightAnchor,constant: -Const.ImageRightMargin),
            plusButton.bottomAnchor.constraint(equalTo: navigationBar.bottomAnchor, constant: -Const.ImageBottomMarginForLargeState),
            plusButton.heightAnchor.constraint(equalToConstant: Const.ImageSizeForLargeState),
            plusButton.widthAnchor.constraint(equalTo: plusButton.heightAnchor)
                ])
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
            /// This value = 14. It equals to difference of 12 and 6 (bottom margin for large and small states). Also it adds 8.0 (size difference when the image gets smaller size)
            let maxYTranslation = Const.ImageBottomMarginForLargeState - Const.ImageBottomMarginForSmallState + sizeDiff
            return max(0, min(maxYTranslation, (maxYTranslation - coeff * (Const.ImageBottomMarginForSmallState + sizeDiff))))
        }()

        let xTranslation = max(0, sizeDiff - coeff * sizeDiff)

        plusButton.transform = CGAffineTransform.identity
            .scaledBy(x: scale, y: scale)
            .translatedBy(x: xTranslation, y: yTranslation)
       
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
        
        if let cachedConversations = DatabaseManager.shared.getAllConversationsFromCache(for: safeEmail) {
            self.spinner.dismiss()
            self.noConversationsLabel.isHidden = cachedConversations.isEmpty ? false : true
            self.tableView.isHidden = cachedConversations.isEmpty ? true : false
            self.conversations = cachedConversations
            self.tableView.reloadData()
        } else {
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
                    
                    DatabaseManager.shared.saveConversationsToCache(conversations, for: safeEmail)
                    
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
        }
    }
    
    @objc private func didTapComposeButton() {
        let vc = NewConversationsViewController()
        vc.completion = { [weak self] result in
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showImage(true)
       
        validateAuth()
    }
    
    private func setupTableView() {
        if traitCollection.userInterfaceStyle == .light {
           // tableView.backgroundColor = UIColor(red: 0.9590069652, green: 0.9689564109, blue: 1, alpha: 1)
        }
        
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func validateAuth() {
        if FirebaseAuth.Auth.auth().currentUser == nil {
            let loginvc = InitialScreenVC()
            let navControl = UINavigationController(rootViewController: loginvc)
            navControl.modalPresentationStyle = .fullScreen
            present(navControl, animated: true)
        }
    }

}

extension ConversationsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifier, for: indexPath) as! ConversationTableViewCell
        
        if traitCollection.userInterfaceStyle == .dark {
            // Koyu modda background rengini dark gray olarak ayarla
            cell.backgroundColor = UIColor(#colorLiteral(red: 0.1098036841, green: 0.1098041013, blue: 0.1183908954, alpha: 1))
        } else {
            // Parlak modda background rengini belirlediğiniz renk olarak ayarla
            cell.backgroundColor = .white
        }
        cell.clipsToBounds = true
        let model = conversations[indexPath.row]
        
        if Network.reachability.isReachable {
            // İnternet bağlantısı var, fetch işlemini gerçekleştir
            DatabaseManager.shared.fetchUserSettings(safeEmail: model.otherUserEmail, isCurrentUser: false) { [weak self] in
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
