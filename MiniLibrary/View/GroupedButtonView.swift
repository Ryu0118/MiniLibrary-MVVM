//
//  GroupedButtonView.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/17.
//

import UIKit
import SnapKit

class GroupedButtonView: UIView {
    
    let systemName1: String
    let systemName2: String
    
    private lazy var hstack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [leftButton, rightButton])
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.isUserInteractionEnabled = false
        return stack
    }()
    
    lazy var leftButton: UIButton = {
        let button = UIButton()
        let configuration = UIImage.SymbolConfiguration(pointSize: 22, weight: .regular, scale: .default)
        button.setImage(UIImage(systemName: systemName1, withConfiguration: configuration), for: .normal)
        button.tintColor = .black
        button.isUserInteractionEnabled = true
        return button
    }()
    
    lazy var rightButton: UIButton = {
        let button = UIButton()
        let configuration = UIImage.SymbolConfiguration(pointSize: 22, weight: .regular, scale: .default)
        button.setImage(UIImage(systemName: systemName2, withConfiguration: configuration), for: .normal)
        button.tintColor = .black
        return button
    }()
    
    
    init(item1SystemName: String, item2SystemName: String) {
        self.systemName1 = item1SystemName
        self.systemName2 = item2SystemName
        
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        addSubview(hstack)
        hstack.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
}

