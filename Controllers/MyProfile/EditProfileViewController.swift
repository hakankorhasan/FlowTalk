//
//  EditProfileViewController.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 6.11.2023.
//

import UIKit

class EditProfileViewController: UIViewController {
    
    private let profileImageView: UIImageView = {
       let iv = UIImageView()
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
    
    private let nameLabel = UILabel(text: "Name", font: .systemFont(ofSize: 12, weight: .regular), textColor: .black, textAlignment: .left, numberOfLines: 0)
    
    private let nameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Name"
        return tf
    }()
    
    let lineViewName = UIView()
    
    private let surnameLabel = UILabel(text: "Surname", font: .systemFont(ofSize: 12, weight: .regular), textColor: .black, textAlignment: .left, numberOfLines: 0)

    
    private let surnameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Surname"
        return tf
    }()
    
    let lineViewSurname = UIView()
    
    private let passwordLabel = UILabel(text: "New Password", font: .systemFont(ofSize: 12, weight: .regular), textColor: .black, textAlignment: .left, numberOfLines: 0)
    
    
    private let passwordTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "New Password"
        return tf
    }()
    
    let lineViewPassword = UIView()
     
    private let confirmPasswordLabel = UILabel(text: "Confirm Password", font: .systemFont(ofSize: 12, weight: .regular), textColor: .black, textAlignment: .left, numberOfLines: 0)
    
    private let confirmPasswordTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Confirm password"
        return tf
    }()
    
    let lineViewConfirmPassword = UIView()
    
    private let countryCodeLabel = UILabel(text: "Country code", font: .systemFont(ofSize: 12, weight: .regular), textColor: .black, textAlignment: .left, numberOfLines: 0)
    
    private let countryCodeTextField: UITextField = {
       let tf = UITextField()
        tf.placeholder = "+XXX"
        return tf
    }()
    
    let lineViewCode = UIView()
    
    private let phoneNumberLabel = UILabel(text: "Phone Number", font: .systemFont(ofSize: 12, weight: .regular), textColor: .black, textAlignment: .left, numberOfLines: 0)
    
    private let phoneTextField: UITextField = {
       let tf = UITextField()
        tf.placeholder = "XXX - XXX - XX - XX"
        return tf
    }()
    
    let lineViewPhone = UIView()
    
    var nameStackView = UIStackView()
    var surnameStackView = UIStackView()
    var passwordStackView = UIStackView()
    var confirmPasswordStackView = UIStackView()
    var phoneStackView = UIStackView()
    
    // Bir etiket dizisi oluşturun
    var labels: [UILabel] = []
    var textFields: [UITextField] = []
    
    var labelTextFieldPairs: [(label: UILabel, textField: UITextField)] = []
    private var labelInitialYPositions = [UILabel: CGFloat]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Edit Profile"
        // Özel bir düğme oluşturun
        let backButton = UIButton(type: .custom)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0) // Sol padding ayarlamak için
        
        labelTextFieldPairs = [
            (nameLabel, nameTextField),
            (surnameLabel, surnameTextField),
            (passwordLabel, passwordTextField),
            (confirmPasswordLabel, confirmPasswordTextField),
            (countryCodeLabel, countryCodeTextField),
            (phoneNumberLabel, phoneTextField)
        ]
        
        // Düğmeye bir eylem ekleyin
        backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)

        // Özel bir bar button oluşturun
        let customBackButton = UIBarButtonItem(customView: backButton)
        backButton.tintColor = .black
        navigationItem.largeTitleDisplayMode = .never
        // Navigasyon çubuğundaki sol düğmeyi ayarlayın
        navigationItem.leftBarButtonItem = customBackButton
        view.backgroundColor = UIColor(#colorLiteral(red: 0.9638196826, green: 0.9687927365, blue: 1, alpha: 1))
        tabBarController?.tabBar.isHidden = true

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
    }
    
   
    
    @objc fileprivate func handleBack() {
        tabBarController?.tabBar.isHidden = false
        self.navigationController?.popViewController(animated: true)
    }
    
   
}

extension EditProfileViewController {
    
    private func setupImageView() {
        view.addSubview(profileImageView)
        profileImageView.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: nil, bottom: nil, trailing: nil, padding: .init(top: 20, left: 0, bottom: 0, right: 0), size: .init(width: 100, height: 100))
        profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        view.addSubview(button)
        button.anchor(top: nil, leading: nil, bottom: profileImageView.bottomAnchor, trailing: profileImageView.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 5, right: 5), size: .init(width: 24, height: 24))
    }
    
    private func setupNameStack() {
        lineViewName.translatesAutoresizingMaskIntoConstraints = false
        lineViewName.heightAnchor.constraint(equalToConstant: 0.33).isActive = true
        lineViewName.backgroundColor = .black
        
        nameStackView = VerticalStackView(arrangedSubviews: [
            nameLabel,
            nameTextField,
         //   lineViewName
        ], spacing: 10)
        
        view.addSubview(nameStackView)
        nameStackView.anchor(top: profileImageView.bottomAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 30, left: 30, bottom: 0, right: 30))
        view.addSubview(lineViewName)
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
        
        view.addSubview(surnameStackView)
        surnameStackView.anchor(top: nameStackView.bottomAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 30, left: 30, bottom: 0, right: 30))
        view.addSubview(lineViewSurname)
        lineViewSurname.anchor(top: surnameStackView.bottomAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 10, left: 20, bottom: 0, right: 20))
    }
    
    private func setupPasswordStack() {
        lineViewPassword.backgroundColor = .black
        lineViewPassword.translatesAutoresizingMaskIntoConstraints = false
        lineViewPassword.heightAnchor.constraint(equalToConstant: 0.33).isActive = true
        
        passwordStackView = VerticalStackView(arrangedSubviews: [
            passwordLabel,
            passwordTextField,
        ], spacing: 10)
        
        view.addSubview(passwordStackView)
        passwordStackView.anchor(top: surnameStackView.bottomAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 30, left: 30, bottom: 0, right: 30))
        view.addSubview(lineViewPassword)
        lineViewPassword.anchor(top: passwordStackView.bottomAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 10, left: 20, bottom: 0, right: 20))
    }
    
    private func setupConfirmPasswordStack() {
        lineViewConfirmPassword.backgroundColor = .black
        lineViewConfirmPassword.translatesAutoresizingMaskIntoConstraints = false
        lineViewConfirmPassword.heightAnchor.constraint(equalToConstant: 0.33).isActive = true
        
        confirmPasswordStackView = VerticalStackView(arrangedSubviews: [
            confirmPasswordLabel,
            confirmPasswordTextField,
        ], spacing: 10)
        
        view.addSubview(confirmPasswordStackView)
        confirmPasswordStackView.anchor(top: passwordStackView.bottomAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 30, left: 30, bottom: 0, right: 30))
        view.addSubview(lineViewConfirmPassword)
        lineViewConfirmPassword.anchor(top: confirmPasswordStackView.bottomAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 10, left: 20, bottom: 0, right: 20))
    }
    
    private func setupPhoneStack() {
        lineViewCode.backgroundColor = .black
        lineViewCode.translatesAutoresizingMaskIntoConstraints = false
        lineViewCode.heightAnchor.constraint(equalToConstant: 0.33).isActive = true
        
        lineViewPhone.backgroundColor = .black
        lineViewPhone.translatesAutoresizingMaskIntoConstraints = false
        lineViewPhone.heightAnchor.constraint(equalToConstant: 0.33).isActive = true
        
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
        
        view.addSubview(phoneStackView)
        phoneStackView.anchor(top: confirmPasswordStackView.bottomAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 30, left: 30, bottom: 0, right: 30))
    }
}

extension EditProfileViewController: UITextFieldDelegate {
    
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
