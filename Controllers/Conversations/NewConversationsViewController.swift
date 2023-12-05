//
//  NewConversationsViewController.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 22.08.2023.
//

import UIKit
import JGProgressHUD

final class NewConversationsViewController: UIViewController {
    
    public var completion: ((SearchResult) -> (Void))?
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private var users = [[String: Any]]()
    private var results = [SearchResult]()
    private var hasFetched = false
    
    private let searchBar: UISearchBar = {
       let sb = UISearchBar()
        sb.placeholder = "Search for users..."
        return sb
    }()
    
    private let tableView: UITableView = {
      let tv = UITableView()
        tv.register(NewConversationCell.self, forCellReuseIdentifier: NewConversationCell.identifier)
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
        
        tableView.delegate = self
        tableView.dataSource = self
        self.view.addGlobalUnsafeAreaView()

        searchBar.delegate = self
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissSelf))
        
        //bu ekran açılır açılmaz search bar'a tekrar dokunmaya gerek kalmadan arama yapmayı sağlar.
        searchBar.becomeFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        noSearchResultsLabel.frame = CGRect(x: view.width/4,
                                            y: (view.height-200)/2,
                                            width: view.width/2,
                                            height: 200)
    }
    
    @objc private func dismissSelf() {
        dismiss(animated: true)
    }
    
}

extension NewConversationsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let model = results[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: NewConversationCell.identifier, for: indexPath) as! NewConversationCell
        //cell.textLabel?.text = results[indexPath.row].name
        cell.configure(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        // start conversation
        let targetUserData = results[indexPath.row]
        
        dismiss(animated: true) { [weak self] in
            self?.completion?(targetUserData)
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
        
        results.removeAll()
        
        spinner.show(in: view)
        searchUsers(query: text)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            results.removeAll()
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
            DatabaseManager.shared.getAllUsers { [weak self] result in
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

            guard let name = $0["name"] as? String, let isOnline = $0["isOnline"] as? Bool else {
                return false
            }
            
            guard let isOnline = $0["isOnline"] else { return false }
            
            guard let lastOnline = $0["lastOnline"] as? String else { return false }
            
            return name.lowercased().hasPrefix(term.lowercased())
        }.compactMap {
            
            guard let email = $0["email"] as? String, email != safeEmail,
                  let name = $0["name"] as? String,
                  let isOnline = $0["isOnline"] as? Bool,
                  let lastOnline = $0["lastOnline"] as? String else {
                return nil
            }
            //let isOnlineString = isOnline ? "true" : "false"
           // let isOnlineBool = isOnline.lowercased() == "true"
            return SearchResult(name: name, email: email, isOnline: isOnline, lastOnline: lastOnline)
        }
        self.results = results
        
        updateUI()
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
