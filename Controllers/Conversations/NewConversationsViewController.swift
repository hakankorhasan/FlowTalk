//
//  NewConversationsViewController.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 22.08.2023.
//

import UIKit
import JGProgressHUD

final class NewConversationsViewController: UIViewController {
    
    public var completionForSearch: ((SearchResult) -> (Void))?
    public var completionForFriends: ((FriendRequest) -> (Void))?
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private var users = [[String: Any]]()
    
    private var resultsSearch = [SearchResult]()
    
    private var resultsFriends = [FriendRequest]()
    
    private var hasFetched = false
    
    let segmentedControl: UISegmentedControl = {
       let sc = UISegmentedControl(items: ["My Friends", "Search"])
        sc.selectedSegmentIndex = 0
        sc.selectedSegmentTintColor = .white
        sc.backgroundColor = #colorLiteral(red: 0.1784554124, green: 0.2450254858, blue: 0.3119192123, alpha: 0.7805301171)
        sc.constrainHeight(constant: 40)
        sc.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
        sc.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor(#colorLiteral(red: 0.1784554124, green: 0.2450254858, blue: 0.3119192123, alpha: 0.7805301171))] , for: UIControl.State.selected)
        return sc
    }()
    
    private let searchBar: UISearchBar = {
       let sb = UISearchBar()
        sb.placeholder = "Search for users..."
        sb.searchTextField.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        sb.searchTextField.layer.cornerRadius = 10
        sb.searchTextField.tintColor = .black
        return sb
    }()
    
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

        view.addSubview(noSearchResultsLabel)
        view.addSubview(tableView)
        navigationItem.title = "My Friends"
        tableView.delegate = self
        tableView.dataSource = self
        segmentedControl.constrainWidth(constant: view.width)
        
        let padding: CGFloat = 16.0
        segmentedControl.constrainWidth(constant: view.width - 2 * padding)
        tableView.tableHeaderView = segmentedControl
        segmentedControl.centerXAnchor.constraint(equalTo: tableView.centerXAnchor).isActive = true
        segmentedControl.topAnchor.constraint(equalTo: tableView.topAnchor).isActive = true
        
        segmentedControl.addTarget(self, action: #selector(segmentCOntrolValueChanged), for: .valueChanged)

        self.view.addGlobalUnsafeAreaView()

        searchBar.delegate = self
        view.backgroundColor = .systemBackground
       // navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissSelf))
        fetchForSegmentFirst()
        //bu ekran açılır açılmaz search bar'a tekrar dokunmaya gerek kalmadan arama yapmayı sağlar.
        //searchBar.becomeFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        noSearchResultsLabel.frame = CGRect(x: view.width/4,
                                            y: (view.height-200)/2,
                                            width: view.width/2,
                                            height: 200)
    }
    
    @objc private func segmentCOntrolValueChanged() {
        if segmentedControl.selectedSegmentIndex == 0 {
            hidesSearchBar()
            self.resultsSearch = []
            self.fetchForSegmentFirst()
            // fetch my friends from database
            searchBar.text = ""
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            
            
        } else {
            DispatchQueue.main.async {
                self.resultsFriends = []
                self.tableView.reloadData()
            }
            
            showSearchBar()
        }
    }
    
    private func showSearchBar() {
        navigationController?.navigationBar.topItem?.titleView = searchBar
        searchBar.becomeFirstResponder()
    }
    
    private func hidesSearchBar() {
        navigationItem.titleView = nil
        navigationItem.title = "My Friends"
        searchBar.resignFirstResponder()
    }
    
    @objc private func dismissSelf() {
        dismiss(animated: true)
    }
    
    private func fetchForSegmentFirst() {
        DatabaseManager.shared.fetchMyFriends { result in
            switch result {
            case .success(let userFriendsData):
                // Arkadaşları results dizisine ekle
                       self.resultsFriends += userFriendsData.compactMap { friendData in
                           guard let name = friendData["name"] as? String,
                                 let email = friendData["email"] as? String else {
                               print("nill")
                               return nil
                           }
                           return FriendRequest(email: email, name: name)
                       }
                       
                       // Tabloyu güncelle
                       self.updateUI()
                
            case .failure(let failure):
                print("failure \(failure)")
            }
        }
    }
    
}

extension NewConversationsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if segmentedControl.selectedSegmentIndex == 0 {
            return resultsFriends.count
        } else {
            return resultsSearch.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if segmentedControl.selectedSegmentIndex == 0
        {
            let model = resultsFriends[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: NewConversationCell.identifier, for: indexPath) as! NewConversationCell
            cell.selectionStyle = .none
            cell.messageButtonHandler = {
                self.messageButton(tableView, selectedRow: indexPath)
            }
            //cell.textLabel?.text = results[indexPath.row].name
            cell.configureForFriends(with: model, inController: .newConversationController)
            return cell
        }
        else
        {
            let model = resultsSearch[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: NewConversationCell.identifier, for: indexPath) as! NewConversationCell
            cell.selectionStyle = .none
            //cell.textLabel?.text = results[indexPath.row].name
            cell.messageButtonHandler = {
                self.messageButton(tableView, selectedRow: indexPath)
            }
            cell.configure(with: model, inController: .newConversationController)
            return cell
        }

    }
    
    func messageButton(_ tableView: UITableView, selectedRow indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // start conversation
        if segmentedControl.selectedSegmentIndex == 0
        {
            let targetUserData = resultsFriends[indexPath.row]
            
            dismiss(animated: true) { [weak self] in
                self?.completionForFriends?(targetUserData)
            }
        }
        else
        {
            let targetUserData = resultsSearch[indexPath.row]
            
            dismiss(animated: true) { [weak self] in
                self?.completionForSearch?(targetUserData)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
       
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emaildAddress: currentUserEmail)
        
        if segmentedControl.selectedSegmentIndex == 0 {
            
            let profileContr = ProfilePageController(currentUserEmail: safeEmail, otherUserEmail: resultsFriends[indexPath.row].email, profileState: .alreadyFriends)
            self.navigationController?.pushViewController(profileContr, animated: true)
            
        } else {
            
            let profileContr = ProfilePageController(currentUserEmail: safeEmail, otherUserEmail: resultsSearch[indexPath.row].email, profileState: .alreadyFriends)
            self.navigationController?.pushViewController(profileContr, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
}

extension NewConversationsViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        
        searchBar.resignFirstResponder()
        
        resultsSearch.removeAll()
        
        spinner.show(in: view)
        searchUsers(query: text)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            resultsSearch.removeAll()
            tableView.reloadData()
            noSearchResultsLabel.isHidden = true
            // Arama çubuğundaki metni temizle (isteğe bağlı)
        }
    }
    
    
    func searchUsers(query: String) {
        // check if array has firebase results
        if hasFetched {
            // if it does: filter
            filterUsers(with: query)
        } else {
            // if not, fetch then filter
            DatabaseManager.shared.getAllFriends { [weak self] result in
                switch result {
                case .success(let allUsers):
                    self?.hasFetched = true
                    self?.users = allUsers
                    self?.filterUsers(with: query)
                case .failure(let error):
                    print("failed to get users: \(error.localizedDescription)")
                }
            }
        }
        
        // update the UI: either show results or show no results label
    }
    
    func filterUsers(with term: String) {
        
        // kullanıcı ararken kendi hesabının çıkmasını engelledik
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String, hasFetched else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emaildAddress: currentUserEmail)
        
        self.spinner.dismiss()
        
        let results: [SearchResult] = users.filter {
            
            guard let email = $0["email"] as? String, email != safeEmail else {
                return false
            }

            guard let name = $0["name"] as? String else {
                return false
            }
            
            return name.lowercased().hasPrefix(term.lowercased())
        }.compactMap {
            
            guard let email = $0["email"] as? String, email != safeEmail,
                  let name = $0["name"] as? String else {
                return nil
            }
            
            return SearchResult(name: name, email: email)
            
        }
        
        self.resultsSearch = results
        
        updateUI()
    }
    
    func updateUI() {
        
        if segmentedControl.selectedSegmentIndex == 0
        {
            if resultsFriends.isEmpty {
                noSearchResultsLabel.isHidden = false
                tableView.isHidden = true
            } else {
                noSearchResultsLabel.isHidden = true
                tableView.isHidden = false
                tableView.reloadData()
            }
        }
        else
        {
            if resultsSearch.isEmpty {
                noSearchResultsLabel.isHidden = false
                tableView.isHidden = true
            } else {
                noSearchResultsLabel.isHidden = true
                tableView.isHidden = false
                tableView.reloadData()
            }
        }
       
    }
}
