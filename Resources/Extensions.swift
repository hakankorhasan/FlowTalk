//
//  Extensions.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 22.08.2023.
//

import UIKit
import InputBarAccessoryView

extension UIView {
    
    public var width: CGFloat {
        return frame.size.width
    }
    
    public var height: CGFloat {
        return frame.size.height
    }
    
    public var top: CGFloat {
        return frame.origin.y
    }
    
    public var bottom: CGFloat {
        return frame.size.height + frame.origin.y
    }
    
    public var left: CGFloat {
        return frame.origin.x
    }
    
    public var right: CGFloat {
        return frame.size.width + frame.origin.x
    }
}

extension Notification.Name {
    /// Notification when user logs in
    static let didLogInNotification = Notification.Name("didLogInNotification")
}

enum ButtonImage {
    static var paperclip: String {
        if #available(iOS 13.0, *) {
            return UITraitCollection.current.userInterfaceStyle == .dark ? "paperclip-darkmode" : "paperclip-lightmode"
        } else {
            // Önceki iOS sürümleri için
            return "paperclip-lightmode"
        }
    }
}

extension Date {
    
    func longDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy"
        return dateFormatter.string(from: self)
    }
    
    func stringDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "ddMMMyyyyHHmmss"
        return dateFormatter.string(from: self)
    }
    
    func time() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter.string(from: self)
    }
    
    func interval(ofComponent comp: Calendar.Component, from date: Date) -> Float {
        
        let currentCalendar = Calendar.current
        
        guard  let start = currentCalendar.ordinality(of: comp, in: .era, for: date) else { return 0 }
        guard  let end = currentCalendar.ordinality(of: comp, in: .era, for: self) else { return 0 }

        return Float(start - end)
    }

}

extension InputBarButtonItem {
    
    // Resmin adını dinamik olarak ayarlayan convenience bir initializer oluşturun
    convenience init(imageName: String) {
        self.init()
        if let image = UIImage(named: imageName) {
            setImage(image, for: .normal)
        }
    }
}

extension UIButton {
    
    /// Dark mode ve light mode için farklı resimleri ayarlayan extension
    ///
    /// - Parameters:
    ///   - lightModeImage: Light mode için resim
    ///   - darkModeImage: Dark mode için resim
    func setImages(lightModeImage: UIImage?, darkModeImage: UIImage?) {
        if #available(iOS 13.0, *) {
            if traitCollection.userInterfaceStyle == .dark {
                setImage(darkModeImage, for: .normal)
            } else {
                setImage(lightModeImage, for: .normal)
            }
        } else {
            // iOS 12 ve önceki sürümler için sadece light mode'da çalışacak kodlar buraya gelecek
            setImage(lightModeImage, for: .normal)
        }
    }
}

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

extension UIImage {

    func imageWithSize(scaledToSize newSize: CGSize) -> UIImage {

        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        self.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }

}
