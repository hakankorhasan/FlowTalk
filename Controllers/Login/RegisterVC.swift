//
//  RegisterVC.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 1.11.2023.
//

import UIKit
import CountryPicker

class RegisterVC: UIViewController {
    
    let scrollView: UIScrollView = {
       let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private var userImageView = UIImageView()
    var ivBackground = UIImageView()
    var ivBack = UIImageView()
    
    private var nameLabel = UILabel()
    private var nameTF = UITextField()
    
    private var surnameLabel = UILabel()
    private var surnameTF = UITextField()
    
    private var emailLabel = UILabel()
    private var emailTF = UITextField()
    
    private var passwordLabel = UILabel()
    private var passwordTF = UITextField()
    private var isSecureImage = UIImageView()
    
    private var phoneLabel = UILabel()
    private var countryLabel = UILabel()
    private var phoneTF = UITextField()
    private var countryCodeTF = UITextField()
    
    private var registerButton = UIButton()
    
    var nameSurenameView = UIStackView()
    var emailAddressView = UIStackView()
    var passwordView = UIStackView()
    var phoneView = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleSecureImage))
        
        scrollView.isUserInteractionEnabled = true
        isSecureImage.isUserInteractionEnabled = true
        isSecureImage.addGestureRecognizer(tapGesture)
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapChangeProfilePic))
        userImageView.addGestureRecognizer(gesture)
        view.addSubview(scrollView)
        scrollView.isScrollEnabled = false
        registerButton.addTarget(self, action: #selector(handleRegister), for: .touchUpInside)
        countryCodeTF.isUserInteractionEnabled = true
        phoneTF.delegate = self
        createCountryPicker()
        view.backgroundColor = .white
        setupViews()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        //scrollView.contentSize = CGSize(width: view.frame.size.width, height: view.frame.size.height)
        scrollView.frame = view.bounds
    }
    
    
    @objc fileprivate func didTapChangeProfilePic() {
        presentPhotoActionSheet()
        print("geldi")
    }
    
    let attributes: [NSAttributedString.Key : Any] = [NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.8),
        NSAttributedString.Key.font: UIFont(name: "", size: 12.0) ?? UIFont.systemFont(ofSize: 12.0) ]

    private func setupViews() {
        setupBackground()
        setupIvBack()
        imageViewUI()
        nameAndSurnameUI()
        emailUI()
        passwordUI()
        phoneUI()
        registerBtnUI()
    }
    
    @objc private func handleRegister() {
        let countryCode = countryCodeTF.text ?? ""
        let phoneNumberString = phoneTF.text ?? ""
        let countryCodeInt = Int(countryCode) ?? 0
        let phoneNumberInt = Int(phoneNumberString)
        
        guard let email = emailTF.text,
              let password = passwordTF.text,
              let firstName = nameTF.text,
              let lastName = surnameTF.text,
              //let phone = phoneNumber,
              !email.isEmpty,
              !firstName.isEmpty,
              !lastName.isEmpty,
              !password.isEmpty,
              password.count >= 6 else {
            //alertUserLoginError()
            return
        }
        
        FirebaseRegisterManager.shared.registerWithFirebase(viewController: self, userImageView: userImageView, email: email, password: password, firstName: firstName, lastName: lastName, countryCode: countryCodeInt, phoneNumber: phoneNumberInt) { success in
            if success {
                print("kayıt başarılı")
                self.navigationController?.popViewController(animated: true)
                self.navigationController?.dismiss(animated: true)
            } else {
                print("kayıt başarısız")
            }
        }
    }
    
    private func imageViewUI() {
        scrollView.addSubview(userImageView)
        userImageView.isUserInteractionEnabled = true
        userImageView.clipsToBounds = true
        userImageView.image = UIImage(systemName: "person.circle")
        userImageView.contentMode = .scaleAspectFit
        userImageView.tintColor = .gray
        userImageView.layer.masksToBounds = true
        userImageView.layer.borderColor = UIColor.lightGray.cgColor
        userImageView.layer.borderWidth = 2.0
        userImageView.translatesAutoresizingMaskIntoConstraints = false
        userImageView.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: nil, bottom: nil, trailing: nil, padding: .init(top: 20, left: 0, bottom: 0, right: 0), size: .init(width: view.width/3, height: view.width/3))
        userImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        userImageView.layer.cornerRadius = view.width / 6.0
        
    }
    
    private func nameAndSurnameUI() {
        scrollView.addSubview(nameLabel)
        scrollView.addSubview(nameTF)
        scrollView.addSubview(surnameLabel)
        scrollView.addSubview(surnameTF)
        
        nameLabel.text = "Name"
        nameLabel.font = .systemFont(ofSize: 10, weight: .regular)
       
        nameTF.attributedPlaceholder = NSAttributedString(string: "Name...", attributes: attributes)
        nameTF.autocapitalizationType = .none
        nameTF.font = .systemFont(ofSize: 14, weight: .medium)
        nameTF.autocorrectionType = .no
        nameTF.returnKeyType = .continue
        nameTF.layer.cornerRadius = 18
        nameTF.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        nameTF.leftViewMode = .always
        nameTF.backgroundColor = .lightGray//UIColor.white.withAlphaComponent(0.6)
        nameTF.heightAnchor.constraint(equalToConstant: 46).isActive = true
        
        surnameLabel.text = "Surname"
        surnameLabel.font = .systemFont(ofSize: 10, weight: .regular)
        
        surnameTF.attributedPlaceholder = NSAttributedString(string: "Surname...", attributes: attributes)
        surnameTF.autocapitalizationType = .none
        surnameTF.font = .systemFont(ofSize: 14, weight: .medium)
        surnameTF.autocorrectionType = .no
        surnameTF.returnKeyType = .continue
        surnameTF.layer.cornerRadius = 18
        surnameTF.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        surnameTF.leftViewMode = .always
        surnameTF.backgroundColor = .lightGray//UIColor.white.withAlphaComponent(0.6)
        surnameTF.heightAnchor.constraint(equalToConstant: 46).isActive = true
        
        nameSurenameView = UIStackView(arrangedSubviews: [
            VerticalStackView(arrangedSubviews: [nameLabel, nameTF], spacing: 6),
            VerticalStackView(arrangedSubviews: [surnameLabel, surnameTF], spacing: 6)
        ])
        nameSurenameView.axis = .horizontal
        nameSurenameView.distribution = .fillEqually
        nameSurenameView.spacing = 15
        
        scrollView.addSubview(nameSurenameView)
        nameSurenameView.anchor(top: userImageView.bottomAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 20, left: 40, bottom: 0, right: 40))
        
    }
    
    private func emailUI() {
        scrollView.addSubview(emailLabel)
        scrollView.addSubview(emailTF)
        emailLabel.text = "Email Address"
        emailLabel.font = .systemFont(ofSize: 10, weight: .regular)
       
        emailTF.attributedPlaceholder = NSAttributedString(string: "Your email...", attributes: attributes)
        emailTF.autocapitalizationType = .none
        emailTF.font = .systemFont(ofSize: 14, weight: .medium)
        emailTF.autocorrectionType = .no
        emailTF.returnKeyType = .continue
        emailTF.layer.cornerRadius = 18
        emailTF.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        emailTF.leftViewMode = .always
        emailTF.backgroundColor = .lightGray//UIColor.white.withAlphaComponent(0.6)
        emailTF.heightAnchor.constraint(equalToConstant: 46).isActive = true
        
        emailAddressView = VerticalStackView(arrangedSubviews: [
            emailLabel, emailTF
        ], spacing: 6)
        scrollView.addSubview(emailAddressView)
        emailAddressView.anchor(top: nameSurenameView.bottomAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 20, left: 40, bottom: 0, right: 40))
        
    }
    
    private func passwordUI() {
        scrollView.addSubview(passwordLabel)
        scrollView.addSubview(passwordTF)
        passwordLabel.text = "Password"
        passwordLabel.font = .systemFont(ofSize: 10, weight: .regular)
       
        passwordTF.attributedPlaceholder = NSAttributedString(string: "Your password...", attributes: attributes)
        passwordTF.autocapitalizationType = .none
        passwordTF.isSecureTextEntry = true
        passwordTF.font = .systemFont(ofSize: 14, weight: .medium)
        passwordTF.autocorrectionType = .no
        passwordTF.returnKeyType = .continue
        passwordTF.layer.cornerRadius = 18
        passwordTF.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        passwordTF.leftViewMode = .always
        passwordTF.backgroundColor = .lightGray//UIColor.white.withAlphaComponent(0.6)
        passwordTF.heightAnchor.constraint(equalToConstant: 46).isActive = true
        
        isSecureImage.image = UIImage(systemName: "eye.slash.fill")
        isSecureImage.tintColor = .darkGray
        isSecureImage.heightAnchor.constraint(equalToConstant: 22).isActive = true
        isSecureImage.widthAnchor.constraint(equalToConstant: 28).isActive = true
        
        passwordView = VerticalStackView(arrangedSubviews: [
            passwordLabel, passwordTF
        ], spacing: 6)
        
        
        scrollView.addSubview(passwordView)
        passwordView.anchor(top: emailAddressView.bottomAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 20, left: 40, bottom: 0, right: 70))
        
        scrollView.addSubview(isSecureImage)
        isSecureImage.anchor(top: nil, leading: passwordView.trailingAnchor, bottom: nil, trailing: nil, padding: .init(top: 0, left: 10, bottom: 0, right: 0))
        isSecureImage.centerYAnchor.constraint(equalTo: passwordTF.centerYAnchor).isActive = true
    }
    
    @objc func toggleSecureImage() {
        if isSecureImage.image == UIImage(systemName: "eye.slash.fill") {
            isSecureImage.image = UIImage(systemName: "eye.fill")
            passwordTF.isSecureTextEntry = false
        } else {
            isSecureImage.image = UIImage(systemName: "eye.slash.fill")
            passwordTF.isSecureTextEntry = true

        }
    }
    
    private func phoneUI() {
        scrollView.addSubview(phoneLabel)
        scrollView.addSubview(countryLabel)
        scrollView.addSubview(phoneTF)
        scrollView.addSubview(countryCodeTF)
        phoneLabel.text = "Phone Number"
        phoneLabel.font = .systemFont(ofSize: 10, weight: .regular)
        
        countryLabel.text = "Country Code"
        countryLabel.font = .systemFont(ofSize: 10, weight: .regular)
       
        phoneTF.attributedPlaceholder = NSAttributedString(string: "XXX - XXX - XX - XX", attributes: attributes)
        phoneTF.font = .systemFont(ofSize: 14, weight: .medium)
        phoneTF.autocorrectionType = .no
        phoneTF.keyboardType = .numberPad
        phoneTF.returnKeyType = .continue
        phoneTF.layer.cornerRadius = 18
        phoneTF.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        phoneTF.leftViewMode = .always
        phoneTF.backgroundColor = .lightGray//UIColor.white.withAlphaComponent(0.6)
        phoneTF.heightAnchor.constraint(equalToConstant: 46).isActive = true
        
        countryCodeTF.attributedPlaceholder = NSAttributedString(string: "+XXX", attributes: attributes)
        countryCodeTF.heightAnchor.constraint(equalToConstant: 46).isActive = true
        countryCodeTF.widthAnchor.constraint(equalToConstant: 80).isActive = true
        countryCodeTF.layer.cornerRadius = 18
        countryCodeTF.font = .systemFont(ofSize: 14, weight: .medium)
        countryCodeTF.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 0))
        countryCodeTF.leftViewMode = .always
        countryCodeTF.backgroundColor = .lightGray
        
        phoneView = UIStackView(arrangedSubviews: [
            HorizontalStackView(arrangedSubviews: [
                VerticalStackView(arrangedSubviews: [
                    countryLabel, countryCodeTF
                ], spacing: 6),
                VerticalStackView(arrangedSubviews: [
                    phoneLabel, phoneTF
                ], spacing: 6)
            ], spacing: 10, distrubiton: .fillProportionally)
        ])
        
        scrollView.addSubview(phoneView)
        phoneView.anchor(top: passwordView.bottomAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 20, left: 40, bottom: 0, right: 40))
    }
    
    private func createCountryPicker() {
        let picker = CountryPicker()
        picker.countryPickerDelegate = self
        picker.showPhoneNumbers = true
        countryCodeTF.inputView = picker
        picker.selectRow(0, inComponent: 0, animated: true)
    }
    
    private func registerBtnUI() {
        scrollView.addSubview(registerButton)
        registerButton.translatesAutoresizingMaskIntoConstraints = false
        registerButton.anchor(top: phoneView.bottomAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 30, left: 50, bottom: 0, right: 50), size: .init(width: 0, height: 60))
        registerButton.setTitle("Register", for: .normal)
        registerButton.setTitleColor(UIColor(#colorLiteral(red: 0.1999999881, green: 0.1999999881, blue: 0.1999999881, alpha: 1)), for: .normal)
        registerButton.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        registerButton.titleLabel?.font = UIFont(name: "Gratina", size: 16)
        registerButton.layer.cornerRadius = 30
    }
    
    
    func setupBackground() {
        scrollView.addSubview(ivBackground)
        ivBackground.translatesAutoresizingMaskIntoConstraints = false
        ivBackground.anchor(top: view.topAnchor, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: view.trailingAnchor)
        ivBackground.contentMode = .scaleAspectFill
        ivBackground.image = UIImage(named: "ivBack2")
    }
    
    func setupIvBack() {
        ivBack.isHidden = false
        scrollView.addSubview(ivBack)
        ivBack.translatesAutoresizingMaskIntoConstraints = false
        
        ivBack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10).isActive = true
        ivBack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        ivBack.widthAnchor.constraint(equalToConstant: 25).isActive = true
        ivBack.heightAnchor.constraint(equalToConstant: 25).isActive = true
                
        ivBack.image = UIImage(named: "ic_back")
                
        ivBack.isUserInteractionEnabled = true
        let backTapGesture = UITapGestureRecognizer(target: self, action: #selector(backScreen))
        ivBack.addGestureRecognizer(backTapGesture)
                
    }
    
    @objc private func backScreen() {
        ivBack.isHidden = true
        self.navigationController?.popViewController(animated: true)
    }
    
}

extension RegisterVC: CountryPickerDelegate, UITextFieldDelegate {
    
    /// MARK: -- Country Code Picker Delegate
    func countryPhoneCodePicker(_ picker: CountryPicker, didSelectCountryWithName name: String, countryCode: String, phoneCode: String, flag: UIImage) {
        
        countryCodeTF.text = phoneCode
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
                
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
                
        return updatedText.count <= 12
    }
    
}

extension RegisterVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func presentPhotoActionSheet() {
        
        let alert = UIAlertController(title: "Profile Picture", message: "How would you like to select a picture?", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: { _ in
            self.presentCamera()
        }))
        
        alert.addAction(UIAlertAction(title: "Chose Photo", style: .default, handler: { _ in
            self.presentPhotoPicker()
        }))
        
        present(alert, animated: true)
    }
    
    func presentCamera() {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.isEditing = true
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func presentPhotoPicker() {
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
        
        self.userImageView.image = selectedImage
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
