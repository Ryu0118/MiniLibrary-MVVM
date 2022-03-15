//
//  AuthTextField.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/15.
//

import UIKit
import RxCocoa
import RxSwift
import SnapKit

class AuthTextField : UIView {
    
    private let field: AuthTextFieldCore
    private let disposeBag = DisposeBag()
    
    var text: String {
        get { field.text ?? ""  }
        set { field.text = newValue }
    }
    var rx:Reactive<AuthTextFieldCore> { return field.rx }
    
    
    init(textFieldType: UIKeyboardType, placeHolder: String, isPassword: Bool = false) {
        self.field = AuthTextFieldCore(textFieldType: textFieldType, placeHolder: placeHolder, isPassword: isPassword)
        super.init(frame: .zero)
        setup()
        bind()
        addGesture()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func setup() {
        self.backgroundColor = .white
        self.layer.cornerRadius = 10
        addSubview(field)
        field.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(ConstraintInsets(top: 10, left: 10, bottom: 10, right: 10))
        }
    }
    
    private func bind() {
        
        self.rx.controlEvent(.editingDidBegin).asDriver()
            .drive {[weak self] _ in
                guard let self = self else { return }
                
                self.layer.borderWidth = 2
                self.layer.borderColor = UIColor.systemBlue.cgColor
                self.layoutIfNeeded()
            }
            .disposed(by: disposeBag)
        
        self.rx.controlEvent(.editingDidEnd).asDriver()
            .drive {[weak self] _ in
                guard let self = self else { return }
                
                self.layer.borderWidth = 0
                self.layer.borderColor = UIColor.clear.cgColor
                self.layoutIfNeeded()
            }
            .disposed(by: disposeBag)
    }
    
    private func addGesture() {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(keyboardShow))
        self.addGestureRecognizer(gesture)
    }
    
    @objc private func keyboardShow() {
        field.becomeFirstResponder()
    }
    
}
 
class AuthTextFieldCore : UITextField {

    var textFieldType: UIKeyboardType
    private var placeHolderAttribute: [NSAttributedString.Key : Any] = [
        .font: UIFont.appFont,
        .foregroundColor: UIColor.lightGray
    ]
    private let disposeBag = DisposeBag()
    
    init(textFieldType: UIKeyboardType, placeHolder: String, isPassword: Bool = false) {
        self.textFieldType = textFieldType
        super.init(frame: .zero)
        self.attributedPlaceholder = NSMutableAttributedString(string: placeHolder, attributes: placeHolderAttribute)
        self.layer.cornerRadius = 10
        self.keyboardType = textFieldType
        self.isSecureTextEntry = isPassword
        self.backgroundColor = .white
        self.font = .appFont
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
}
