//
//  LibraryListCell.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/16.
//

import UIKit
import SnapKit

class LibraryListCell : UICollectionViewCell {
    
    static let cellHeight: CGFloat = 80
    static let cellMargin: CGFloat = 14
    
    private let vstack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.distribution = .equalSpacing
        stack.alignment = .center
        return stack
    }()
    private let hstack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.alignment = .bottom
        return stack
    }()
    private let titleLabel = MiniLibraryLabel(size: 18)
    private let userListView = UserListView()
    private let bookCountLabel = MiniLibraryLabel(size: 14)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .white
        self.layer.cornerRadius = 20
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        bookCountLabel.textColor = .darkGray
        
        addSubview(vstack)
        vstack.addArrangedSubviews([titleLabel, hstack])
        hstack.addArrangedSubviews([userListView, bookCountLabel])
        vstack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(ConstraintInsets(top: 3, left: 10, bottom: 3, right: 10))
        }
        hstack.snp.makeConstraints {
            $0.width.equalToSuperview()
            $0.height.lessThanOrEqualToSuperview()
        }
    }
    
    func update(library: Library) {
        titleLabel.text = library.library_name
        userListView.usersData = library.usersNameAndColorCode
        bookCountLabel.text = "蔵書数: \(library.books.count)"
    }
    
}
