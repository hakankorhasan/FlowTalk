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
        return tv
    }()
        
    var results = [SearchResult]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addGlobalUnsafeAreaView()
        view.backgroundColor = UIColor(#colorLiteral(red: 0.9638196826, green: 0.9687927365, blue: 1, alpha: 1))
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
      //  tableView.frame = view.bounds
    }
    
}

class SearchController: UIViewController, UISearchResultsUpdating, UISearchControllerDelegate {
    
    let searchController = UISearchController(searchResultsController: InviteFriendViewController())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Invite Friend"
        self.view.addGlobalUnsafeAreaView()

        view.backgroundColor = UIColor(#colorLiteral(red: 0.9638196826, green: 0.9687927365, blue: 1, alpha: 1))
        
        let backButton = UIButton(type: .custom)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)

        let customButton = UIBarButtonItem(customView: backButton)
        backButton.tintColor = .black
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
        guard let text = searchController.searchBar.text else {
            return
        }
    }
}
