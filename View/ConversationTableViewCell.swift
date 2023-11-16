//
//  ConversationTableViewCell.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 15.09.2023.
//

import UIKit
import SDWebImage

class ConversationTableViewCell: UITableViewCell {

    static let identifier = "ConversationTableViewCell"
    
    private let userImageView: UIImageView = {
       let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 36
        iv.layer.masksToBounds = true
        return iv
    }()
    
    private let usernameLabel: UILabel = {
       let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        return label
    }()
    
    private let userMessageLabel: UILabel = {
       let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.numberOfLines = 0
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.text = "11:57 pm"
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.layer.cornerRadius = 44
        self.selectionStyle = .none
        
        // Gölge eklemek için özellikleri ayarlayın
        self.layer.shadowColor = UIColor.gray.cgColor // Gölge rengi
        self.layer.shadowOffset = CGSize(width: 0, height: 1) // Gölge boyutu ve yönü
        self.layer.shadowOpacity = 0.3 // Gölge opaklığı
        self.layer.shadowRadius = 1.0 // Gölge yarıçapı
        
        
        addSubview(userImageView)
        addSubview(usernameLabel)
        addSubview(dateLabel)
        addSubview(userMessageLabel)
    }
    
    // cell hücrelerine tabelView ın kenarlarından 15 er puanlık dolgu verdik
    override var frame: CGRect {
            get {
                return super.frame
            }
            set (newFrame) {
                var frame = newFrame
                frame.origin.x += 15
                frame.size.width -= 2 * 15
                super.frame = frame
            }
        }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        userImageView.frame = CGRect(x: 10,
                                     y: 10,
                                     width: 74,
                                     height: 74)
        
        usernameLabel.frame = CGRect(x: userImageView.right + 10,
                                     y: 10,
                                     width: contentView.width - 100 - userImageView.width,
                                     height: (contentView.height-20)/2)
        
        dateLabel.frame = CGRect(x: usernameLabel.right + 10,
                                 y: usernameLabel.center.y,
                                 width: 60,
                                 height: 20)
        
        
        userMessageLabel.frame = CGRect(x: userImageView.right + 10,
                                        y: usernameLabel.bottom,
                                        width: contentView.width - 100 - userImageView.width,
                                        height: (contentView.height-20)/2)
    }

    func configure(with model: Conversation) {
        userMessageLabel.text = model.latestMessage.text
        usernameLabel.text = model.name
        let date = model.latestMessage.date
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy 'at' h:mm:ss a 'GMT'Z"

        if let dateString = dateFormatter.date(from: date) {
            dateFormatter.dateFormat = "h:mm a"
            // "AMSymbol" ve "PMSymbol" özelliklerini küçük harfle ayarlayın
            dateFormatter.amSymbol = "am"
            dateFormatter.pmSymbol = "pm"
            let formattedDate = dateFormatter.string(from: dateString)
            dateLabel.text = formattedDate
            print(formattedDate)
        } else {
            print("Date format is incompatible.")
        }
      
        let path = "images/\(model.otherUserEmail)_profile_picture.png"
        
        
        if isOtherPF {
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
        } else {
            self.userImageView.image = UIImage(systemName: "person.fill")
            self.userImageView.tintColor = .darkGray
        }
        
    }
}
