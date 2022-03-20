//
//  LibraryHeaderView.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/18.
//

import UIKit

class LibraryHeaderView : UICollectionReusableView {
    
    static let identifier = "LibraryHeaderView"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup(indexPath: IndexPath) {
        subviews.forEach { $0.removeFromSuperview() }
        let titleLabel = MiniLibraryLabel(size: 20)
        addSubview(titleLabel)
        
        switch indexPath.section {
        case 0:
            titleLabel.text = "貸出中の本"
            titleLabel.snp.makeConstraints {
                $0.left.centerY.equalToSuperview()
            }
        case 1:
            titleLabel.text = "全ての本"
            titleLabel.snp.makeConstraints {
                $0.centerY.equalToSuperview()
                $0.left.equalToSuperview().offset(8)
            }
        default:
            break
        }
    }
    
}
