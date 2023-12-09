//
//  EditProfileViewController.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 6.11.2023.
//

import UIKit
import CountryPicker
import FirebaseAuth
import JGProgressHUD

class EditProfileViewController: UIViewController {
    
    private let scrollView: UIScrollView = {
       let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let spinner = JGProgressHUD()
    
    private let profileImageView = UIImageView()
    private let editPhotoButton = UIButton()
    
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
    
    var name, surname, pass: String?
    var countryCd, phoneNum: Int?
    
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
        
        spinner.textLabel.text = "Your information is being updated. Please wait!"
        self.view.addGlobalUnsafeAreaView()

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
                      let password = userData["user_password"] as? String,
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
                
                self?.name = firstName
                self?.surname = lastName
                self?.pass = password
                self?.countryCd = countryCode
                self?.phoneNum = phoneNumber
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
    
    var filledFields: [String] = []
    var isSelectImg: Bool = false
    
    @objc private func handleSave() {
        
        guard let currentUser = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emaildAddress: currentUser)
      
        guard var firstName = nameTextField.text else { return }
        guard var lastName = surnameTextField.text else { return }
        guard var password = passwordTextField.text else { return }
        guard var countryCodeText = countryCodeTextField.text else { return }
        guard var phoneText = phoneTextField.text else { return }
        var countryCode = Int(countryCodeText)
        var phone = Int(phoneText)
        
        // Dolu olan alanları kontrol et
        //var filledFields: [String] = []

        if !firstName.isEmpty && firstName != nameTextField.placeholder {
            filledFields.append("Name")
        } else {
            firstName = name ?? ""
        }

        if !lastName.isEmpty && lastName != surnameTextField.placeholder {
            filledFields.append("Surname")
        } else {
            lastName = surname ?? ""
        }

        if countryCode != nil || phone != nil {
            filledFields.append("Phone Number")
        } else {
            countryCode = countryCd ?? 0
            phone = phoneNum ?? 0
        }

        if !password.isEmpty {
            filledFields.append("Password")
        } else {
            password = pass ?? ""
        }
        
        let filledFieldsMessage: String
        filledFieldsMessage = filledFields.joined(separator: ", ") + " information will be updated. Are you sure?"
        
        if !filledFields.isEmpty {
            let alert = UIAlertController(title: "Changes", message: filledFieldsMessage, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
                self.spinner.show(in: self.view, animated: true)
                let userInfo = ChatAppUser(firstName: firstName, lastName: lastName, countryCode: countryCode ?? 0, phoneNumber: phone ?? 0, password: password, emailAddress: safeEmail, isOnline: true, lastOnline: "", friends: [], requests: [])
                
                let user = Auth.auth().currentUser
                let credential = EmailAuthProvider.credential(withEmail: currentUser, password: password)
            
                user?.reauthenticate(with: credential, completion: { authResult, error in
                    if error != nil {
                        print("reauthenticate başarısız")
                    }else {
                        print("reauthenticate edildi")
                    }
                })
                
                DatabaseManager.shared.updateProfileInformation(with: userInfo) { [self] success in
                    
                    if success {
                        
                        if isSelectImg {
                            updateProfilePicture(user: userInfo)
                        } else {
                            if let profileViewController = self.navigationController?.viewControllers.first(where: { $0 is ProfileViewController }) as? ProfileViewController {
                                   profileViewController.viewDidLoad()
                               }
                            self.tabBarController?.tabBar.isHidden = false
                            self.navigationController?.popViewController(animated: true)
                        }
                    } else {
                        print("güncellenemedi")
                    }
                }
            }))
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            cancelAction.setValue(UIColor.red, forKey: "titleTextColor")
            alert.addAction(cancelAction)
            
            present(alert, animated: true)
        } else {
           showAlertDialog()
        }
        
              
    }
    
    private func updateProfilePicture(user: ChatAppUser) {
        guard let image = self.profileImageView.image,
                let data = image.pngData() else {
            return
        }

        let fileName = user.profilePictureFileName

        // Bir DispatchGroup oluşturuyoruz. Bu grup, birden fazla asenkron işlemi gruplandırmamıza
        // ve işlemlerin tamamlandığını takip etmemize olanak tanır.
        let group = DispatchGroup()

        // group.enter() ile Dispatch Group'a bir işlem eklenir ve işlem tamamlandığında group.leave() ile bu işlem tamamlandığı belirtilir.
        // Profil resminin silinme işlemi bir asenkron işlem olduğu için defer kullanarak işlem tamamlandığında group.leave() otomatik olarak çağrılır.
        group.enter()
        StorageManager.shared.deleteProfilePicture(fileName: fileName) { success in
            defer {
                group.leave()
            }

            if success {
                print("var olan resim silindi")
            } else {
                print("varolan resim silinemedi")
            }
        }

        // group.notify kısmı, Dispatch Group içindeki tüm işlemler tamamlandığında çalışan bir kapanış bloğudur.
        // Profil resmi silme işlemi ve profil resmi yükleme işlemi bu kapanış bloğu içine alınmıştır.
        // Bu sayede, önce varolan resmin silinmesi beklenir, sonra yeni resmin yüklenmesi gerçekleşir.
        group.notify(queue: .main) {
            // Grup içindeki tüm işlemler tamamlandığında bu kısım çalışır
            print("Tüm işlemler tamamlandı")

            // Yeni resmi yükleme işlemi
            group.enter()
            StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName) { result in
                defer {
                    group.leave()
                }

                switch result {
                case .success(let downloadUrl):
                    print("DOWNLOAD URL: \(downloadUrl)")
                    UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                    // Burada sadece profil resmi yüklendikten sonra yapılmasını istediğiniz işlemleri ekleyebilirsiniz
                    self.spinner.dismiss(animated: true)
                    if let profileViewController = self.navigationController?.viewControllers.first(where: { $0 is ProfileViewController }) as? ProfileViewController {
                           profileViewController.viewDidLoad()
                       }
                    self.tabBarController?.tabBar.isHidden = false
                    self.navigationController?.popViewController(animated: true)
                case .failure(let error):
                    print("profile picture upload error: \(error)")
                }
            }
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
        
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 50
        profileImageView.layer.masksToBounds = true
        profileImageView.backgroundColor = .gray
        profileImageView.isUserInteractionEnabled = true
        scrollView.addSubview(profileImageView)
        
       // let gesture = UITapGestureRecognizer(target: self, action: #selector(presentPhotoActionSheet))
       // profileImageView.addGestureRecognizer(gesture)
        
        profileImageView.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: nil, bottom: nil, trailing: nil, padding: .init(top: 20, left: 0, bottom: 0, right: 0), size: .init(width: 100, height: 100))
        profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        editPhotoButton.backgroundColor = .black
        editPhotoButton.layer.cornerRadius = 12
        editPhotoButton.setImage(UIImage(named: "edit-5"), for: .normal)
        scrollView.addSubview(editPhotoButton)
        editPhotoButton.addTarget(self, action: #selector(presentPhotoActionSheet), for: .touchUpInside)
        editPhotoButton.anchor(top: nil, leading: nil, bottom: profileImageView.bottomAnchor, trailing: profileImageView.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 5, right: 5), size: .init(width: 24, height: 24))
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
        
        confirmPasswordTextField.isSecureTextEntry = true
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

extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @objc func presentPhotoActionSheet() {
        
        let alert = UIAlertController(title: "Profile Picture", message: "How would you like to select a picture?", preferredStyle: .actionSheet)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        cancelAction.setValue(UIColor.red, forKey: "titleTextColor")
        alert.addAction(cancelAction)
        
        let takeAction = UIAlertAction(title: "Take Photo", style: .default) { _ in
            self.presentCamera()
        }
        alert.addAction(takeAction)
        
        let choseAction = UIAlertAction(title: "Chose Photo", style: .default) { _ in
            self.presentPhotoPicker()
        }
        alert.addAction(choseAction)
        
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
        
        self.profileImageView.image = selectedImage
        self.filledFields.append("Profile picture")
        self.isSelectImg = true
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        if isSelectImg {
            
            print("fotoğraf seçildi isSelecti false yapma")
        }
        picker.dismiss(animated: true)
    }
}
