//
//  LoginViewController.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/15.
//

import UIKit
import RxSwift
import RxCocoa
import Firebase
import RxKeyboard
import KRProgressHUD

class LoginViewController : UIViewController {
    
    private var titleLabel: MiniLibraryLabel!
    private var emailTextField: AuthTextField!
    private var passwordTextField: AuthTextField!
    private var signInButton: RegisterButton!
    private var newRegisterButton: UIButton!
    private var vstack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.distribution = .fillProportionally
        stack.alignment = .center
        return stack
    }()
    
    private let disposeBag = DisposeBag()
    private let viewModel = LoginViewModel()
    private lazy var viewHeight = self.view.frame.origin.y
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .appBackgroundColor
        setupViews()
        addGestureRecognizer()
        bind()
    }
    
}

//MARK: private methods

extension LoginViewController {
    
    private func bind() {
        newRegisterButton.rx
            .controlEvents([.touchUpInside, .touchUpOutside])
            .asDriver(onErrorJustReturn: ())
            .drive {[weak self] _ in
                guard let self = self else { return }
                let registerVC = RegistrationViewController()
                registerVC.modalTransitionStyle = .flipHorizontal
                registerVC.modalPresentationStyle = .fullScreen
                self.present(registerVC, animated: true, completion: nil)
            }
            .disposed(by: disposeBag)
        
        emailTextField.rx.text.orEmpty
            .bind(to: viewModel.inputs.emailObserver)
            .disposed(by: disposeBag)
        
        passwordTextField.rx.text.orEmpty
            .bind(to: viewModel.inputs.passwordObserver)
            .disposed(by: disposeBag)
        
        Observable.merge(
                signInButton.rx.controlEvent(.touchUpInside).asObservable(),
                passwordTextField.rx.controlEvent(.editingDidEndOnExit).asObservable()
            )
            .observe(on: MainScheduler.instance)
            .withLatestFrom(viewModel.outputs.isEnabledButton.asObservable())
            .do {[unowned self] isEnabled in
                if !isEnabled {
                    UIAlertController.show(target: self, title: "正しいメールアドレスを入力してください", message: nil, prefferedStyle: .alert, actionTitles: ["おけ"], actionStyles: [.default], actionHandlers: [nil])
                }else{
                    KRProgressHUD.show()
                }
            }
            .filter { $0 }
            .flatMapLatest {[unowned self] isEnabled -> Observable<LoginInfo> in
                return Observable<LoginInfo>.just(LoginInfo(email: emailTextField.text, password: passwordTextField.text))
            }
            .bind(to: viewModel.inputs.loginObserver)
            .disposed(by: disposeBag)
        
        RxKeyboard.instance.visibleHeight
            .drive { [weak self] height in
                guard let self = self else { return }
                var originalHeight = self.viewHeight
                originalHeight -= height / 2
                self.view.frame.origin.y = originalHeight
            }
            .disposed(by: disposeBag)

        viewModel.outputs.isSuccessLogin
            .asDriver(onErrorJustReturn: false)
            .do { _ in
                KRProgressHUD.dismiss()
            }
            .drive {[unowned self] isSuccess in
                if isSuccess {
                    let vc = ViewController()
                    vc.modalPresentationStyle = .fullScreen
                    vc.modalTransitionStyle = .crossDissolve
                    present(vc, animated: true, completion: nil)
                }else{
                    UIAlertController.show(target: self, title: "失敗", message: nil, prefferedStyle: .alert, actionTitles: ["おけ"], actionStyles: [.default], actionHandlers: [nil])
                }
            }
            .disposed(by: disposeBag)
    }
    
    private func addGestureRecognizer() {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(keyboardDismiss))
        view.addGestureRecognizer(gesture)
    }
    
    @objc private func keyboardDismiss() {
        [emailTextField, passwordTextField].forEach { textField in
            textField?.endEditing(true)
        }
    }
    
    private func setupViews() {
        titleLabel = MiniLibraryLabel(size: 40)
        emailTextField = AuthTextField(textFieldType: .emailAddress, placeHolder: "メールアドレスを入力")
        passwordTextField = AuthTextField(textFieldType: .default, placeHolder: "パスワードを入力", isPassword: true)
        signInButton = RegisterButton()
        newRegisterButton = UIButton()
        
        titleLabel.text = "MiniLibrary"
        titleLabel.textAlignment = .center
        
        signInButton.setTitle("ログイン", for: .normal)
        
        newRegisterButton.setTitle("新規登録", for: .normal)
        newRegisterButton.setTitleColor(.systemBlue, for: .normal)
        newRegisterButton.titleLabel?.font = .appFont
        
        vstack.addArrangedSubviews([titleLabel, emailTextField, passwordTextField, signInButton, newRegisterButton])
        
        vstack.setCustomSpacing(70, after: titleLabel)
        vstack.setCustomSpacing(8, after: emailTextField)
        vstack.setCustomSpacing(70, after: passwordTextField)
        vstack.setCustomSpacing(13, after: signInButton)
        
        view.addSubview(vstack)
        
        vstack.snp.makeConstraints {
            $0.left.equalTo(view.safeAreaLayoutGuide).offset(15)
            $0.right.equalTo(view.safeAreaLayoutGuide).offset(-15)
            $0.centerY.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints {
            $0.width.equalToSuperview()
            $0.height.equalTo(60)
        }
        
        [emailTextField, passwordTextField, signInButton].forEach { textField in
            textField.snp.makeConstraints {
                $0.width.equalToSuperview()
                $0.height.equalTo(50)
            }
        }
        
        newRegisterButton.snp.makeConstraints {
            $0.width.equalTo(100)
            $0.height.equalTo(20)
        }
        
    }
    
}

//MARK: internal methods

extension LoginViewController {
    
}
