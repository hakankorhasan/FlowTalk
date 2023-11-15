//
//  PrivacyTableViewCell.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 12.11.2023.
//

import UIKit

struct PrivacyViewModel {
    let title: String
    var isSwitchOn: Bool
    let handler: (() -> Void)?
    var titleContent: String {
        return isSwitchOn ? "Everyone" : "Nobody"
    }

}

class PrivacyTableViewCell: UITableViewCell {
    
    static let identifier = "PrivacyTableViewCell"
    
    var viewModel: PrivacyViewModel? {
        didSet {
            guard let viewModel = viewModel else { return }
            title.text = viewModel.title
            titleContent.text = viewModel.titleContent
            switchButton.isOn = viewModel.isSwitchOn
        }
    }
    
    let title: UILabel = {
       let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        return label
    }()
    
    let titleContent: UILabel = {
       let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .regular)
        label.textColor = .darkGray
        return label
    }()
    
    let switchButton = UISwitch()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.backgroundColor = UIColor(#colorLiteral(red: 0.9638196826, green: 0.9687927365, blue: 1, alpha: 1))
        backgroundColor = UIColor(#colorLiteral(red: 0.9638196826, green: 0.9687927365, blue: 1, alpha: 1))
       
        addSubview(title)
        addSubview(titleContent)
        addSubview(switchButton)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        title.anchor(top: topAnchor, leading: leadingAnchor, bottom: nil, trailing: nil, padding: .init(top: 8, left: 15, bottom: 0, right: 0))
        
        titleContent.anchor(top: title.bottomAnchor, leading: title.leadingAnchor, bottom: nil, trailing: nil, padding: .init(top: 4, left: 0, bottom: 0, right: 0))
        
        switchButton.translatesAutoresizingMaskIntoConstraints = false
        switchButton.anchor(top: nil, leading: nil, bottom: nil, trailing: trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 10), size: .init(width: 41, height: 25))
        switchButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        contentView.layer.cornerRadius = 12
        layer.cornerRadius = 12
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
