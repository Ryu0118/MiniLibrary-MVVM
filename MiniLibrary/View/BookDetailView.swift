//
//  BookDetailView.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/18.
//

import UIKit
import RxSwift
import RxCocoa
import RxNuke
import Nuke
import SnapKit

class BookDetailView : UIView {
    
    let bookinfo: BookInfo
    let isPresentOwner: Bool
    
    var hstack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillProportionally
        stack.spacing = 10
        return stack
    }()
    
    var minHstack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        return stack
    }()
    
    var vstack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.distribution = .fillProportionally
        stack.spacing = 8
        return stack
    }()
    
    lazy var titleLabel: MiniLibraryLabel = {
        let label = MiniLibraryLabel(size: 18)
        label.text = bookinfo.title
        label.sizeToFit()
        label.numberOfLines = 0
        label.textAlignment = .left
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    lazy var authorLabel: MiniLibraryLabel = {
        let label = MiniLibraryLabel(size: 13)
        label.text = bookinfo.author
        label.textColor = .appTextColor
        label.textAlignment = .left
        return label
    }()
    
    lazy var publicationLabel: MiniLibraryLabel = {
        let label = MiniLibraryLabel(size: 12)
        label.textColor = .gray
        label.textAlignment = .right
        label.text = bookinfo.publication_date
        return label
    }()
    
    lazy var ownerLabel: MiniLibraryLabel = {
        let label = MiniLibraryLabel(size: 12)
        label.textColor = .gray
        label.textAlignment = .right
        if self.isPresentOwner {
            label.text = "所有者: " + bookinfo.owner
        }
        return label
    }()
    
    var thumbnail: UIImageView! {
        didSet {
            
            let pipeline = ImagePipeline.shared
            thumbnail.image = UIImage.noimage
            
            if let url = bookinfo.imageURL {
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
            
        }
    }
    
    private let disposeBag = DisposeBag()
    
    init(bookinfo: BookInfo, isPresentOwner: Bool = true) {
        self.bookinfo = bookinfo
        self.isPresentOwner = isPresentOwner
        super.init(frame: .zero)
        setup()
    }
    
    private func setup() {
        thumbnail = UIImageView()
        
        hstack.addArrangedSubviews([thumbnail, vstack])
        minHstack.addArrangedSubviews([ownerLabel, publicationLabel])
        vstack.addArrangedSubviews([titleLabel, authorLabel, minHstack])
        
        addSubview(hstack)
        hstack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(ConstraintInsets(top: 4, left: 10, bottom: 4, right: 10))
        }
        thumbnail.snp.makeConstraints {
            $0.width.equalTo(70)
            $0.height.equalTo(106)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
