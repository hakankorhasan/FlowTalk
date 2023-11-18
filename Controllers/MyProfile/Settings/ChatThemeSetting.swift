//
//  ChatThemeSetting.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 17.11.2023.
//

import UIKit

class ChatThemeSetting: UIViewController {
    
    var phoneDesign = PhoneDesign()
    var brightnessSlider = UISlider()
    
    var changeButton = UIButton()
    let darkLabel = UILabel()
    let lightLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(#colorLiteral(red: 0.9638196826, green: 0.9687927365, blue: 1, alpha: 1))
        changeButton.addTarget(self, action: #selector(handleChange), for: .touchUpInside)
        phoneDesign.isUserInteractionEnabled = true
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleChange))
        phoneDesign.addGestureRecognizer(gesture)
        configurePhoneView()
        darkOrLightLabel()
        brightnessSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
      
    }
    
    @objc func sliderValueChanged(_ sender: UISlider) {
        // Aydınlatma/Karartma miktarını belirle (0: tam aydınlatma, 1: tam karartma)
        // Gölge miktarını belirle
        let blackRatio = CGFloat(sender.value)
       
        phoneDesign.tintView.backgroundColor = UIColor(white: 0, alpha: blackRatio)
    }
    
    func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage {

       let scale = newWidth / image.size.width
       let newHeight = image.size.height * scale
       UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight))
        image.draw(in: CGRectMake(0, 0, newWidth, newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
       UIGraphicsEndImageContext()

       return newImage
   }
}


extension ChatThemeSetting: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @objc fileprivate func handleChange() {
        
        let alert = UIAlertController(title: "Chat Background Picture", message: "How would you like to select a picture?", preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        cancelAction.setValue(UIColor.red, forKey: "titleTextColor")
        alert.addAction(cancelAction)
        
        let takeAction = UIAlertAction(title: "Take Photo", style: .default) { _ in
            self.presentGallery()
        }
        alert.addAction(takeAction)
        
        UIView.animate(withDuration: 0.3, animations: {
               // Scale up the button by increasing its size
            self.changeButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            // Completion block: Scale down the button back to its original size
            UIView.animate(withDuration: 0.3) {
                self.changeButton.transform = CGAffineTransform.identity
            }
        }
        
        present(alert, animated: true)
    }
    
    func presentGallery() {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {
            return
        }
        
        self.phoneDesign.imageViewArea.image = selectedImage
       
        picker.dismiss(animated: true)
    }
}

extension ChatThemeSetting {
    private func configurePhoneView() {
        
        phoneDesign.setupNavBar()
        phoneDesign.setupImageView()
        phoneDesign.setupTabBarArea()
        
        let views = UIView()
        views.layer.cornerRadius = 14
        views.layer.borderWidth = 1.0
        views.layer.borderColor = UIColor.darkGray.cgColor
        view.addSubview(views)
        views.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 50, left: 100, bottom: 0, right: 100), size: .init(width: 0, height: 340))
        
        views.clipsToBounds = true
        views.addSubview(phoneDesign)
        phoneDesign.anchor(top: views.topAnchor, leading: views.leadingAnchor, bottom: nil, trailing: views.trailingAnchor, size: .init(width: 0, height: 340))
        
        changeButton.setTitle("Change", for: .normal)
        changeButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .regular)
        changeButton.setTitleColor(.white, for: .normal)
        changeButton.backgroundColor = #colorLiteral(red: 0, green: 0.1996820271, blue: 0.4762874842, alpha: 1)
        changeButton.layer.cornerRadius = 16
        changeButton.layer.shadowColor = UIColor.gray.cgColor
        changeButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        changeButton.layer.shadowRadius = 4
        changeButton.layer.shadowOpacity = 0.8
        changeButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        view.addSubview(changeButton)
        changeButton.anchor(top: views.bottomAnchor, leading: views.leadingAnchor, bottom: nil, trailing: views.trailingAnchor, padding: .init(top: 30, left: 30, bottom: 0, right: 30))
        
        let lineView = UIView()
        lineView.translatesAutoresizingMaskIntoConstraints = false
        lineView.backgroundColor = .black
        
        view.addSubview(lineView)
        lineView.anchor(top: changeButton.bottomAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 20, left: 0, bottom: 0, right: 0), size: .init(width: 0, height: 0.33))
    }
    
    private func darkOrLightLabel() {
        
        brightnessSlider.translatesAutoresizingMaskIntoConstraints = false
        brightnessSlider.layer.shadowOffset = CGSize(width: 0, height: 2)
        brightnessSlider.layer.shadowRadius = 4
        brightnessSlider.minimumTrackTintColor?.withAlphaComponent(1)
        brightnessSlider.layer.shadowOpacity = Float(0.8)
        brightnessSlider.minimumValue = 0.0
        brightnessSlider.maximumValue = 1.0
        brightnessSlider.value = 0.0
        brightnessSlider.minimumTrackTintColor = #colorLiteral(red: 0, green: 0.1996820271, blue: 0.4762874842, alpha: 1)
        brightnessSlider.minimumTrackTintColor = #colorLiteral(red: 0, green: 0.1996820271, blue: 0.4762874842, alpha: 1)
        let image = resizeImage(image: UIImage(named: "night-mode")!, newWidth: 24)
        
        brightnessSlider.setThumbImage(image, for: .normal)
        
        darkLabel.text = "If you want to change your wallpaper for light theme color, enable light theme from Settings > Chats > Theme."
        darkLabel.numberOfLines = 3
        darkLabel.font = .systemFont(ofSize: 14, weight: .regular)
        
        lightLabel.text = "If you want to change your wallpaper for dark theme color, enable dark theme from Settings > Chats > Theme."
        lightLabel.numberOfLines = 3
        lightLabel.textColor = .black
        lightLabel.textAlignment = .center
        lightLabel.font = .systemFont(ofSize: 14, weight: .regular)
        
        view.addSubview(lightLabel)
        lightLabel.anchor(top: nil, leading: view.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.trailingAnchor, padding: .init(top: 0, left: 40, bottom: 60, right: 40))
        
        
        view.addSubview(brightnessSlider)
        brightnessSlider.anchor(top: nil, leading: view.leadingAnchor, bottom: lightLabel.topAnchor, trailing: view.trailingAnchor, padding: .init(top: 0, left: 40, bottom: 30, right: 40))
    }
    
}

