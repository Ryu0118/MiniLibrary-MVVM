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
            titleLabel.numberOfLines = 0
            titleLabel.sizeToFit()
            titleLabel.adjustsFontSizeToFitWidth = true
            
            deadlineLabel.attributedText = textAttributes(left: "期限:  ", right: bookinfo.deadline?.string() ?? "")
            currentOwnerLabel.attributedText = textAttributes(left: "借りている人:  ", right: bookinfo.currentOwner ?? "")
            ownerLabel.attributedText = textAttributes(left: "貸している人:  ", right: bookinfo.owner)
            
        }
    }
    
    var thumbnail: UIImageView!
    var titleLabel: MiniLibraryLabel!
    var deadlineLabel: MiniLibraryLabel!
    var ownerLabel: MiniLibraryLabel!
    var currentOwnerLabel: MiniLibraryLabel!
    
    var hstack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillProportionally
        stack.spacing = 12
        return stack
    }()
    
    var vstack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.distribution = .equalSpacing
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
        deadlineLabel = MiniLibraryLabel(size: 12)
        currentOwnerLabel = MiniLibraryLabel(size: 12)
        ownerLabel = MiniLibraryLabel(size: 12)
        [deadlineLabel, currentOwnerLabel, ownerLabel].forEach { $0.textAlignment = .left }
        thumbnail = UIImageView()
        titleLabel = MiniLibraryLabel(size: 16)

        self.bookinfo = bookinfo
        
        hstack.removeAllArrangedSubviews()
        vstack.removeAllArrangedSubviews()
        hstack.addArrangedSubviews([thumbnail, vstack])
        vstack.addArrangedSubviews([titleLabel, deadlineLabel, currentOwnerLabel, ownerLabel])
//        vstack.setCustomSpacing(6, after: titleLabel)
//        vstack.setCustomSpacing(2, after: deadlineLabel)
//        vstack.setCustomSpacing(2, after: ownerLabel)
        
        addSubview(hstack)
        
        hstack.snp.makeConstraints {
            $0.centerX.centerY.equalToSuperview()
            $0.left.equalToSuperview().offset(8)
            $0.right.equalToSuperview().offset(-8)
        }
        
        vstack.snp.makeConstraints {
            $0.height.equalToSuperview()
        }
        
        thumbnail.snp.makeConstraints {
            $0.height.equalTo(106 * 1.3)
            $0.width.equalTo(70 * 1.3)
        }
        
        titleLabel.snp.makeConstraints {
            $0.height.equalToSuperview().multipliedBy(0.5)
        }
        
        [deadlineLabel, currentOwnerLabel, ownerLabel].forEach { label in
            label.snp.makeConstraints {
                $0.height.lessThanOrEqualTo(18)
                //$0.width.lessThanOrEqualToSuperview().multipliedBy(0.7)
            }
        }
    }
    
    private func textAttributes(left: String, right: String) -> NSMutableAttributedString {
        
        let nameAttributes: [NSAttributedString.Key : Any] = [
            .foregroundColor : UIColor.black,
            .font : UIFont.appFont(size: 12)
        ]
        let messageAttributes: [NSAttributedString.Key : Any] = [
            .foregroundColor : UIColor.darkGray,
            .font : UIFont.appFont(size: 12)
        ]
        
        let nameString = NSAttributedString(string: left, attributes: nameAttributes)
        let messageString = NSAttributedString(string: right, attributes: messageAttributes)
        
        let mutableString = NSMutableAttributedString()
        mutableString.append(nameString)
        mutableString.append(messageString)
        
        return mutableString
        
    }
    
}
