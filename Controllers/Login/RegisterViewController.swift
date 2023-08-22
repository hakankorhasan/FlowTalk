//
//  RegisterViewController.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 22.08.2023.
//

import UIKit

class RegisterViewController: UIViewController {

    private let scrollView: UIScrollView = {
       let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "head")
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    let firstName: UITextField = {
       let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 0.6
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "First Name..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        return field
    }()

    let lastName: UITextField = {
       let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 0.6
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Last Name..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        return field
    }()

    
    let emailTextField: UITextField = {
       let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 0.6
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Email Address..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        return field
    }()

    let passwordTextField: UITextField = {
       let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 0.6
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Password"
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        field.isSecureTextEntry = true
        return field
    }()
    
    private let loginButton: UIButton = {
       let button = UIButton()
        button.setTitle("Register", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: .plain, target: self, action: #selector(didTapRegister))
        
        loginButton.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(firstName)
        scrollView.addSubview(lastName)
        scrollView.addSubview(emailTextField)
        scrollView.addSubview(passwordTextField)
        scrollView.addSubview(loginButton)
        
        imageView.isUserInteractionEnabled = true
        scrollView.isUserInteractionEnabled = true
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapChangeProfilePic))
        imageView.addGestureRecognizer(gesture)
    }
    
    @objc private func didTapChangeProfilePic() {
        print("tapped")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        
        let size = scrollView.width / 3
        imageView.frame = CGRect(x: CGFloat(Int((scrollView.width-size)) / 2), y: 20, width: size, height: size)
        
        firstName.frame = CGRect(x: 30, y: imageView.bottom + 10, width: scrollView.width - 60, height: 50)
        
        lastName.frame = CGRect(x: 30, y: firstName.bottom + 10, width: scrollView.width - 60, height: 50)
        
        emailTextField.frame = CGRect(x: 30, y: lastName.bottom + 10, width: scrollView.width - 60, height: 50)
        
        passwordTextField.frame = CGRect(x: 30, y: emailTextField.bottom + 10, width: scrollView.width - 60, height: 50)
        
        loginButton.frame = CGRect(x: 30, y: passwordTextField.bottom + 10, width: scrollView.width - 60, height: 50)
    }
    
    @objc private func handleLogin() {
       
        //login butonuna basınca keyboardı kapatmak için bu iki satırı yazdık
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
        
        guard let email = emailTextField.text,
              let password = passwordTextField.text,
              let firstName = firstName.text,
              let lastName = lastName.text,
              !email.isEmpty,
              !firstName.isEmpty,
              !lastName.isEmpty,
              !password.isEmpty,
              password.count >= 6 else {
            alertUserLoginError()
            return
        }
    }
    
    func alertUserLoginError() {
        let alert = UIAlertController(title: "Woops", message: "Please enter all information to create a new account", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel))
        
        present(alert, animated: true)
    }
    
    @objc private func didTapRegister() {
        let vc = RegisterViewController()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension RegisterViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            handleLogin()
        }
        
        return true
    }
}
