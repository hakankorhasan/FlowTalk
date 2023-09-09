//
//  NewConversationsViewController.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 22.08.2023.
//

import UIKit

class NewConversationsViewController: UIViewController {
    
    private let searchBar: UISearchBar = {
       let sb = UISearchBar()
        sb.placeholder = "Search for users..."
        return sb
    }()
    
    private let tableView: UITableView = {
      let tv = UITableView()
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
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

        searchBar.delegate = self
        view.backgroundColor = .white
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissSelf))
        
        //bu ekran açılır açılmaz search bar'a tekrar dokunmaya gerek kalmadan arama yapmayı sağlar.
        searchBar.becomeFirstResponder()
    }
    
    @objc private func dismissSelf() {
        dismiss(animated: true)
    }
    
}

extension NewConversationsViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
    }
}
