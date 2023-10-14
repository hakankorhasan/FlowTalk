//
//  UIColor+Extensions.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 14.10.2023.
//

import Foundation
import UIKit

extension UIColor {
    
    /// Dark mode ve light mode için uygun renkleri döndüren extension
    ///
    /// - Parameters:
    ///   - lightModeColor: Light mode için renk
    ///   - darkModeColor: Dark mode için renk
    /// - Returns: Uygun renk
    static func dynamicColor(lightModeColor: UIColor, darkModeColor: UIColor) -> UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { (traitCollection) -> UIColor in
                return traitCollection.userInterfaceStyle == .dark ? darkModeColor : lightModeColor
            }
        } else {
            return lightModeColor
        }
    }
    
}
