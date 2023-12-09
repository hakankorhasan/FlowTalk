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
    
    private let acceptButton: UIButton = {
        let btn = UIButton(type: .system)
        return btn
    }()
    
    private let declineButton: UIButton = {
        let btn = UIButton(type: .system)
        return btn
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(userImageView)
        contentView.addSubview(usernameLabel)
        contentView.addSubview(acceptButton)
        contentView.addSubview(declineButton)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        acceptButton.backgroundColor = #colorLiteral(red: 0.3739683032, green: 0.6619769931, blue: 0.0885688886, alpha: 1)
        acceptButton.layer.borderWidth = 1
        acceptButton.layer.borderColor = UIColor.black.cgColor
        acceptButton.layer.cornerRadius = 10
        acceptButton.setTitle("Accept", for: .normal)
        acceptButton.tintColor = .black
        acceptButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        acceptButton.clipsToBounds = true
    
        declineButton.backgroundColor = #colorLiteral(red: 0.762557646, green: 0, blue: 0, alpha: 1)
        declineButton.layer.borderWidth = 1
        declineButton.layer.borderColor = UIColor.black.cgColor
        declineButton.layer.cornerRadius = 10
        declineButton.setTitle("Decline", for: .normal)
        declineButton.tintColor = .white
        declineButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        declineButton.clipsToBounds = true
        
        
     /*   userImageView.frame = CGRect(x: 10,
                                     y: 10,
                                     width: 64,
                                     height: 64)
        
        usernameLabel.frame = CGRect(x: userImageView.right + 10,
                                     y: 20,
                                     width: contentView.width - 20 - userImageView.width,
                                     height: 48)*/
        userImageView.anchor(top: topAnchor, leading: leadingAnchor, bottom: nil, trailing: nil, padding: .init(top: 10, left: 10, bottom: 0, right: 0), size: .init(width: 64, height: 64))
        usernameLabel.anchor(top: userImageView.topAnchor, leading: userImageView.trailingAnchor, bottom: nil, trailing: nil, padding: .init(top: 0, left: 15, bottom: 0, right: 0), size: .init(width: contentView.width - 20 - userImageView.width, height: 36))
        
        acceptButton.anchor(top: usernameLabel.bottomAnchor, leading: userImageView.trailingAnchor, bottom: nil, trailing: nil, padding: .init(top: 5, left: 15, bottom: 0, right: 0), size: .init(width: contentView.width/3, height: 32))
        declineButton.anchor(top: usernameLabel.bottomAnchor, leading: acceptButton.trailingAnchor, bottom: nil, trailing: nil, padding: .init(top: 5, left: 10, bottom: 0, right: 0), size: .init(width: contentView.width/3, height: 32))
        
    }

    func configure(with model: SearchResult, inController controllerType: ControllerType) {
        usernameLabel.text = model.name
        
        let path = "images/\(model.email)_profile_picture.png"
        
        
        StorageManager.shared.downloadUrl(for: path) { [weak self] result in
            switch result {
            case .success(let url):
                DispatchQueue.main.async {
                    self?.userImageView.sd_setImage(with: url)
                }
            case .failure(let error):
                print("failed to get image: ",error)
            }
        }
        
        // Controller tipine göre özelleştirmeleri yap
        if controllerType == .newConversationController {
            // Bu controller için gerekli özelleştirmeleri yap
            acceptButton.isHidden = true
            declineButton.isHidden = true
            // Diğer UI elemanlarını istediğiniz gibi düzenleyebilirsiniz
        } else if controllerType == .friendViewController {
            // Bu controller için gerekli özelleştirmeleri yap
            acceptButton.isHidden = false
            declineButton.isHidden = false
            // Diğer UI elemanlarını istediğiniz gibi düzenleyebilirsiniz
        }
    }
}

enum ControllerType {
    case newConversationController
    case friendViewController
    // İhtiyacınıza göre enum case'leri ekleyebilirsiniz
}

