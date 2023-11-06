//
//  EditProfileViewController.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 6.11.2023.
//

import UIKit

class EditProfileViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Edit Profile"
        // Özel bir düğme oluşturun
        let backButton = UIButton(type: .custom)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0) // Sol padding ayarlamak için

        // Düğmeye bir eylem ekleyin
        backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)

        // Özel bir bar button oluşturun
        let customBackButton = UIBarButtonItem(customView: backButton)
        backButton.tintColor = .black
        navigationItem.largeTitleDisplayMode = .never
        // Navigasyon çubuğundaki sol düğmeyi ayarlayın
        navigationItem.leftBarButtonItem = customBackButton
        view.backgroundColor = UIColor(#colorLiteral(red: 0.9638196826, green: 0.9687927365, blue: 1, alpha: 1))
        tabBarController?.tabBar.isHidden = true
    }
    
    @objc fileprivate func handleBack() {
        tabBarController?.tabBar.isHidden = false
        self.navigationController?.popViewController(animated: true)
    }
   
}
