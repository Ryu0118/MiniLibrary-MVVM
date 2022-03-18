//
//  MemberCell.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/17.
//

import UIKit
import SnapKit

class MemberCell: UITableViewCell {
    
    static let identifier = "MemberCell"
    static let cellHeight = CGFloat(59)
    
    var userList: UserList!
    
    var iconView: CircleIconView!
    var nameLabel: MiniLibraryLabel! {
        didSet {
            nameLabel.text = userList.userName
        }
    }
    var bookOwnedLabel: MiniLibraryLabel! {
        didSet {
            bookOwnedLabel.text = "本所有数: \(userList.bookCount)"
            bookOwnedLabel.textAlignment = .right
            bookOwnedLabel.textColor = .grayTextColor
        }
    }
    
    var hstack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillProportionally
        return stack
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup(userList: UserList) {
        self.userList = userList
        
        hstack.removeAllArrangedSubviews()
        
        iconView = CircleIconView(initialName: String(userList.userName.prefix(1)), colorCode: userList.colorCode)
        nameLabel = MiniLibraryLabel(size: 14)
        bookOwnedLabel = MiniLibraryLabel(size: 12)
        
        hstack.addArrangedSubviews([iconView, nameLabel, bookOwnedLabel])
        hstack.setCustomSpacing(15, after: iconView)
        
        addSubview(hstack)
        hstack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(ConstraintInsets(top: 4, left: 15, bottom: 4, right: 15))
        }
        iconView.snp.makeConstraints {
            $0.width.height.equalTo(42)
        }
    }
}
