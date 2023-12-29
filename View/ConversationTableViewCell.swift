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

       /* if let cachedImage = loadCacheImage(forkey: cacheKey) {
            // Önbellekte veri var, cache'den kullan
            let cachedName = UserDefaults.standard.string(forKey: cacheKey + "_name")
            let cachedDate = UserDefaults.standard.string(forKey: cacheKey + "_date")
            let cachedMessage = UserDefaults.standard.string(forKey: cacheKey + "_latest_message")
            print("cacheden çekildi")
            userImageView.image = cachedImage
            usernameLabel.text = cachedName
            userMessageLabel.text = cachedMessage
            dateLabel.text = cachedDate
        } else {*/
            // Cache'de veri yok, internetten çek
            print("Cache'de veri yok, internetten çek")
            if getUserSetting(status: .other, setting: .profilePhoto) {
                StorageManager.shared.downloadUrl(for: path) { [weak self] result in
                    switch result {
                    case .success(let url):
                        DispatchQueue.main.async {
                            self?.userImageView.sd_setImage(with: url)

                            // Save data to cache
                        //    self?.saveToCache(image: self?.userImageView.image, name: model.name, date: formattedDates, message: model.latestMessage.text, forkey: cacheKey)
                        }
                    case .failure(let error):
                        print("failed to get image: ", error)
                    }
                }
            } else {
                self.userImageView.image = UIImage(systemName: "person.fill")
                self.userImageView.tintColor = .darkGray
            }
        //}
    }

    func saveToCache(image: UIImage?, name: String, date: String, message: String, forkey key: String) {
        UserDefaults.standard.set(name, forKey: key + "_name")
        UserDefaults.standard.set(date, forKey: key + "_date")
        UserDefaults.standard.set(message, forKey: key + "_latest_message")

        if let image = image,
            let imageData = image.jpegData(compressionQuality: 1.0) {
            UserDefaults.standard.setValue(imageData, forKey: key)
        }
    }

    func loadCacheImage(forkey key: String) -> UIImage? {
        if let cachedImage = UserDefaults.standard.data(forKey: key),
           let image = UIImage(data: cachedImage) {
            return image
        } else {
            print("No cached image or error while loading for key: \(key)")
            return nil
        }
    }

}
