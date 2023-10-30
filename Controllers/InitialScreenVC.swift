//
//  InitialScreenVC.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 26.10.2023.
//

import UIKit
import GoogleSignIn
import FirebaseCore
import FirebaseDatabase
import JGProgressHUD
import FirebaseAuth

class InitialScreenVC: UIViewController {
    private let scrollView: UIScrollView = {
       let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    var ivBackground = UIImageView()
    var ivBack = UIImageView()
    var viewColor = UIView()
    var viewLogo = UIView()
    
    var ivLogo = UIImageView()
    var lbLogo = UILabel()
    var lbSol = UILabel()
    
    var btnRegister = UIButton()
    var btnLogin = UIButton()
    var btnGoogle = UIButton()
    var btnFacebook = UIButton()
   // var googleButton = GIDSignInButton()
    
    var lbVer = UILabel()
    var cantLoginLb = UILabel()
    
    var emailTextField = UITextField()
    var passwordTextField = UITextField()
    
    var originalYforLogo: CGFloat = 0
    var originalYforBtn: CGFloat = 0
    var originalYforGoogle: CGFloat = 0
    var originalYforFacebook: CGFloat = 0
    var originalYforEmail: CGFloat = 0
    var originalYforPassword: CGFloat = 0
    var originalYforLabel: CGFloat = 0
    var tapGesture: UITapGestureRecognizer?
    
    private var loginObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loginObserver = NotificationCenter.default.addObserver(forName: Notification.Name.didLogInNotification, object: nil, queue: .main, using: { [weak self] _ in
            guard let strongSelf = self else { return }
            
            strongSelf.navigationController?.dismiss(animated: true)
        })
        view.addSubview(scrollView)
        scrollView.isScrollEnabled = false
        emailTextField.delegate = self
        passwordTextField.delegate = self
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        //scrollView.contentSize = CGSize(width: view.frame.size.width, height: view.frame.size.height)
        scrollView.frame = view.bounds
    }
    
    func setupUI() {
     
        
        setupBackground()
        setupIvBack()
        setupLabelVersion()
        setupLogoView()
        setupButton()
        cantLoginLabelSetup()
        setupTextFields()
    }
    
    func setupTextFields() {
        passwordTextField.isHidden = true
        emailTextField.isHidden = true
        
        scrollView.addSubview(emailTextField)
        emailTextField.autocapitalizationType = .none
        emailTextField.autocorrectionType = .no
        emailTextField.returnKeyType = .continue
        emailTextField.layer.cornerRadius = 24
       // emailTextField.layer.borderWidth = 0.6
       // emailTextField.layer.borderColor = UIColor.lightGray.cgColor
        emailTextField.placeholder = "Email Address..."
        emailTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 0))
        emailTextField.leftViewMode = .always
        emailTextField.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        
        emailTextField.anchor(top: lbLogo.bottomAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 30, left: 50, bottom: 0, right: 50), size: .init(width: 0, height: 60))
        
        scrollView.addSubview(passwordTextField)
        passwordTextField.autocapitalizationType = .none
        passwordTextField.autocorrectionType = .no
        passwordTextField.returnKeyType = .done
        passwordTextField.layer.cornerRadius = 24
      //  passwordTextField.layer.borderWidth = 0.6
      //  passwordTextField.layer.borderColor = UIColor.lightGray.cgColor
        passwordTextField.placeholder = "Password"
        passwordTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 0))
        passwordTextField.leftViewMode = .always
        passwordTextField.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        passwordTextField.isSecureTextEntry = true
        
        passwordTextField.anchor(top: emailTextField.bottomAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 20, left: 50, bottom: 0, right: 50), size: .init(width: 0, height: 60))
        
    }

    @objc func backScreen() {
        emailTextField.text = ""
        passwordTextField.text = ""
        ivBack.isHidden = true
        if isAnimationCompleted {
            // Eğer animasyon tamamlandıysa, geri alın
            UIView.animate(withDuration: 0.8, delay: 0, options: .curveEaseOut, animations: {
                self.cantLoginLb.isHidden = true
                self.btnGoogle.isHidden = true
                self.btnFacebook.isHidden = true
                self.btnRegister.isHidden = false
                self.passwordTextField.isHidden = true
                self.emailTextField.isHidden = true
                self.btnLogin.frame.origin.y = self.originalYforBtn
                self.btnGoogle.frame.origin.y = self.originalYforGoogle
                self.btnFacebook.frame.origin.y = self.originalYforFacebook
                self.lbLogo.frame.origin.y = self.originalYforLogo
                self.emailTextField.frame.origin.y = self.originalYforEmail
                self.passwordTextField.frame.origin.y = self.originalYforPassword
                self.cantLoginLb.frame.origin.y = self.originalYforLabel
            }) { (completed) in
                if completed {
                    // Animasyon tamamlandığında bayrağı false olarak işaretleyin.
                    self.isAnimationCompleted = false
                    // Eklenen butonları kaldırın
                }
            }
        }
    }

    var isAnimationCompleted = false

    @objc private func goToLogin() {
        
        ivBack.isHidden = false
        if !isAnimationCompleted {
            // Eğer animasyon başladıysa, başlangıçtaki orijinal değerleri kaydedin
            originalYforLogo = lbLogo.frame.origin.y
            originalYforBtn = btnLogin.frame.origin.y
            originalYforEmail = emailTextField.frame.origin.y
            originalYforPassword = passwordTextField.frame.origin.y
            originalYforGoogle = btnGoogle.frame.origin.y
            originalYforLabel = cantLoginLb.frame.origin.y
            originalYforFacebook = btnFacebook.frame.origin.y
            
            let targetYforLogo: CGFloat = lbLogo.frame.origin.y - 154
            let targetYforEmail: CGFloat = emailTextField.frame.origin.y - 154
            let targetYforPassword: CGFloat = passwordTextField.frame.origin.y - 154
           
            UIView.animate(withDuration: 0.8, delay: 0, options: .curveEaseOut, animations: {
                self.cantLoginLb.isHidden = false
                self.passwordTextField.isHidden = false
                self.emailTextField.isHidden = false
                self.btnRegister.isHidden = true
                self.btnGoogle.isHidden = false
                self.btnFacebook.isHidden = false
                self.lbLogo.frame.origin.y = targetYforLogo
                self.emailTextField.frame.origin.y = targetYforEmail
                self.passwordTextField.frame.origin.y = targetYforPassword
                self.btnLogin.frame.origin.y = targetYforPassword + 90
                self.btnGoogle.frame.origin.y = targetYforPassword + 160
                self.btnFacebook.frame.origin.y = targetYforPassword + 160
                self.cantLoginLb.frame.origin.y = targetYforPassword + 230
            }) { (completed) in
                if completed {
                    // Animasyon tamamlandığında bayrağı true olarak işaretleyin.
                    self.isAnimationCompleted = true
                   
                }
            }
        } else {
            FirebaseAuthManager.signInWithFirebase(viewController: self, email: emailTextField.text ?? "", password: passwordTextField.text ?? "") { success in
                
                self.emailTextField.resignFirstResponder()
                self.passwordTextField.resignFirstResponder()
                
                if success {
                    print("giriş başarılı")
                    self.navigationController?.dismiss(animated: true)
                } else {
                    print("giriş başarısız")
                }
            }
        }
        
        
    }
    
    func setupButton() {
        // add buttons
        btnGoogle.isHidden = true
        btnFacebook.isHidden = true
        scrollView.addSubview(btnRegister)
        scrollView.addSubview(btnGoogle)
        scrollView.addSubview(btnFacebook)
        
        btnGoogle.translatesAutoresizingMaskIntoConstraints = false
        btnGoogle.bottomAnchor.constraint(equalTo: lbVer.topAnchor, constant: -80).isActive = true
        btnGoogle.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor, constant: -40).isActive = true
        btnGoogle.heightAnchor.constraint(equalToConstant: 60).isActive = true
        btnGoogle.widthAnchor.constraint(equalToConstant: 60).isActive = true
        
        if let originalImage = UIImage(named: "google2") {
            let imageSize = CGSize(width: 30, height: 30) // Ayarlamak istediğiniz boyutu burada belirleyin
            UIGraphicsBeginImageContextWithOptions(imageSize, false, 0.0)
            originalImage.draw(in: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            btnGoogle.setImage(resizedImage, for: .normal)
            
        }
        btnGoogle.addTarget(self, action: #selector(signInWithGoogle), for: .touchUpInside)
        btnGoogle.backgroundColor = UIColor.white.withAlphaComponent(0.6)
        
        btnFacebook.translatesAutoresizingMaskIntoConstraints = false
        btnFacebook.anchor(top: nil, leading: nil, bottom: lbVer.topAnchor, trailing: nil, padding: .init(top: 0, left: 0, bottom: 80, right: 0), size: .init(width: 60, height: 60))
        btnFacebook.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 40).isActive = true

        if let originalImage = UIImage(named: "facebook") {
            let imageSize = CGSize(width: 30, height: 30) // Ayarlamak istediğiniz boyutu burada belirleyin
            UIGraphicsBeginImageContextWithOptions(imageSize, false, 0.0)
            originalImage.draw(in: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            btnFacebook.setImage(resizedImage, for: .normal)
        }
        btnFacebook.backgroundColor = UIColor.white.withAlphaComponent(0.6)
        btnFacebook.addTarget(self, action: #selector(signInWithFacebook), for: .touchUpInside)

        
        btnRegister.translatesAutoresizingMaskIntoConstraints = false
        btnRegister.anchor(top: nil, leading: view.leadingAnchor, bottom: lbVer.topAnchor, trailing: view.trailingAnchor, padding: .init(top: 0, left: 50, bottom: 80, right: 50), size: .init(width: 0, height: 60))
        btnRegister.setTitle("Register", for: .normal)
        btnRegister.setTitleColor(UIColor(#colorLiteral(red: 0.1999999881, green: 0.1999999881, blue: 0.1999999881, alpha: 1)), for: .normal)
        btnRegister.backgroundColor = UIColor.white.withAlphaComponent(0.6)
        btnRegister.titleLabel?.font = UIFont(name: "Gratina", size: 16)
        btnRegister.addTarget(self, action: #selector(goToRegister), for: .touchUpInside)
        
        scrollView.addSubview(btnLogin)
        btnLogin.translatesAutoresizingMaskIntoConstraints = false
        btnLogin.anchor(top: nil, leading: view.leadingAnchor, bottom: btnRegister.topAnchor, trailing: view.trailingAnchor, padding: .init(top: 0, left: 50, bottom: 20, right: 50), size: .init(width: 0, height: 60))
        btnLogin.setTitle("Login", for: .normal)
        btnLogin.setTitleColor(UIColor(#colorLiteral(red: 0.1999999881, green: 0.1999999881, blue: 0.1999999881, alpha: 1)), for: .normal)
        btnLogin.backgroundColor = UIColor.white.withAlphaComponent(0.6)
        btnLogin.titleLabel?.font = UIFont(name: "Gratina", size: 16)
        btnLogin.addTarget(self, action: #selector(goToLogin), for: .touchUpInside)
        
        
        roundCorner(views: [btnFacebook, btnGoogle ,btnLogin, btnRegister], radius: 30)
        
    }
    
    deinit {
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    @objc func signInWithFacebook() {
        
    }
    
    @objc func signInWithGoogle() {
        GoogleSignInManager.signInWithGoogle(viewController: self) { succes in
            if succes {
                print("success")
            } else {
                print("error")
            }
        }
    }
    
    func cantLoginLabelSetup() {
        cantLoginLb.isHidden = true
        scrollView.addSubview(cantLoginLb)
        let fullText = "Can't login? Forgot Password"
        let attributedString = NSMutableAttributedString(string: fullText)

        // Mavi rengi ayarla
        let range = (fullText as NSString).range(of: "Forgot Password")
        attributedString.addAttribute(.foregroundColor, value: UIColor.link, range: range)
        cantLoginLb.font = .systemFont(ofSize: 13, weight: .regular)
        // Label'a özellikli metni ayarla
        cantLoginLb.attributedText = attributedString
        cantLoginLb.translatesAutoresizingMaskIntoConstraints = false
        cantLoginLb.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        cantLoginLb.topAnchor.constraint(equalTo: btnRegister.bottomAnchor, constant: 10).isActive = true
        
    }
    
    func setupLabelVersion() {
        // add label version
        scrollView.addSubview(lbVer)
        lbVer.translatesAutoresizingMaskIntoConstraints = false
        lbVer.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        lbVer.bottomAnchor.constraint(equalTo: scrollView.safeAreaLayoutGuide.bottomAnchor, constant: -10).isActive = true
        lbVer.text = "Vit's Flow Talk v1.0"
        lbVer.textColor = .black
        lbVer.textAlignment = .center
        lbVer.font = lbVer.font.withSize(15)
        lbVer.alpha = 0.7
    }
    
    func setupBackground() {
        scrollView.addSubview(ivBackground)
        ivBackground.translatesAutoresizingMaskIntoConstraints = false
        ivBackground.anchor(top: view.topAnchor, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: view.trailingAnchor)
        ivBackground.contentMode = .scaleAspectFill
       // ivBackground.frame = CGRect(x: 0, y: 0, width: scrollView.contentSize.width, height: scrollView.contentSize.height)

        ivBackground.image = UIImage(named: "ivBack2")
    }
    
    func setupLogoView() {
        // add labelLogo
        scrollView.addSubview(lbLogo)
        lbLogo.translatesAutoresizingMaskIntoConstraints = false
        lbLogo.topAnchor.constraint(equalTo: scrollView.safeAreaLayoutGuide.topAnchor, constant: 150).isActive = true
        lbLogo.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        lbLogo.text = "Flow Talk"
        lbLogo.font =  UIFont(name: "Gratina", size: view.frame.width / 9)
        lbLogo.textColor = .black
        lbLogo.sizeToFit()
    }
     
    func setupIvBack() {
        ivBack.isHidden = true
        scrollView.addSubview(ivBack)
        ivBack.translatesAutoresizingMaskIntoConstraints = false
        
        ivBack.topAnchor.constraint(equalTo: scrollView.safeAreaLayoutGuide.topAnchor, constant: 10).isActive = true
        ivBack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20).isActive = true
        ivBack.widthAnchor.constraint(equalToConstant: 25).isActive = true
        ivBack.heightAnchor.constraint(equalToConstant: 25).isActive = true
                
        ivBack.image = UIImage(named: "ic_back")
                
        ivBack.isUserInteractionEnabled = true
        let backTapGesture = UITapGestureRecognizer(target: self, action: #selector(backScreen))
        ivBack.addGestureRecognizer(backTapGesture)
                
    }
    
    func roundCorner(views: [UIView], radius: CGFloat) {
        views.forEach { v in
            v.layer.cornerRadius = radius
            v.layer.masksToBounds = true
            v.layer.borderWidth = 1
            v.layer.borderColor = v.backgroundColor?.cgColor
        }
    }
    
    @objc private func goToRegister() {
        let loginVC = RegisterViewController()
        navigationController?.pushViewController(loginVC, animated: true)
    }
}

extension InitialScreenVC: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            goToLogin()
        }
        
        return true
    }

}
