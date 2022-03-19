//
//  NotificationCell.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/19.
//

import UIKit
import RxNuke
import RxSwift
import Nuke
import SnapKit

class NotificationCell : UITableViewCell {
    
    static let identifier = "NotificationCell"
    
    private var vstack: UIStackView!
    private var minVstack: UIStackView!
    private var aboveHstack: UIStackView!
    private var descendHstack: UIStackView!
    private var minHstack: UIStackView!
    private var circleIconView: CircleIconView!
    private var messageLabel: MiniLibraryLabel!
    private var titleLabel: MiniLibraryLabel!
    private var rentPeriodLabel: MiniLibraryLabel!
    private var dateLabel: MiniLibraryLabel!
    private var thumbnail: UIImageView!
    private let disposeBag = DisposeBag()
    
    var notification: Notification! {
        didSet {
            initStack()
            setupView()
            setupConstraints()
            loadImage()
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //to avoid clash
    private func initStack() {
        
//        [vstack, minVstack, aboveHstack, descendHstack].forEach { $0?.removeAllArrangedSubviews() }
        subviews.forEach {
            let constraints = $0.constraints
            $0.removeConstraints(constraints)
            $0.removeFromSuperview()
        }
        
        vstack = {
            let stack = UIStackView()
            stack.axis = .vertical
            stack.distribution = .fillProportionally
            stack.spacing = 5
            return stack
        }()
        
        minVstack = {
            let stack = UIStackView()
            stack.axis = .vertical
            stack.distribution = .fillProportionally
            stack.spacing = 15
            return stack
        }()
        
        aboveHstack = {
            let stack = UIStackView()
            stack.distribution = .fillProportionally
            stack.spacing = 12
            return stack
        }()
        
        descendHstack = {
            let stack = UIStackView()
            stack.distribution = .fillProportionally
            stack.spacing = 12
            return stack
        }()
        
        minHstack = {
            let stack = UIStackView()
            stack.distribution = .equalSpacing
            return stack
        }()
        
    }
    
    private func loadImage() {
        if let url = notification.imageURL {
            
            let pipeline = ImagePipeline.shared
            thumbnail.image = UIImage.noimage
            
            if let rowRes = notification.lowResImageURL { //handle low to high resolution
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
    
    private func setupView() {
    
        circleIconView = CircleIconView(initialName: String(notification.from_name.prefix(1)), colorCode: notification.from_colorCode)
        messageLabel = MiniLibraryLabel(size: 16)
        thumbnail = UIImageView()
        titleLabel = MiniLibraryLabel(size: 16)
        rentPeriodLabel = MiniLibraryLabel(size: 12)
        dateLabel = MiniLibraryLabel(size: 12)
        
        titleLabel.text = notification.title
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.sizeToFit()
        dateLabel.text = notification.date.string(format: "M月d日 HH:mm")
        dateLabel.textColor = .darkGray
        rentPeriodLabel.text = "貸出期間:  \(notification.rent_period)日"
        rentPeriodLabel.textColor = .darkGray
        
        setAttributedString()
        addSubview(vstack)
        vstack.addArrangedSubviews([aboveHstack, descendHstack])
        aboveHstack.addArrangedSubviews([circleIconView, messageLabel])
        descendHstack.addArrangedSubviews([thumbnail, minVstack])
        minVstack.addArrangedSubviews([titleLabel, minHstack])
        minHstack.addArrangedSubviews([rentPeriodLabel, dateLabel])
        
    }
    
    private func setupConstraints() {
        
        vstack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(ConstraintInsets(top: 8, left: 10, bottom: 8, right: 10)).labeled("VStack Constraints")
        }
        
        aboveHstack.snp.makeConstraints {
            $0.width.equalToSuperview()
        }
        
        descendHstack.snp.makeConstraints {
            $0.width.equalToSuperview()
        }
        
        circleIconView.snp.makeConstraints {
            $0.width.height.equalTo(40).labeled("Circle Icon View")
        }
        
        thumbnail.snp.makeConstraints {
            $0.width.equalTo(56).labeled("Thumbnail Constraints")
            $0.height.equalTo(84.8).labeled("Thumbnail Constraints")
        }

    }
    
    private func setAttributedString() {
        let nameAttributes: [NSAttributedString.Key : Any] = [
            .foregroundColor : UIColor.black,
            .font : UIFont.appFont(size: 16)
        ]
        let messageAttributes: [NSAttributedString.Key : Any] = [
            .foregroundColor : UIColor.darkGray,
            .font : UIFont.appFont(size: 14)
        ]
        
        let nameString = NSAttributedString(string: notification.from_name, attributes: nameAttributes)
        let messageString = NSAttributedString(string: " さんから貸出申請が届いています", attributes: messageAttributes)
        
        let mutableString = NSMutableAttributedString()
        mutableString.append(nameString)
        mutableString.append(messageString)
        
        messageLabel.attributedText = mutableString
        messageLabel.textAlignment = .right
        messageLabel.numberOfLines = 0
        messageLabel.sizeToFit()
        messageLabel.adjustsFontSizeToFitWidth = true
        
    }

    func update(notification: Notification) {
        self.notification = notification
    }
    
}
