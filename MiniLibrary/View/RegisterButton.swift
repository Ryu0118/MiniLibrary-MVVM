//
//  RegisterButton.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/15.
//

import UIKit
import RxCocoa
import RxSwift

class RegisterButton : UIButton {
    
    private let disposeBag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor(red: 247, green: 105, blue: 102, alpha: 1)
        self.layer.cornerRadius = 10
        self.setTitleColor(.white, for: .normal)
        self.titleLabel?.font = .appFont(size: 16)
        
        bind()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func bind() {
        
        self.rx.controlEvent(.touchDown).asDriver()
            .drive {[weak self] _ in
                UIView.animate(withDuration: 0.1) {
                    self?.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                }
            }
            .disposed(by: disposeBag)
        
        self.rx.controlEvents([.touchUpInside, .touchUpOutside]).asDriver(onErrorJustReturn: ())
            .drive {[weak self] _ in
                UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.3, initialSpringVelocity: 0.1, options: [.overrideInheritedCurve], animations: {
                    self?.transform = .identity
                })
            }
            .disposed(by: disposeBag)
        
    }
    
}

