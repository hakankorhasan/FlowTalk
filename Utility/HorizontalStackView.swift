//
//  HorizontalStackView.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 1.11.2023.
//

import UIKit

class HorizontalStackView: UIStackView {
    
    init(arrangedSubviews: [UIView], spacing: CGFloat = 0, distrubiton: UIStackView.Distribution = .fillEqually) {
        super.init(frame: .zero)
        
        arrangedSubviews.forEach({addArrangedSubview($0)})

        self.spacing = spacing
        self.axis = .horizontal
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
