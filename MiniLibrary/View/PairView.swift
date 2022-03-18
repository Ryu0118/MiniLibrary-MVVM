//
//  PairView.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/17.
//

import UIKit

class PairView : UIView {
    
    let stack: UIStackView
    let firstView: UIView
    let secondView: UIView
    
    var firstText: String? {
        get {
            if firstView is UILabel {
                return firstView.forceCast(UILabel.self).text
            }
            else {
                return nil
            }
        }
        set {
            if firstView is UILabel {
                firstView.forceCast(UILabel.self).text = newValue
            }
        }
    }
    
    var secondText: String? {
        get {
            if secondView is UILabel {
                return secondView.forceCast(UILabel.self).text
            }
            else {
                return nil
            }
        }
        set {
            if secondView is UILabel {
                secondView.forceCast(UILabel.self).text = newValue
            }
        }
    }
    
    init(first: UIView, second: UIView, axis: NSLayoutConstraint.Axis = .horizontal, spacing: CGFloat = 18, constraintsHandler: (() -> ())? = nil) {
        firstView = first
        secondView = second
        stack = UIStackView()
        stack.removeAllArrangedSubviews()
        stack.addArrangedSubviews([first, second])
        stack.axis = axis
        stack.spacing = spacing
        stack.distribution = .fillProportionally
        stack.alignment = .center
        super.init(frame: .zero)
        
        addSubview(stack)
        stack.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        constraintsHandler?()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

