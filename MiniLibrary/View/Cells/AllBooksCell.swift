//
//  AllBooksCell.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/17.
//

import UIKit
import RxSwift
import Nuke
import RxNuke
import SnapKit

class AllBooksCell : UICollectionViewCell {
    
    private let disposeBag = DisposeBag()
    static let identifier = "AllBooksCell"
    
    var bookinfo: BookInfo! {
        didSet {
            pairView = PairView(first: UIImageView(), second: MiniLibraryLabel(size: 14))
            
            titleLabel.text = bookinfo.name
            titleLabel.lineBreakMode = .byTruncatingTail
            titleLabel.numberOfLines = 3
            
            if let url = bookinfo.imageURL {
                thumbnail.image = UIImage.noimage
                ImagePipeline.shared.rx.loadImage(with: URL(string: url)!)
                    .subscribe(onSuccess: {[weak self] in
                        guard let self = self else { return }
                        self.thumbnail.image = $0.image
                    })
                    .disposed(by: disposeBag)
            }
            else {
                thumbnail.image = UIImage.noimage
            }
        }
    }
    
    var pairView: PairView! {
        didSet {
            pairView.stack.distribution = .equalSpacing
        }
    }
    
    var thumbnail: UIImageView {
        return pairView.firstView.forceCast(UIImageView.self)
    }
    
    var titleLabel: MiniLibraryLabel {
        return pairView.secondView.forceCast(MiniLibraryLabel.self)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.cornerRadius = 10
        self.backgroundColor = .white
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(bookinfo: BookInfo) {
        self.bookinfo = bookinfo
        addSubview(pairView)
        pairView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(ConstraintInsets(top: 4, left: 2, bottom: 4, right: 2))
        }
    }
    
}
