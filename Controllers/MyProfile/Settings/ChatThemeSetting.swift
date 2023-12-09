//
//  ChatThemeSetting.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 17.11.2023.
//

import UIKit
import FirebaseStorage
import JGProgressHUD

class ChatThemeSetting: UIViewController {
    
    var phoneDesign = PhoneDesign()
    var brightnessSlider = UISlider()
    var blackRatio = CGFloat()
    var changeButton = UIButton()
    let darkLabel = UILabel()
    let lightLabel = UILabel()
    
    let progress = JGProgressHUD(style: .light)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addGlobalUnsafeAreaView()

        progress.textLabel.text = "Background Image"
        progress.detailTextLabel.text = "Background image is loading.\n Please wait!"
        progress.detailTextLabel.numberOfLines = 2
        view.backgroundColor = UIColor(#colorLiteral(red: 0.9638196826, green: 0.9687927365, blue: 1, alpha: 1))
        changeButton.addTarget(self, action: #selector(handleChange), for: .touchUpInside)
        phoneDesign.isUserInteractionEnabled = true
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleChange))
        phoneDesign.addGestureRecognizer(gesture)
        configurePhoneView()
        navItemSetup()
        darkOrLightLabel()
        brightnessSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
       
    }
    
    private func navItemSetup() {
        
        let backButton = UIButton(type: .custom)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
        let customButton = UIBarButtonItem(customView: backButton)
        backButton.tintColor = .black
        backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        navigationItem.leftBarButtonItem = customButton
        
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emaildAddress: email)
        StorageManager.shared.downloadUrl(for: "images/\(safeEmail)_chatBack.jpg") { result in
            switch result {
            case .success(let downloadUrl):
                DispatchQueue.main.async {
                    self.phoneDesign.imageViewArea.sd_setImage(with: downloadUrl)
                }
            case .failure(let error):
                print("error", error)
            }
        }
    }
    
    @objc fileprivate func endedEdit() {
        progress.show(in: view)
        blackRatioConstants = blackRatio
        guard let imageData = phoneDesign.imageViewArea.image?.pngData() else {
               // Handle error if unable to convert image to data
            self.progress.textLabel.text = "Error"
            self.progress.detailTextLabel.text = "Please make sure you choose a picture."
            self.progress.dismiss(afterDelay: 1)
               return
           }

        guard let currEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emaildAddress: currEmail)
           // Use Firebase Storage reference
           let storageRef = Storage.storage().reference().child("images").child("\(safeEmail)_chatBack.jpg")

           // Upload image data to Firebase Storage
           storageRef.putData(imageData, metadata: nil) { (metadata, error) in
               if let error = error {
                   // Handle error
                   print("Error uploading image: \(error.localizedDescription)")
                  
               } else {
                   // Image uploaded successfully
                   self.progress.dismiss()
                 
               }
           }        //resizeAndUploadImage(image: phoneDesign.imageViewArea.image!, darknessLevel: blackRatio)
    }
    
    @objc fileprivate func handleBack() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func sliderValueChanged(_ sender: UISlider) {
        // Aydınlatma/Karartma miktarını belirle (0: tam aydınlatma, 1: tam karartma)
        // Gölge miktarını belirle
        blackRatio = CGFloat(sender.value)
        
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
    
    func resizeAndUploadImage(image: UIImage, darknessLevel: CGFloat) {
       
        let darkenedImage = applyDarkness(image: image, darknessLevel: darknessLevel)

        guard let imageData = darkenedImage.jpegData(compressionQuality: 0.8) else {
            // Handle error if unable to convert image to data
            return
        }

        // Use Firebase Storage reference
        let storageRef = Storage.storage().reference().child("images").child("darkenedImage.jpg")

        // Upload image data to Firebase Storage
        storageRef.putData(imageData, metadata: nil) { (metadata, error) in
            if let error = error {
                // Handle error
                print("Error uploading image: \(error.localizedDescription)")
            } else {
                // Image uploaded successfully
               // print("Image uploaded successfully. URL: \(String(describing: metadata?.downloadURL()))")
            }
        }
    }
    
    func applyDarkness(image: UIImage, darknessLevel: CGFloat) -> UIImage {
        guard let cgImage = image.cgImage else {
               return image
           }

           let context = CIContext(options: nil)
           let ciImage = CIImage(cgImage: cgImage)

           // Apply darkness using CIFilter
           if let filter = CIFilter(name: "CIColorControls") {
               filter.setValue(ciImage, forKey: kCIInputImageKey)
               filter.setValue(NSNumber(value: Float(-darknessLevel)), forKey: kCIInputContrastKey)

               if let outputCIImage = filter.outputImage,
                  let outputCGImage = context.createCGImage(outputCIImage, from: outputCIImage.extent) {
                   return UIImage(cgImage: outputCGImage)
               }
           }

           // Return original image if something goes wrong
           return image
    }
}


extension ChatThemeSetting: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @objc fileprivate func handleChange() {
        
        guard let currentUser = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emaildAddress: currentUser)
        
        let alert = UIAlertController(title: "Chat Background Picture", message: "How would you like to select a picture?", preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        cancelAction.setValue(UIColor.red, forKey: "titleTextColor")
        alert.addAction(cancelAction)
        
        let choseAction = UIAlertAction(title: "Chose Photo", style: .default) { _ in
            self.presentGallery()
        }
        choseAction.setValue(UIColor.black, forKey: "titleTextColor")
        
        let deletePhoto = UIAlertAction(title: "Delete", style: .default) { _ in
            
            let fileName = "\(safeEmail)_chatBack.jpg"
            StorageManager.shared.deleteProfilePicture(fileName: fileName) { success in
                if success {
                    self.phoneDesign.imageViewArea.image = nil
                } else {
                    let alertDeleted = UIAlertController(title: "Photo could not be deleted", message: "", preferredStyle: .alert)
                    let alert2 = UIAlertAction(title: "Close", style: .cancel)
                    alertDeleted.addAction(alert2)
                    self.present(alert, animated: true)
                }
            }
        }
        deletePhoto.setValue(UIColor.black, forKey: "titleTextColor")
        
        alert.addAction(choseAction)
        alert.addAction(deletePhoto)
        
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
        //vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
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
        
        let screenHeight = UIScreen.main.bounds.height

        // Ekran yüksekliğinin yüzde 30'u kadar bir değeri `phoneDesign`'ın yüksekliği olarak belirle
        let phoneDesignHeightPercentage: CGFloat = 0.4
        let phoneDesignHeight = screenHeight * phoneDesignHeightPercentage
        
        let views = UIView()
        views.layer.cornerRadius = 14
        views.layer.borderWidth = 1.0
        views.layer.borderColor = UIColor.darkGray.cgColor
        view.addSubview(views)
        views.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 30, left: self.view.width/4, bottom: 0, right: self.view.width/4), size: .init(width: 0, height: phoneDesignHeight))
        
        views.clipsToBounds = true
        views.addSubview(phoneDesign)
        phoneDesign.anchor(top: views.topAnchor, leading: views.leadingAnchor, bottom: nil, trailing: views.trailingAnchor, size: .init(width: 0, height: phoneDesignHeight))
        
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
        brightnessSlider.value = Float(blackRatioConstants)
        phoneDesign.tintView.backgroundColor = UIColor(white: 0, alpha: blackRatioConstants)
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
        
        view.addSubview(brightnessSlider)
        view.addSubview(lightLabel)
        brightnessSlider.anchor(top: changeButton.bottomAnchor, leading: view.leadingAnchor, bottom: lightLabel.topAnchor, trailing: view.trailingAnchor, padding: .init(top: 40, left: 40, bottom: 30, right: 40))
        
        let rightButton = UIButton()
        view.addSubview(rightButton)
        lightLabel.anchor(top: brightnessSlider.bottomAnchor, leading: view.leadingAnchor, bottom: rightButton.topAnchor, trailing: view.trailingAnchor, padding: .init(top: 0, left: 40, bottom: 30, right: 40))
    
        rightButton.setImage(UIImage(systemName: "checkmark"), for: .normal)
        rightButton.setTitleColor(.white, for: .normal)
        rightButton.backgroundColor = #colorLiteral(red: 0, green: 0.1996820271, blue: 0.4762874842, alpha: 1)
        rightButton.layer.cornerRadius = 25
        rightButton.layer.shadowColor = UIColor.gray.cgColor
        rightButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        rightButton.layer.shadowRadius = 4
        rightButton.layer.shadowOpacity = 0.8
        rightButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        rightButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        rightButton.tintColor = .white
        rightButton.addTarget(self, action: #selector(endedEdit), for: .touchUpInside)
        
        rightButton.anchor(top: lightLabel.bottomAnchor, leading: nil, bottom: nil, trailing: nil, padding: .init(top: 30, left: 0, bottom: 0, right: 0))
        rightButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }
    
}

