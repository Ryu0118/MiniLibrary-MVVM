//
//  RentingCell.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/17.
//

import UIKit
import RxSwift
import RxNuke
import Nuke
import SnapKit

extension NSObject {
    
    func forceCast<T>(_ type: T.Type) -> T {
        return self as! T
    }
    
    func cast<T>(_ type: T.Type) -> T? {
        return self as? T
    }
    
}

class RentingCell : UICollectionViewCell {
    
    static let identifier = "RentingCell"
    static let height = CGFloat(140)
    
    private let disposeBag = DisposeBag()
    
    var bookinfo: BookInfo! {
        didSet {
            //load book thumbnail
            let pipeline = ImagePipeline.shared
            thumbnail.image = UIImage.noimage
            
            if let url = bookinfo.imageURL {
                if let rowRes = bookinfo.lowResImageURL {
                    Observable.concat(pipeline.rx.loadImage(with: URL(string: rowRes)!).asObservable(),
                                      pipeline.rx.loadImage(with: URL(string: url)!).asObservable()
                    )
                        .subscribe(onNext:{[weak self] response in

                            self?.thumbnail.image = response.image
                        })
                        .disposed(by: disposeBag)
                }else{
                    pipeline.rx.loadImage(with: URL(string: url)!)
                        .subscribe(onSuccess: {[weak self] in
                            guard let self = self else { return }
                            self.thumbnail.image = $0.image
                        })
                        .disposed(by: disposeBag)
                }
            }else{
                thumbnail.image = UIImage.noimage
            }
            
            titleLabel.text = bookinfo.title
            titleLabel.numberOfLines = 2

            deadlineLabel.secondText = bookinfo.deadline?.string()
            ownerLabel.secondText = bookinfo.owner
            currentOwnerLabel.secondText = bookinfo.currentOwner
            
            deadlineLabel.firstText = "期限:"
            ownerLabel.firstText = "貸している人:"
            currentOwnerLabel.firstText = "借りている人:"
            
            deadlineLabel.firstView.cast(MiniLibraryLabel.self)?.textColor = .appTextColor
            ownerLabel.firstView.cast(MiniLibraryLabel.self)?.textColor = .appTextColor
            currentOwnerLabel.firstView.cast(MiniLibraryLabel.self)?.textColor = .appTextColor
            deadlineLabel.secondView.cast(MiniLibraryLabel.self)?.textColor = .grayTextColor
            ownerLabel.secondView.cast(MiniLibraryLabel.self)?.textColor = .grayTextColor
            currentOwnerLabel.secondView.cast(MiniLibraryLabel.self)?.textColor = .grayTextColor
            
        }
    }
    
    var thumbnail: UIImageView!
    var titleLabel: MiniLibraryLabel!
    var deadlineLabel: PairView!
    var ownerLabel: PairView!
    var currentOwnerLabel: PairView!
    
    var hstack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        return stack
    }()
    
    var vstack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.distribution = .fillProportionally
        return stack
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.cornerRadius = 10
        self.backgroundColor = .white
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(bookinfo: BookInfo) {
        thumbnail = UIImageView()
        titleLabel = MiniLibraryLabel(size: 16)
        deadlineLabel = PairView(first: MiniLibraryLabel(size: 12), second: MiniLibraryLabel(size: 12))
        ownerLabel = PairView(first: MiniLibraryLabel(size: 12), second: MiniLibraryLabel(size: 12))
        currentOwnerLabel = PairView(first: MiniLibraryLabel(size: 12), second: MiniLibraryLabel(size: 12))
        
        self.bookinfo = bookinfo
        
        hstack.removeAllArrangedSubviews()
        vstack.removeAllArrangedSubviews()
        hstack.addArrangedSubviews([thumbnail, vstack])
        vstack.addArrangedSubviews([titleLabel, deadlineLabel, ownerLabel, currentOwnerLabel])
        vstack.setCustomSpacing(15, after: titleLabel)
        vstack.setCustomSpacing(5, after: deadlineLabel)
        vstack.setCustomSpacing(5, after: ownerLabel)
        
        addSubview(hstack)
        
        hstack.snp.makeConstraints {
            $0.centerX.centerY.equalToSuperview()
            $0.left.equalToSuperview().offset(8)
            $0.right.equalToSuperview().offset(-8)
        }
    }
    
}
