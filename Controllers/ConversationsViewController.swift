//
//  ViewController.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 22.08.2023.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

struct Conversation {
    let id: String
    let name: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
}

struct LatestMessage {
    let date: String
    let isRead: Bool
    let text: String
}

class ConversationsViewController: UIViewController{
    
    private let spinner = JGProgressHUD(style: .dark)
    
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
        label.textColor = .gray
        label.font = .systemFont(ofSize: 21, weight: .medium)
        return label
    }()
    
    private var loginObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(didTapComposeButton))
        
        view.addSubview(tableView)
        setupTableView()
        fetchConversations()
        startListeningForConversations()
        
        loginObserver = NotificationCenter.default.addObserver(forName: Notification.Name.didLogInNotification, object: nil, queue: .main, using: { [weak self] _ in
            guard let strongSelf = self else { return }
            
            strongSelf.startListeningForConversations()
        })
    }
    
    private func startListeningForConversations() {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
    
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        let safeEmail = DatabaseManager.safeEmail(emaildAddress: email)
        
        DatabaseManager.shared.getAllConversations(for: safeEmail) { [weak self] result in
            print(result)
            switch result {
            case .success(let conversations):
                guard !conversations.isEmpty else {
                    print("empty")
                    return
                }
                
                self?.conversations = conversations
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
                
            case .failure(let error):
                print("failed to get convos: \(error)")
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
         tableView.frame = view.bounds
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
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            }
        }
        
        
    }
    
    private func fetchConversations() {
        tableView.isHidden = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        validateAuth()
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func validateAuth() {
        if FirebaseAuth.Auth.auth().currentUser == nil {
            let loginvc = LoginViewController()
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
        
        let model = conversations[indexPath.row]
        
        cell.configure(with: model)
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
        return 120
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
 
        if editingStyle == .delete {
            let actionSheet = UIAlertController(title: "", message: "Are you sure you want to delete messages?", preferredStyle: .alert)
            
            actionSheet.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
                
                let conversationId = self.conversations[indexPath.row].id
                tableView.beginUpdates()
                
                DatabaseManager.shared.deleteConversation(conversationId: conversationId) { [weak self] success in
                    if success {
                        self?.conversations.remove(at: indexPath.row)
                        
                        tableView.deleteRows(at: [indexPath], with: .left)
                        
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
