//
//  FriendRequestsController.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 9.12.2023.
//

import UIKit
import JGProgressHUD

class FriendRequestsController: UIViewController {
    
    public var completion: ((SearchResult) -> (Void))?
    
    private let spinner = JGProgressHUD(style: .dark)
    
    var friendshipRequests: [FriendRequest] = []
        
    private var users = [[String: Any]]()
    private var results = [SearchResult]()
    private var hasFetched = false
    
    private var safeEmail: String?
    private var currentUserName: String?
    
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.register(NewConversationCell.self, forCellReuseIdentifier: NewConversationCell.identifier)
        tv.rowHeight = 90
        return tv
    }()
    
    private let noSearchResultsLabel: UILabel = {
        let label = UILabel()
        label.isHidden = true
        label.text = "No results!"
        label.textAlignment = .center
        label.textColor = .red
        label.font = .systemFont(ofSize: 21, weight: .medium)
        return label
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        title = "My friend requests"
        view.addSubview(noSearchResultsLabel)
        view.addSubview(tableView)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        self.view.addGlobalUnsafeAreaView()
        //searchBar.delegate = self
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissSelf))

        guard let currentUser = UserDefaults.standard.value(forKey: "email") as? String,
              let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
            return
        }
        
        safeEmail = DatabaseManager.safeEmail(emaildAddress: currentUser)
        currentUserName = currentName
        fetchingIncomingRequests()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchingIncomingRequests()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        noSearchResultsLabel.frame = CGRect(x: view.width/4,
                                            y: (view.height-200)/2,
                                            width: view.width/2,
                                            height: 200)
    }
    
    private func fetchingIncomingRequests() {
        
        guard let currentUser = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        DatabaseManager.shared.getFriendRequests(forUserEmail: currentUser, type: .incomingRequests) { result in
            switch result {
            case .success(let returnedData):
                self.friendshipRequests = returnedData
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
    
    @objc private func dismissSelf() {
        dismiss(animated: true)
    }
    
    
    func updateUI() {
        
        if results.isEmpty {
            noSearchResultsLabel.isHidden = false
            tableView.isHidden = true
        } else {
            noSearchResultsLabel.isHidden = true
            tableView.isHidden = false
            tableView.reloadData()
        }
    }
}


extension FriendRequestsController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friendshipRequests.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NewConversationCell.identifier, for: indexPath) as! NewConversationCell
        //cell.textLabel?.text = results[indexPath.row].name
        let model = friendshipRequests[indexPath.row]
        cell.selectionStyle = .none
        cell.acceptButtonHandler = {
            let otherUserEmail = model.email
            let otherUsername = model.name
           
            // save to in friends collection
            DatabaseManager.shared.saveToMyFriends(forUserEmail: self.safeEmail ?? "", currentUsername: self.currentUserName ?? "", targetUserEmail: otherUserEmail, targetUsername: otherUsername) { success in
                
                if success {
                    if let index = self.friendshipRequests.firstIndex(where: { $0.email == otherUserEmail }) {
                        
                        self.friendshipRequests.remove(at: index)
                        let indexPath = IndexPath(row: index, section: 0)
                        self.tableView.deleteRows(at: [indexPath], with: .fade)
                        self.tableView.reloadData()
                    }
                }
            }
        }
        
        cell.declineButtonHandler = {
            let otherUserEmail = model.email
           
            DatabaseManager.shared.deleteAndCancelRequest(for: self.safeEmail ?? "", targetUserEmail: otherUserEmail, isDelete: true) { success in
                if success {
                    if let index = self.friendshipRequests.firstIndex(where: { $0.email == otherUserEmail }) {
                        
                        self.friendshipRequests.remove(at: index)
                        let indexPath = IndexPath(row: index, section: 0)
                        self.tableView.deleteRows(at: [indexPath], with: .fade)
                        self.tableView.reloadData()
                    }
                }
            }
        }
        
        cell.configureForFriends(with: model, inController: .friendViewController)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emaildAddress: currentUserEmail)
        
       
        
        let pController = ProfilePageController(currentUserEmail: currentUserEmail, otherUserEmail: friendshipRequests[indexPath.row].email, profileState: .incominRequests)
        self.navigationController?.pushViewController(pController, animated: true)
    }
}


