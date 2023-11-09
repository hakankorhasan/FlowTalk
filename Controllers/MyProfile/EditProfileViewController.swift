//
//  EditProfileViewController.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 6.11.2023.
//

import UIKit
import CountryPicker

class EditProfileViewController: UIViewController {
    
    private let scrollView: UIScrollView = {
       let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let profileImageView: UIImageView = {
       let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 50
        iv.layer.masksToBounds = true
        iv.backgroundColor = .gray
        return iv
    }()
    
    private let button: UIButton = {
       let btn = UIButton()
        btn.backgroundColor = .black
        btn.layer.cornerRadius = 12
        btn.setImage(UIImage(named: "edit-5"), for: .normal)
        return btn
    }()
    
    private let nameLabel = UILabel(text: "Name", font: .systemFont(ofSize: 12, weight: .regular))
    private let nameTextField = UITextField(placeholder: "Name")
    let lineViewName = UIView()
    
    private let surnameLabel = UILabel(text: "Surname", font: .systemFont(ofSize: 12, weight: .regular))
    private let surnameTextField = UITextField(placeholder: "Surname")
    let lineViewSurname = UIView()
    
    private let passwordLabel = UILabel(text: "New Password", font: .systemFont(ofSize: 12, weight: .regular))
    private let passwordTextField = UITextField(placeholder: "New Password")
    let lineViewPassword = UIView()
    
    private let notMatchLabel = UILabel(text: "Passwords do not match! ❌", font: .systemFont(ofSize: 8, weight: .regular), textColor: .red, textAlignment: .left, numberOfLines: 0)
    private let notMatchLabel2 = UILabel(text: "Passwords do not match! ❌", font: .systemFont(ofSize: 8, weight: .regular), textColor: .red, textAlignment: .left, numberOfLines: 0)
    private let passwordSameCorrect = UILabel(text: "Passwords match ✅", font: .systemFont(ofSize: 8, weight: .regular), textColor: .green, textAlignment: .left, numberOfLines: 0)
    private let passwordSameCorrect2 = UILabel(text: "Passwords match ✅", font: .systemFont(ofSize: 8, weight: .regular), textColor: .green, textAlignment: .left, numberOfLines: 0)
     
    private let confirmPasswordLabel = UILabel(text: "Confirm Password", font: .systemFont(ofSize: 12, weight: .regular))
    private let confirmPasswordTextField = UITextField(placeholder: "Confirm password")
    let lineViewConfirmPassword = UIView()
    
    private let countryCodeLabel = UILabel(text: "Country code", font: .systemFont(ofSize: 12, weight: .regular))
    private let countryCodeTextField = UITextField(placeholder: "+XXX")
    let lineViewCode = UIView()
    
    private let phoneNumberLabel = UILabel(text: "Phone Number", font: .systemFont(ofSize: 12, weight: .regular))
    private let phoneTextField = UITextField(placeholder: "XXX - XXX - XX - XX")
    let lineViewPhone = UIView()
    
    private var isSecureImage = UIImageView()
    private var isSecureImage2 = UIImageView()
    private let saveButton = UIButton()
    
    var nameStackView = UIStackView()
    var surnameStackView = UIStackView()
    var passwordStackView = UIStackView()
    var confirmPasswordStackView = UIStackView()
    var phoneStackView = UIStackView()
    
    var labelTextFieldPairs: [(label: UILabel, textField: UITextField)] = []
    private var labelInitialYPositions = [UILabel: CGFloat]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Edit Profile"
        // Özel bir düğme oluşturun
        let backButton = UIButton(type: .custom)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
        let customBackButton = UIBarButtonItem(customView: backButton)
        backButton.tintColor = .black
        backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItem = customBackButton
        view.backgroundColor = UIColor(#colorLiteral(red: 0.9638196826, green: 0.9687927365, blue: 1, alpha: 1))
        tabBarController?.tabBar.isHidden = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleSecureImage))
        let tapGesture2 = UITapGestureRecognizer(target: self, action: #selector(toggleSecureImage2))
        passwordTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        confirmPasswordTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        saveButton.addTarget(self, action: #selector(handleSave), for: .touchUpInside)

        scrollView.isUserInteractionEnabled = true
        isSecureImage.isUserInteractionEnabled = true
        isSecureImage2.isUserInteractionEnabled = true
        isSecureImage.addGestureRecognizer(tapGesture)
        isSecureImage2.addGestureRecognizer(tapGesture2)
        
        view.addSubview(scrollView)
       
        labelTextFieldPairs = [
            (nameLabel, nameTextField),
            (surnameLabel, surnameTextField),
            (passwordLabel, passwordTextField),
            (confirmPasswordLabel, confirmPasswordTextField),
            (countryCodeLabel, countryCodeTextField),
            (phoneNumberLabel, phoneTextField)
        ]
        
        // Her çift için gesture recognizer'ları ekleyin
        for (pairLabel, pairTextField) in labelTextFieldPairs {
            addTapGestureRecognizerToPair(pairLabel, pairTextField)
        }
        
        saveInitialYPositions()
        setupImageView()
        setupNameStack()
        setupSurnameStack()
        setupPasswordStack()
        setupConfirmPasswordStack()
        setupPhoneStack()
        createCountryPicker()
        fetchUserData()
    }
    
    @objc fileprivate func handleBack() {
        tabBarController?.tabBar.isHidden = false
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func toggleSecureImage() {
        if isSecureImage.image == UIImage(systemName: "eye.slash.fill") {
            isSecureImage.image = UIImage(systemName: "eye.fill")
            passwordTextField.isSecureTextEntry = false
        } else {
            isSecureImage.image = UIImage(systemName: "eye.slash.fill")
            passwordTextField.isSecureTextEntry = true

        }
    }
    
    @objc func toggleSecureImage2() {
        if isSecureImage2.image == UIImage(systemName: "eye.slash.fill") {
            isSecureImage2.image = UIImage(systemName: "eye.fill")
            confirmPasswordTextField.isSecureTextEntry = false
        } else {
            isSecureImage2.image = UIImage(systemName: "eye.slash.fill")
            confirmPasswordTextField.isSecureTextEntry = true

        }
    }
    
    private func createCountryPicker() {
        let picker = CountryPicker()
        picker.countryPickerDelegate = self
        picker.showPhoneNumbers = true
        countryCodeTextField.inputView = picker
        picker.selectRow(0, inComponent: 0, animated: true)
    }
    
    private func fetchUserData() {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emaildAddress: currentEmail)
        let imagePath = "images/\(safeEmail)_profile_picture.png"
        
        DatabaseManager.shared.getDataFor(path: safeEmail) { [weak self] result in
            switch result {
            case .success(let data):
                guard let userData = data as? [String: Any],
                      let firstName = userData["first_name"] as? String,
                      let lastName = userData["last_name"] as? String,
                      let countryCode = userData["country_code"] as? Int,
                      let phoneNumber = userData ["phone_number"] as? Int else {
                    return
                }
                
                let countryCodeString = "+" + String(countryCode)
                let phoneNumberString = String(phoneNumber)
                self?.nameTextField.placeholder = firstName
                self?.surnameTextField.placeholder = lastName
                if countryCode != 0 && phoneNumber != 0 {
                    self?.countryCodeTextField.placeholder = countryCodeString
                    self?.phoneTextField.placeholder = phoneNumberString
                }
                
            case .failure(let error):
                print("result data for edit profile page: \(error)")
            }
        }
        
        StorageManager.shared.downloadUrl(for: imagePath) { [weak self] result in
            switch result {
            case .success(let url):
                DispatchQueue.main.async {
                    self?.profileImageView.sd_setImage(with: url)
                }
            case .failure(let error):
                print("failed to get image for profile edit page: \(error)")
            }
        }
        
    }
    
    @objc private func handleSave() {
        guard let firstName = nameTextField.text,
              let lastName = surnameTextField.text,
              let password = passwordTextField.text,
              let phone = phoneTextField.text,
              !firstName.isEmpty,
              !lastName.isEmpty,
              !password.isEmpty,
              !phone.isEmpty else {
            showAlertDialog()
            return
        }
              
    }
    
    private func showAlertDialog() {
        let alert = UIAlertController(title: "Woops", message: "You haven't made any changes.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel))
        
        present(alert, animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
    }
    
}

extension EditProfileViewController: UITextFieldDelegate {
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        let password = passwordTextField.text ?? ""
        let confirmPassword = confirmPasswordTextField.text ?? ""

        if textField == passwordTextField || textField == confirmPasswordTextField {
            if password.isEmpty && confirmPassword.isEmpty {
                passwordSameCorrect.isHidden = true
                passwordSameCorrect2.isHidden = true
                notMatchLabel2.isHidden = true
                notMatchLabel.isHidden = true
            } else if password == confirmPassword {
                passwordSameCorrect.isHidden = false
                passwordSameCorrect2.isHidden = false
                notMatchLabel2.isHidden = true
                notMatchLabel.isHidden = true
            } else {
                passwordSameCorrect2.isHidden = true
                passwordSameCorrect.isHidden = true
                notMatchLabel.isHidden = false
                notMatchLabel2.isHidden = false
            }
        }
    }
    // Her çift için bir gesture recognizer eklemek için yardımcı bir fonksiyon
    private func addTapGestureRecognizerToPair(_ label: UILabel, _ textField: UITextField) {
        label.isUserInteractionEnabled = true
        textField.delegate = self // UITextFieldDelegate'ı uygun şekilde ayarlayın

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(labelTapped(_:)))
        label.addGestureRecognizer(tapGesture)
    }
    
    @objc func labelTapped(_ gesture: UITapGestureRecognizer) {
        if let label = gesture.view as? UILabel {
            for (pairLabel, pairTextField) in labelTextFieldPairs {
                if label == pairLabel {
                    animateLabel(pairLabel, up: true)
                    pairTextField.becomeFirstResponder()
                } else {
                    animateLabel(pairLabel, up: false)
                }
            }
        }
    }

    
    func animateLabel(_ label: UILabel, up: Bool) {
        let offset: CGFloat = up ? -label.frame.height/2 - 5 : 0
        UIView.animate(withDuration: 0.3) {
            label.frame.origin.y = self.labelInitialYPositions[label]! + offset
        }
    }
    // Önceki konumları kaydetmek için bir fonksiyon
    private func saveInitialYPositions() {
        for (pairLabel, _) in labelTextFieldPairs {
            labelInitialYPositions[pairLabel] = pairLabel.frame.origin.y
        }
    }
    // UITextFieldDelegate metodları
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Textfield düzenlemeye başladığında ilgili etiketi ve animasyonu seçin
        for (pairLabel, pairTextField) in labelTextFieldPairs {
            if textField == pairTextField {
                animateLabel(pairLabel, up: true)
            }
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        // Textfield düzenlemeyi bitirdiğinde ilgili etiketi ve animasyonu seçin
        for (pairLabel, pairTextField) in labelTextFieldPairs {
            if textField == pairTextField {
                animateLabel(pairLabel, up: false)
            }
        }
    }
}

extension EditProfileViewController: CountryPickerDelegate {
    
    func countryPhoneCodePicker(_ picker: CountryPicker, didSelectCountryWithName name: String, countryCode: String, phoneCode: String, flag: UIImage) {
        
        countryCodeTextField.text = phoneCode
    }
    
}

extension EditProfileViewController {
    
    private func setupImageView() {
        scrollView.addSubview(profileImageView)
        profileImageView.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: nil, bottom: nil, trailing: nil, padding: .init(top: 20, left: 0, bottom: 0, right: 0), size: .init(width: 100, height: 100))
        profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        scrollView.addSubview(button)
        button.anchor(top: nil, leading: nil, bottom: profileImageView.bottomAnchor, trailing: profileImageView.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 5, right: 5), size: .init(width: 24, height: 24))
    }
    
    private func setupNameStack() {
        lineViewName.translatesAutoresizingMaskIntoConstraints = false
        lineViewName.heightAnchor.constraint(equalToConstant: 0.33).isActive = true
        lineViewName.backgroundColor = .black
        
        nameStackView = VerticalStackView(arrangedSubviews: [
            nameLabel,
            nameTextField,
        ], spacing: 10)
        
        scrollView.addSubview(nameStackView)
        nameStackView.anchor(top: profileImageView.bottomAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 30, left: 30, bottom: 0, right: 30))
        scrollView.addSubview(lineViewName)
        lineViewName.anchor(top: nameStackView.bottomAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 10, left: 20, bottom: 0, right: 20))
       
    }
    
    private func setupSurnameStack() {
        lineViewSurname.backgroundColor = .black
        lineViewSurname.translatesAutoresizingMaskIntoConstraints = false
        lineViewSurname.heightAnchor.constraint(equalToConstant: 0.33).isActive = true
        
        surnameStackView = VerticalStackView(arrangedSubviews: [
            surnameLabel,
            surnameTextField,
        ], spacing: 10)
        
        scrollView.addSubview(surnameStackView)
        surnameStackView.anchor(top: nameStackView.bottomAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 30, left: 30, bottom: 0, right: 30))
        scrollView.addSubview(lineViewSurname)
        lineViewSurname.anchor(top: surnameStackView.bottomAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 10, left: 20, bottom: 0, right: 20))
    }
    
    private func setupPasswordStack() {
        passwordSameCorrect.isHidden = true
        notMatchLabel.isHidden = true
        lineViewPassword.backgroundColor = .black
        lineViewPassword.translatesAutoresizingMaskIntoConstraints = false
        lineViewPassword.heightAnchor.constraint(equalToConstant: 0.33).isActive = true
        
        isSecureImage.image = UIImage(systemName: "eye.slash.fill")
        isSecureImage.tintColor = .darkGray
        isSecureImage.heightAnchor.constraint(equalToConstant: 22).isActive = true
        isSecureImage.widthAnchor.constraint(equalToConstant: 28).isActive = true
        
        passwordTextField.isSecureTextEntry = true
        passwordStackView = VerticalStackView(arrangedSubviews: [
            passwordLabel,
            HorizontalStackView(arrangedSubviews: [passwordTextField, isSecureImage], spacing: 20, distrubiton: .fill)
        ], spacing: 10)
        
        scrollView.addSubview(passwordStackView)
        passwordStackView.anchor(top: surnameStackView.bottomAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 30, left: 30, bottom: 0, right: 30))
        scrollView.addSubview(lineViewPassword)
        lineViewPassword.anchor(top: passwordStackView.bottomAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 10, left: 20, bottom: 0, right: 20))
        
        scrollView.addSubview(notMatchLabel)
        scrollView.addSubview(passwordSameCorrect)
        passwordSameCorrect.anchor(top: lineViewPassword.bottomAnchor, leading: lineViewPassword.leadingAnchor, bottom: nil, trailing: nil, padding: .init(top: 2, left: 0, bottom: 0, right: 0))
        notMatchLabel.anchor(top: lineViewPassword.bottomAnchor, leading: lineViewPassword.leadingAnchor, bottom: nil, trailing: nil, padding: .init(top: 2, left: 0, bottom: 0, right: 0))
    }
    
    private func setupConfirmPasswordStack() {
        passwordSameCorrect2.isHidden = true
        notMatchLabel2.isHidden = true
        lineViewConfirmPassword.backgroundColor = .black
        lineViewConfirmPassword.translatesAutoresizingMaskIntoConstraints = false
        lineViewConfirmPassword.heightAnchor.constraint(equalToConstant: 0.33).isActive = true
        
        confirmPasswordStackView = VerticalStackView(arrangedSubviews: [
            confirmPasswordLabel,
            HorizontalStackView(arrangedSubviews: [confirmPasswordTextField, isSecureImage2], spacing: 20, distrubiton: .fill),
        ], spacing: 10)
        
        isSecureImage2.image = UIImage(systemName: "eye.slash.fill")
        isSecureImage2.tintColor = .darkGray
        isSecureImage2.heightAnchor.constraint(equalToConstant: 22).isActive = true
        isSecureImage2.widthAnchor.constraint(equalToConstant: 28).isActive = true
        
        scrollView.addSubview(confirmPasswordStackView)
        confirmPasswordStackView.anchor(top: passwordStackView.bottomAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 40, left: 30, bottom: 0, right: 30))
        scrollView.addSubview(lineViewConfirmPassword)
        lineViewConfirmPassword.anchor(top: confirmPasswordStackView.bottomAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 10, left: 20, bottom: 0, right: 20))
        scrollView.addSubview(notMatchLabel2)
        scrollView.addSubview(passwordSameCorrect2)
        
        passwordSameCorrect2.anchor(top: lineViewConfirmPassword.bottomAnchor, leading: lineViewConfirmPassword.leadingAnchor, bottom: nil, trailing: nil, padding: .init(top: 2, left: 0, bottom: 0, right: 0))
        notMatchLabel2.anchor(top: lineViewConfirmPassword.bottomAnchor, leading: lineViewConfirmPassword.leadingAnchor, bottom: nil, trailing: nil, padding: .init(top: 2, left: 0, bottom: 0, right: 0))
    }
    
    private func setupPhoneStack() {
        lineViewCode.backgroundColor = .black
        lineViewCode.translatesAutoresizingMaskIntoConstraints = false
        lineViewCode.heightAnchor.constraint(equalToConstant: 0.33).isActive = true
        
        lineViewPhone.backgroundColor = .black
        lineViewPhone.translatesAutoresizingMaskIntoConstraints = false
        lineViewPhone.heightAnchor.constraint(equalToConstant: 0.33).isActive = true
        
        countryCodeTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        countryCodeTextField.leftViewMode = .always
        let codeStackView = VerticalStackView(arrangedSubviews: [
            countryCodeLabel, countryCodeTextField, lineViewCode
        ], spacing: 10)
        codeStackView.widthAnchor.constraint(equalToConstant: 80).isActive = true
        
        let phoneNumberStackView = VerticalStackView(arrangedSubviews: [
            phoneNumberLabel, phoneTextField, lineViewPhone
        ], spacing: 10)
        phoneStackView = UIStackView(arrangedSubviews: [
            HorizontalStackView(arrangedSubviews: [
                codeStackView,
                phoneNumberStackView
            ], spacing: 20, distrubiton: .fillProportionally)
        ])
        
        scrollView.addSubview(phoneStackView)
        phoneStackView.anchor(top: confirmPasswordStackView.bottomAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 35, left: 30, bottom: 0, right: 30))
        
        saveButton.setTitle("Save", for: .normal)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.backgroundColor = .link
        saveButton.layer.cornerRadius = 12
        saveButton.layer.shadowColor = UIColor.link.cgColor
        saveButton.layer.shadowOffset = CGSize(width: 0, height: 4) // Shadow'ın yatay ve dikey ofset değerleri
        saveButton.layer.shadowRadius = 4
        saveButton.layer.shadowOpacity = 0.5
        scrollView.addSubview(saveButton)
        saveButton.anchor(top: phoneStackView.bottomAnchor, leading: nil, bottom: nil, trailing: nil, padding: .init(top: 50, left: 0, bottom: 0, right: 0), size: .init(width: 120, height: 40))
        saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
    }
}
