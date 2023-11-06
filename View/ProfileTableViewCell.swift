//
//  ProfileTableViewCell.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 10.10.2023.
//

import UIKit

class ProfileTableViewCell: UITableViewCell {

    static let identifier = "ProfileTableViewCell"
    var padding: CGFloat? = nil
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    private let cellInfo: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        return label
    }()
    
    private let goToDetailButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        button.tintColor = .darkGray
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.backgroundColor = UIColor(#colorLiteral(red: 0.9638196826, green: 0.9687927365, blue: 1, alpha: 1))
        backgroundColor = UIColor(#colorLiteral(red: 0.9638196826, green: 0.9687927365, blue: 1, alpha: 1))
        
        
        addSubview(iconImageView)
        addSubview(cellInfo)
        addSubview(goToDetailButton)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        iconImageView.anchor(top: topAnchor, leading: leadingAnchor, bottom: nil, trailing: nil, padding: .init(top: 2, left: 10, bottom: 0, right: 0), size: .init(width: 46, height: 46))
        
        cellInfo.anchor(top: topAnchor, leading: iconImageView.trailingAnchor, bottom: bottomAnchor, trailing: nil, padding: .init(top: 6, left: 20, bottom: 6, right: 0), size: .init(width: 100, height: 30))
        
        goToDetailButton.anchor(top: topAnchor, leading: nil, bottom: bottomAnchor, trailing: trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 20))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    public func setUP(with viewModel: ProfileViewModel) {
        //self.textLabel?.text = viewModel.title
        switch viewModel.viewModelType {
        case .info:
            //textLabel?.textAlignment = .left
            cellInfo.text = viewModel.title
            iconImageView.image = UIImage(named: viewModel.titleResult)
            padding = viewModel.padding
        case .logout:
            //textLabel?.textColor = .red
            textLabel?.textAlignment = .center
            isUserInteractionEnabled = true
                       
            padding = viewModel.padding
        }
    }
    
    
    
    override var frame: CGRect {
        get {
            return super.frame
        }
        set (newFrame) {
            var frame = newFrame
            frame.origin.x += padding ?? 0
            frame.size.width -= 2 * (padding ?? 0)
            frame.size.height -= 10
            super.frame = frame
        }
    }


}
