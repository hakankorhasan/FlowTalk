//
//  Extensions.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 22.08.2023.
//

import UIKit
import InputBarAccessoryView
import FirebaseDatabase


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



extension UIImage {

    func imageWithSize(scaledToSize newSize: CGSize) -> UIImage {

        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        self.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }

}
