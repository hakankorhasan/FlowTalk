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

extension UILabel {
    convenience public init(text: String? = nil, font: UIFont? = UIFont.systemFont(ofSize: 14), textColor: UIColor = .black, textAlignment: NSTextAlignment = .left, numberOfLines: Int = 1) {
        self.init()
        self.text = text
        self.font = font
        self.textColor = textColor
        self.textAlignment = textAlignment
        self.numberOfLines = numberOfLines
    }
}


extension UITextField {
    convenience public init(placeholder: String? = nil) {
        self.init()
        self.placeholder = placeholder
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

extension UIView {
     func addGlobalUnsafeAreaView() {
        let unsafeAreaView = UIView()
                unsafeAreaView.backgroundColor = #colorLiteral(red: 0.1784554124, green: 0.2450254858, blue: 0.3119192123, alpha: 0.7805301171)
                self.addSubview(unsafeAreaView)

                let statusBarHeight = UIApplication.shared.statusBarFrame.size.height - 0.5
                unsafeAreaView.translatesAutoresizingMaskIntoConstraints = false

                NSLayoutConstraint.activate([
                    unsafeAreaView.heightAnchor.constraint(equalToConstant: statusBarHeight),
                    unsafeAreaView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 1.0),
                    unsafeAreaView.topAnchor.constraint(equalTo: self.topAnchor),
                    unsafeAreaView.centerXAnchor.constraint(equalTo: self.centerXAnchor)
                ])
    }
}
