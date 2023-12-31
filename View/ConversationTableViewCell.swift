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
        iv.layer.cornerRadius = 40
        iv.layer.masksToBounds = true
        return iv
    }()
    
    var onlineInfoButton: UIButton = {
        let btn = UIButton()
        btn.backgroundColor = #colorLiteral(red: 0, green: 0.9388161302, blue: 0, alpha: 1)
        btn.layer.cornerRadius = 10
        return btn
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
    
    private let cacheKeyPrefix = "conversation_"
    
    override func prepareForReuse() {
        super.prepareForReuse()
    /*    userImageView.image = nil
        usernameLabel.text = nil
        dateLabel.text = nil
        userMessageLabel.text = nil*/
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.layer.cornerRadius = 44
        self.selectionStyle = .none
        backgroundColor = UIColor(red: 0.9590069652, green: 0.9689564109, blue: 1, alpha: 1)
        contentView.backgroundColor = UIColor(red: 0.9590069652, green: 0.9689564109, blue: 1, alpha: 1)
        // UITableViewCell içindeki shadow ayarları
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowOpacity = 0.5
        layer.shadowRadius = 2.0
        
        contentView.layer.cornerRadius = 44
        
        addSubview(userImageView)
        addSubview(usernameLabel)
        addSubview(dateLabel)
        addSubview(userMessageLabel)
        addSubview(onlineInfoButton)
    }
    
    // cell hücrelerine tabelView ın kenarlarından 15 er puanlık dolgu verdik
    override var frame: CGRect {
            get {
                return super.frame
            }
            set (newFrame) {
                var frame =  newFrame
                        frame.origin.y += 10
                        frame.origin.x += 10
                        frame.size.height -= 15
                        frame.size.width -= 2 * 10
                super.frame = frame
            }
        }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        userImageView.anchor(top: topAnchor, leading: leadingAnchor, bottom: bottomAnchor, trailing: nil, padding: .init(top: 10, left: 10, bottom: 10, right: 0), size: .init(width: 80, height: 80))
        onlineInfoButton.anchor(top: nil, leading: nil, bottom: userImageView.bottomAnchor, trailing: userImageView.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 2, right: 2), size: .init(width: 20, height: 20))
        
        usernameLabel.anchor(top: topAnchor, leading: userImageView.trailingAnchor, bottom: nil, trailing: nil, padding: .init(top: 5, left: 10, bottom: 0, right: 10), size: .init(width: contentView.width - 100 - userImageView.width, height: (contentView.height-20)/2))
        
        dateLabel.anchor(top: topAnchor, leading: usernameLabel.trailingAnchor, bottom: nil, trailing: trailingAnchor, padding: .init(top: 10, left: 0, bottom: 0, right: 10), size: .init(width: 60, height: 20))
        
        userMessageLabel.anchor(top: usernameLabel.bottomAnchor, leading: userImageView.trailingAnchor, bottom: bottomAnchor, trailing: trailingAnchor, padding: .init(top: 5, left: 10, bottom: 5, right: 10))

    }

    func configure(with model: Conversation) {
        
        usernameLabel.text = model.name
        
        switch model.latestMessage.type {
            case .audio:
                userMessageLabel.text = "Voice 🎵"
                    // Handle audio message logic
            case .photo:
                userMessageLabel.text = "Image 📷"
                    // Handle photo message logic
            case .location:
                userMessageLabel.text = "Location 📍"
                    // Handle location message logic
            case .text:
            userMessageLabel.text = model.latestMessage.text
                // Handle text message logic
        }
        
        let date = model.latestMessage.date
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "dd MMM yyyy 'at' HH:mm:ss 'GMT'Z"
        inputFormatter.locale = Locale(identifier: "en_US_POSIX")

        if let dateObject = inputFormatter.date(from: date) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "h:mm a"
            outputFormatter.amSymbol = "am"
            outputFormatter.pmSymbol = "pm"

            let formattedDate = outputFormatter.string(from: dateObject)
            dateLabel.text = formattedDate
            print(formattedDate)
        } else {
            print("Date format conversion failed.")
        }
        
        let path = "images/\(model.otherUserEmail)_profile_picture.png"
        let cacheKey = cacheKeyPrefix + model.otherUserEmail

       
        print("Cache'de veri yok, internetten çek")
        if getUserSetting(status: .other, setting: .profilePhoto) {
            StorageManager.shared.downloadUrl(for: path) { [weak self] result in
                switch result {
                case .success(let url):
                    DispatchQueue.main.async {
                        self?.userImageView.sd_setImage(with: url)
                    }
                case .failure(let error):
                    print("failed to get image: ", error)
                }
            }
        } else {
            self.userImageView.image = UIImage(systemName: "person.fill")
            self.userImageView.tintColor = .darkGray
        }
    }

}
