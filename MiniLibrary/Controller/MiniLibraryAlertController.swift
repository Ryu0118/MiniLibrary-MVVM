//
//  MiniLibraryAlertController.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/16.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import RxKeyboard

class MiniLibraryAlertAction {
    
    enum Option {
        case normal
        case cancel
    }
    
    let message: String
    let handler: (() -> ())?
    let option: Option
    
    init(message: String, option: Option, handler: (() -> ())?) {
        self.message = message
        self.option = option
        self.handler = handler
    }
}

struct TextfieldConfiguration {
    let placeholder: String
    let keyboardType: UIKeyboardType
}

class MiniLibraryAlertController : UIViewController {
    
    var titleText: String?
    var bigMessage: String?
    var message: String?
    var image: UIImage?
    var textfieldConfiguration: TextfieldConfiguration?
    var customViews: [UIView]?
    var actions: [MiniLibraryAlertAction]
    var width_multipledBy: CGFloat
    var confirmAlert: MiniLibraryAlertController?
    weak var target: UIViewController?
    
    var titleLabel: MiniLibraryLabel? {
        didSet {
            guard let titleLabel = titleLabel else { return }
            titleLabel.textColor = .appTextColor
            titleLabel.numberOfLines = 0
            titleLabel.sizeToFit()
            titleLabel.lineBreakMode = .byTruncatingTail
            titleLabel.textAlignment = .center
        }
    }
    var messageLabel: MiniLibraryLabel? {
        didSet {
            guard let messageLabel = messageLabel else { return }
            messageLabel.textColor = .grayTextColor
            messageLabel.numberOfLines = 7
            messageLabel.lineBreakMode = .byTruncatingTail
            messageLabel.textAlignment = .center
        }
    }
    var bigMessageLabel: MiniLibraryLabel? {
        didSet {
            guard let messageLabel = bigMessageLabel else { return }
            messageLabel.textColor = .appTextColor
            messageLabel.numberOfLines = 1
            messageLabel.textAlignment = .center
        }
    }
    var imageView: UIImageView? {
        didSet {
            guard let imageView = imageView else { return }
            imageView.contentMode = .scaleAspectFit
        }
    }

    var textField: AuthTextField?
    var leftButton: RegisterButton?
    var rightButton: RegisterButton?
    
    private let disposeBag = DisposeBag()
    private lazy var viewHeight = self.view.frame.origin.y
    
    var vstack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.distribution = .fillProportionally
        stack.spacing = 10
        return stack
    }()
    
    var hstack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        return stack
    }()
    
    lazy var baseView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()
    
    lazy var alertView: UIView = {
        let view = UIView()
        view.backgroundColor = .appBackgroundColor
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        return view
    }()
    
    init(title: String? = nil, image: UIImage? = nil, bigMessage: String? = nil, message: String? = nil, textFieldConfiguration: TextfieldConfiguration? = nil, multipledBy: CGFloat = 0.7, actions: [MiniLibraryAlertAction] = []) {
        self.titleText = title
        self.image = image
        self.bigMessage = bigMessage
        self.message = message
        self.textfieldConfiguration = textFieldConfiguration
        self.width_multipledBy = multipledBy
        self.actions = actions
        super.init(nibName: nil, bundle: nil)
        setupViewController()
    }
    
    init(customViews: [UIView], actions: [MiniLibraryAlertAction] = [], multipledBy: CGFloat = 0.7) {
        self.customViews = customViews
        self.actions = actions
        self.width_multipledBy = multipledBy
        super.init(nibName: nil, bundle: nil)
        setupViewController()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAlertView()
        setupCustomView()
        bind()
        textField?.becomeFirstResponder()
    }
    
    func addActions(_ actions: [MiniLibraryAlertAction]) {
        self.actions.append(contentsOf: actions)
    }
    
    func addAction(_ action: MiniLibraryAlertAction) {
        self.actions.append(action)
    }
    
    func showConfirmAlert(target: UIViewController, title: String, action: MiniLibraryAlertAction) {
        confirmAlert = MiniLibraryAlertController(title: title)
        self.target = target
        let cancel = MiniLibraryAlertAction(message: "キャンセル", option: .cancel, handler: nil)
        confirmAlert?.addAction(cancel)
        confirmAlert?.addAction(action)
    }
    
    private func setupViewController() {
        self.providesPresentationContextTransitionStyle = true
        self.definesPresentationContext = true
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = self
    }
    
    private func setupAlertView() {
        view.addSubview(baseView)
        view.addSubview(alertView)
        
        baseView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        alertView.snp.makeConstraints {
            $0.centerX.centerY.equalToSuperview()
            $0.width.equalToSuperview().multipliedBy(width_multipledBy)
            $0.height.lessThanOrEqualToSuperview().multipliedBy(0.85)
        }
    }
    
    private func setupCustomView() {
        if let image = image {
            imageView = UIImageView(image: image)
        }
        if let titleText = titleText {
            titleLabel = MiniLibraryLabel(size: 18)
            titleLabel?.text = titleText
        }

        if let bigMessage = bigMessage {
            bigMessageLabel = MiniLibraryLabel(size: 25)
            bigMessageLabel?.text = bigMessage
        }
        if let message = message {
            messageLabel = MiniLibraryLabel(size: 12)
            messageLabel?.text = message
        }
        if let textfieldConfiguration = textfieldConfiguration {
            textField = AuthTextField(textFieldType: textfieldConfiguration.keyboardType, placeHolder: textfieldConfiguration.placeholder)
        }
        if actions.count == 2 {
            leftButton = RegisterButton(frame: .zero)
            leftButton?.setTitle(actions[0].message, for: .normal)
            rightButton = RegisterButton(frame: .zero)
            rightButton?.setTitle(actions[1].message, for: .normal)
        }
        else if actions.count == 1 {
            leftButton = RegisterButton(frame: .zero)
            leftButton?.setTitle(actions[0].message, for: .normal)
        }
        if let customViews = customViews { vstack.addArrangedSubviews(customViews) }
        vstack.addArrangedSubviews(([imageView, titleLabel, bigMessageLabel, messageLabel, textField, hstack]).compactMap { $0 })
        hstack.addArrangedSubviews([leftButton, rightButton].compactMap { $0 })
        
        alertView.addSubview(vstack)
        vstack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(ConstraintInsets(top: 8, left: 8, bottom: 8, right: 8))
        }
        hstack.snp.makeConstraints {
            $0.width.equalToSuperview()
        }
        leftButton?.snp.makeConstraints {
            if rightButton != nil {
                $0.width.equalToSuperview().multipliedBy(0.45)
                $0.height.equalTo(35)
            }else{
                $0.width.equalToSuperview()
                $0.height.equalTo(35)
            }
        }
        rightButton?.snp.makeConstraints {
            $0.width.equalToSuperview().multipliedBy(0.45)
            $0.height.equalTo(35)
        }
        imageView?.snp.makeConstraints {
            $0.height.equalTo(280)
        }
        titleLabel?.snp.makeConstraints {
            $0.height.lessThanOrEqualTo(75)
            $0.width.equalToSuperview()
        }
//        messageLabel?.snp.makeConstraints {
//            $0.height.lessThanOrEqualTo(140).priority(.low)
//            $0.height.lessThanOrEqualTo(120).priority(.required)
//        }
    }
    
    private func bind() {
        
        leftButton?.rx.tap
            .asDriver()
            .drive {[weak self] _ in
                self?.actions[0].handler?()
                self?.dismiss(animated: true)
            }
            .disposed(by: disposeBag)
        
        rightButton?.rx.tap
            .asDriver()
            .drive {[weak self] _ in
                self?.actions[1].handler?()
                self?.dismiss(animated: true, completion: {[weak self] in
                    if let confirmAlert = self?.confirmAlert {
                        self?.target?.present(confirmAlert, animated: true, completion: nil)
                    }
                })
            }
            .disposed(by: disposeBag)
        
        RxKeyboard.instance.visibleHeight
            .drive { [weak self] height in
                guard let self = self else { return }
                var originalHeight = self.viewHeight
                originalHeight -= height / 4
                self.view.frame.origin.y = originalHeight
            }
            .disposed(by: disposeBag)
        
    }
    
}

extension MiniLibraryAlertController : UIViewControllerTransitioningDelegate {
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return AlertAnimation(isPresent: true)
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return AlertAnimation(isPresent: false)
    }
    
}

class AlertAnimation: NSObject, UIViewControllerAnimatedTransitioning {
    
    let isPresent: Bool
    
    init(isPresent: Bool) {
        self.isPresent = isPresent
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if isPresent {
            dismissAnimation(transitionContext)
        }else{
            presentAnimation(transitionContext)
        }
    }
    
    func presentAnimation(_ transitionContext: UIViewControllerContextTransitioning) {
        let alert = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) as! MiniLibraryAlertController
        
        let container = transitionContext.containerView
        
        alert.baseView.alpha = 0
        alert.alertView.alpha = 0
        alert.alertView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        container.addSubview(alert.view)
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: [.overrideInheritedOptions, .allowUserInteraction], animations: {
            alert.alertView.alpha = 1
            alert.baseView.alpha = 0.6
            alert.alertView.transform = .identity
        }, completion: { _ in
            transitionContext.completeTransition(true)
        })
    }
    
    func dismissAnimation(_ transitionContext: UIViewControllerContextTransitioning) {
        let alert = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) as! MiniLibraryAlertController
        
        UIView.animate(withDuration: 0.25, animations: {
            alert.baseView.alpha = 0
            alert.alertView.alpha = 0
            alert.alertView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        }, completion: { _ in
            transitionContext.completeTransition(true)
        })
    }
 
}
