//
//  Extensions.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 22.08.2023.
//

import UIKit
import InputBarAccessoryView
import FirebaseDatabase

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

/*  guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
      return
  }
  let safeEmail = DatabaseManager.safeEmail(emaildAddress: currentEmail)

  // "users" düğümüne erişim
  let usersRef = Database.database().reference().child("users")
  let refOnline = Database.database().reference().child(safeEmail).child("isOnline")
         refOnline.setValue(false)
  // "users" düğümü içindeki her kullanıcı verisini döngü ile gezme
  usersRef.observe(.childAdded) { (snapshot) in
      if let userData = snapshot.value as? [String: Any], let email = userData["email"] as? String, email == safeEmail {
          // E-posta adresi güvenli e-posta ile eşleşiyor, "isOnline" değerini "true" yapın
          let isOnlineRef = usersRef.child(snapshot.key).child("isOnline")
          
          isOnlineRef.setValue(false) { (error, reference) in
              if let error = error {
                  print("isOnline güncelleme hatası: \(error)")
              } else {
                  print("isOnline başarıyla güncellendi.")
              }
          }
      }
  }*/

extension DatabaseReference {
    static func setUserOnlineStatus(isOnline: Bool) {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emaildAddress: currentEmail)
        
        let usersRef = Database.database().reference().child("users")
        let refOnline = Database.database().reference().child(safeEmail).child("isOnline")
        refOnline.setValue(isOnline)
        
        usersRef.observe(.childAdded) { (snapshot) in
            if let userData = snapshot.value as? [String: Any],
               let email = userData["email"] as? String,
               email == safeEmail {
                let isOnlineRef = usersRef.child(snapshot.key).child("isOnline")
                
                isOnlineRef.setValue(isOnline) { (error, reference) in
                    if let error = error {
                        print("isOnline error update error: ", error)
                    } else {
                        print("isOnline successfully updated.")
                    }
                }
            }
        }
       /* if let currentEmail = UserDefaults.standard.value(forKey: "email") as? String {
            let safeEmail = DatabaseManager.safeEmail(emaildAddress: currentEmail)
            let usersRef = Database.database().reference().child("users")
            let userRef = usersRef.child(safeEmail).child("isOnline")
            
            userRef.setValue(isOnline) { (error, reference) in
                if let error = error {
                    print("isOnline güncelleme hatası: \(error)")
                } else {
                    print("isOnline başarıyla güncellendi.")
                }
            }
        }*/
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
