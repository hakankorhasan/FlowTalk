//
//  SettingsTableViewCell.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 11.11.2023.
//

import UIKit

struct SettingsViewModel {
    let image: String
    let settingTitle: String
    let settingContentTitle: String
    let handler: (() -> Void)?
}


class SettingsTableViewCell: UITableViewCell {
    
    static let identifier = "SettingsTableViewCell"

    // icon image
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    // Text (Gizlilik)
    private let settingsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .bold)
        return label
    }()
    
    private let settingContentLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .darkGray
        return label
    }()
    // Text içeriği

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.backgroundColor = UIColor(#colorLiteral(red: 0.9638196826, green: 0.9687927365, blue: 1, alpha: 1))
        backgroundColor = UIColor(#colorLiteral(red: 0.9638196826, green: 0.9687927365, blue: 1, alpha: 1))
        contentView.layer.cornerRadius = 12
        layer.cornerRadius = 12
        addSubview(iconImageView)
        addSubview(settingsLabel)
        addSubview(settingContentLabel)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        iconImageView.anchor(top: topAnchor, leading: leadingAnchor, bottom: nil, trailing: nil, padding: .init(top: 9, left: 10, bottom: 9, right: 0), size: .init(width: 26, height: 26))
        
        settingsLabel.anchor(top: topAnchor, leading: iconImageView.trailingAnchor, bottom: nil, trailing: nil, padding: .init(top: 4, left: 10, bottom: 0, right: 0))
        
        settingContentLabel.anchor(top: settingsLabel.bottomAnchor, leading: iconImageView.trailingAnchor, bottom: nil, trailing: nil, padding: .init(top: 5, left: 10, bottom: 0, right: 0))

    }
    
    public func setUP(with viewModel: SettingsViewModel) {
        if let image = UIImage(systemName: viewModel.image) {
            iconImageView.image = image
            iconImageView.tintColor = .black
        } else {
            // Handle the case where the image is nil or not found.
            iconImageView.image = UIImage(systemName: "questionmark")
        }
        settingsLabel.text = viewModel.settingTitle
        settingContentLabel.text = viewModel.settingContentTitle
    }
    
    override var frame: CGRect {
        get {
            return super.frame
        }
        set (newFrame) {
            var frame = newFrame
            frame.origin.x += 20
            frame.size.width -= 2 * 20
            frame.size.height -= 10
            super.frame = frame
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
