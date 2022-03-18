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

            subviews.forEach { $0.removeFromSuperview() }
            pairView = PairView(first: UIImageView(), second: MiniLibraryLabel(size: 10), axis: .vertical, spacing: 3)
            
            titleLabel.text = bookinfo.title
            titleLabel.lineBreakMode = .byTruncatingTail
            titleLabel.numberOfLines = 0
            titleLabel.sizeToFit()
            
            if let url = bookinfo.imageURL {
                
                let pipeline = ImagePipeline.shared
                thumbnail.image = UIImage.noimage
                
                if let rowRes = bookinfo.lowResImageURL { //handle low to high resolution
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
            }
            else {
                thumbnail.image = UIImage.noimage
            }
        }
    }
    
    var pairView: PairView! {
        didSet {
            //pairView.stack.distribution = .
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
            $0.top.left.equalToSuperview().offset(4)
            $0.right.equalTo(-4)
            $0.height.equalTo(self.snp.height).multipliedBy(0.95)
            $0.height.greaterThanOrEqualTo(self.snp.height).multipliedBy(0.69).offset(32)
        }
        
        thumbnail.snp.makeConstraints {
            $0.height.equalToSuperview().multipliedBy(0.69)
            $0.width.equalToSuperview().multipliedBy(0.92)
        }
    }
    
}
