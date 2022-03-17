//
//  UserListView.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/16.
//

import UIKit
import SnapKit


class UserListView : UIView {
    
    static let maxUser = 6
    
    var usersData: [(String, String)]! {
        didSet {
            setup()
        }
    }
    
    private let hstack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillProportionally
        stack.alignment = .bottom
        return stack
    }()
    
    private let otherLabel = MiniLibraryLabel(size: 12)
    
    init(usersData: [(String, String)]) {
        self.usersData = usersData
        super.init(frame: .zero)
        setup()
    }
    
    init() {
        super.init(frame: .zero)
    }
    
    private func setup() {
        addSubview(hstack)
        otherLabel.textColor = .darkGray
        hstack.removeAllArrangedSubviews()
        hstack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(ConstraintInsets(top: 4, left: 4, bottom: 4, right: 4))
        }
        
        var circleIcons = usersData.map { user, colorCode -> CircleIconView in
            return CircleIconView(initialName: user, colorCode: colorCode)
        }
        
        if circleIcons.count > UserListView.maxUser {
            
            let diff = circleIcons.count - UserListView.maxUser
            otherLabel.text = "他\(diff)人"
            for _ in 0..<diff { circleIcons.removeLast() }
            
            hstack.addArrangedSubviews(circleIcons)
            hstack.addArrangedSubview(otherLabel)
            
            circleIcons.enumerated().forEach { i, icon in
                if i + 1 == circleIcons.count {
                    hstack.setCustomSpacing(5, after: icon)
                }else{
                    hstack.setCustomSpacing(-3, after: icon)
                }
                icon.snp.makeConstraints {
                    $0.width.height.equalTo(24)
                }
            }
            
            otherLabel.snp.makeConstraints {
                $0.width.height.lessThanOrEqualToSuperview()
            }
        }
        else{
            hstack.addArrangedSubviews(circleIcons)
            
            circleIcons.forEach { icon in
                hstack.setCustomSpacing(-3, after: icon)
                icon.snp.makeConstraints {
                    $0.width.height.equalTo(24)
                }
            }
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
