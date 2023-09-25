//
//  NewConversationCell.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 25.09.2023.
//

import UIKit
import SDWebImage

class NewConversationCell: UITableViewCell {

    static let identifier = "NewConversationCell"
    
    private let userImageView: UIImageView = {
       let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 35
        iv.layer.masksToBounds = true
        return iv
    }()
    
    private let usernameLabel: UILabel = {
       let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(userImageView)
        contentView.addSubview(usernameLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        userImageView.frame = CGRect(x: 10,
                                     y: 10,
                                     width: 64,
                                     height: 64)
        
        usernameLabel.frame = CGRect(x: userImageView.right + 10,
                                     y: 20,
                                     width: contentView.width - 20 - userImageView.width,
                                     height: 48)
    }

    func configure(with model: SearchResult) {
        self.usernameLabel.text = model.name
        
        let path = "images/\(model.email)_profile_picture.png"
        
        
        StorageManager.shared.downloadUrl(for: path) { result in
            switch result {
            case .success(let url):
                DispatchQueue.main.async {
                    self.userImageView.sd_setImage(with: url)
                }
            case .failure(let error):
                print("failed to get image: ",error)
            }
        }
    }
}

