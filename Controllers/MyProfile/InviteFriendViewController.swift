//
//  InviteFriendViewController.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 6.11.2023.
//

import UIKit

class InviteFriendViewController: UIViewController {
  
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.register(NewConversationCell.self, forCellReuseIdentifier: NewConversationCell.identifier)
        return tv
    }()
    
    var searchText: String?
    
    private var hasFetched = false
    
    var results = [SearchResult]()
    
    private var users = [[String: Any]]()
    
    private var safeEmail: String?
    private var currentUserName: String?
    
    init(searchText: String?) {
        self.searchText = searchText
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addGlobalUnsafeAreaView()
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        view.backgroundColor = UIColor(#colorLiteral(red: 0.9638196826, green: 0.9687927365, blue: 1, alpha: 1))
        tableView.backgroundColor = .clear
        
        guard let currentUser = UserDefaults.standard.value(forKey: "email") as? String,
              let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
            return
        }
        
        
        safeEmail = DatabaseManager.safeEmail(emaildAddress: currentUser)
        currentUserName = currentName
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: view.trailingAnchor)
    }
    
    func searchForUsers(with searchText: String) {
        print("searchusers: \(searchText)")
         if hasFetched {
             filterUser(with: searchText)
         } else {
             DatabaseManager.shared.getAllUnfollowedUsers { [weak self] result in
                 switch result {
                 case .success(let allUsers):
                     self?.hasFetched = true
                     self?.users = allUsers
                 case .failure(let error):
                     print("failed to get users: \(error.localizedDescription)")
                 }
         
             }
        }
    }
    
    func filterUser(with term: String?) {
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String,
              hasFetched else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emaildAddress: currentUserEmail)
        
        let results: [SearchResult] = users.filter {
            guard let email = $0["email"] as? String,
                  email != safeEmail else {
                return false
            }
            
            guard let name = $0["name"] as? String
                 // let isOnline = $0["isOnline"] as? Bool
            else {
                return false
            }
            
          //  guard let lastOnline = $0["lastOnline"] as? String else {
            //    return false
           // }
            
            return name.lowercased().hasPrefix(term?.lowercased() ?? "")
            
        }.compactMap {
            guard let email = $0["email"] as? String,
                  let name = $0["name"] as? String
               //   let isOnline = $0["isOnline"] as? Bool,
               //   let lastOnline = $0["lastOnline"] as? String
            else {
                return nil
            }
            return SearchResult(name: name, email: email/*, isOnline: isOnline, lastOnline: lastOnline*/)
        }
        
        self.results = results
        updateUI()
        
    }
    
    func updateUI() {
        
        if results.isEmpty {
            //noSearchResultsLabel.isHidden = false
            tableView.isHidden = true
        } else {
            //noSearchResultsLabel.isHidden = true
            tableView.isHidden = false
            tableView.reloadData()
        }
    }
    
}

extension InviteFriendViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = results[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: NewConversationCell.identifier, for: indexPath) as! NewConversationCell
        
        cell.configure(with: model, inController: .inviteFriendsController)
        cell.sendRequestButtonHandler = {
            let otherUserEmail = model.email
            
         //aa   DatabaseManager.shared.sendFriendsRequest(currentUser: self.safeEmail ?? "", targetUserEmail: otherUserEmail, completion: )
            DatabaseManager.shared.sendFriendsRequest(currentUserEmail: self.safeEmail ?? "",
                                                      currentUserName: self.currentUserName ?? "",
                                                      targetUserEmail: otherUserEmail) { success, isAlreadySent in
                if success {
                    if let index = self.results.firstIndex(where: { $0.email == otherUserEmail }) {
                        self.results.remove(at: index)
                        // Animate the deletion
                        let indexPath = IndexPath(row: index, section: 0)
                        self.tableView.deleteRows(at: [indexPath], with: .fade)
                        self.tableView.reloadData()
                        //self.updateUI()
                    }
                } else {
                    print("yollanamadı")
                }
            }
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let profileContr = ProfilePageController(currentUserEmail: self.safeEmail ?? "", otherUserEmail: results[indexPath.row].email, profileState: .inviteFriends)
        
        let controller = UINavigationController(rootViewController: profileContr)
        self.present(controller, animated: true)
    }
}

class SearchController: UIViewController, UISearchResultsUpdating, UISearchControllerDelegate {
    
    
    private let searchController = UISearchController(searchResultsController: InviteFriendViewController(searchText: nil))
    
    private var hasFetched = false
    
    lazy var search = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Invite Friend"
        self.view.addGlobalUnsafeAreaView()

        view.backgroundColor = UIColor(#colorLiteral(red: 0.9638196826, green: 0.9687927365, blue: 1, alpha: 1))
        
        let backButton = UIButton(type: .custom)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
        
        let customButton = UIBarButtonItem(customView: backButton)
        backButton.tintColor = .white
        backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        navigationItem.leftBarButtonItem = customButton
        
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        searchController.searchBar.tintColor = #colorLiteral(red: 0.1784554124, green: 0.2450254858, blue: 0.3119192123, alpha: 0.7805301171)
        customizeSearchBar()
        navigationItem.searchController = searchController
    }
    
    private func customizeSearchBar() {
        if let cancelButtonAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white] as? [NSAttributedString.Key: Any] {
            UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes(cancelButtonAttributes, for: .normal)
        }

        if let textField = searchController.searchBar.value(forKey: "searchField") as? UITextField {
            // Arama çubuğu metin rengi
            textField.textColor = #colorLiteral(red: 0.1784554124, green: 0.2450254858, blue: 0.3119192123, alpha: 0.7805301171)
            // Arama çubuğu arka plan rengi
            textField.backgroundColor = UIColor.white.withAlphaComponent(0.8)
            // Arama çubuğu köşe yuvarlama
            textField.layer.cornerRadius = 10
            textField.placeholder = "Search for users"
            textField.layer.borderWidth = 0.3
            textField.layer.borderColor = #colorLiteral(red: 0.1784554124, green: 0.2450254858, blue: 0.3119192123, alpha: 0.7805301171)
            
            if let leftView = textField.leftView as? UIImageView {
                // Sol taraftaki arama ikonunun rengi
                leftView.image = leftView.image?.withRenderingMode(.alwaysTemplate)
                leftView.tintColor = #colorLiteral(red: 0.1784554124, green: 0.2450254858, blue: 0.3119192123, alpha: 0.7805301171)
            }

            if let clearButton = textField.value(forKey: "_clearButton") as? UIButton {
                // Temizleme butonunun rengi
                clearButton.setImage(clearButton.imageView?.image?.withRenderingMode(.alwaysTemplate), for: .normal)
                clearButton.tintColor = #colorLiteral(red: 0.1784554124, green: 0.2450254858, blue: 0.3119192123, alpha: 0.7805301171)
            }
        }
    }
    
    @objc fileprivate func handleBack() {
        tabBarController?.tabBar.isHidden = false
        self.navigationController?.popViewController(animated: true)
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text,
        !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        
        if let inviteFriendVC = searchController.searchResultsController as? InviteFriendViewController {
            inviteFriendVC.searchForUsers(with: text)
        }
    }
    
}
