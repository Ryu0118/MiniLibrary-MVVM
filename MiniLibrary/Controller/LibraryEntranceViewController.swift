//
//  LibraryEntranceViewController.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/16.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

class LibraryEntranceViewController: UIViewController {
    
    var rightBarItem: UIBarButtonItem!
    var entranceLibraryView: EntranceLibraryView!
    
    private var viewModel = LibraryEntranceViewModel()
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(hex: "000000", alpha: 0.7)
        setupViews()
        bind()
    }
}

extension LibraryEntranceViewController {
    
    private func bind() {
        entranceLibraryView.makeLibraryButton.rx.tap
            .asDriver()
            .drive {[weak self] _ in
                let alert = MiniLibraryAlertController(title: "図書館を作る", message: nil, textFieldConfiguration: TextfieldConfiguration(placeholder: "図書館の名前を入力", keyboardType: .default))
                alert.addActions([MiniLibraryAlertAction(message: "キャンセル", option: .cancel, handler: nil), MiniLibraryAlertAction(message: "作成", option: .normal, handler: { [weak self] in
                    if let text = alert.textField?.text {
                        self?.viewModel.inputs.libraryNameSubject.onNext(text)
                    }else{
                        print("作成できませんでした")
                    }
                    alert.dismiss(animated: true, completion: nil)
                })])
                self?.present(alert, animated: true, completion: nil)
            }
            .disposed(by: disposeBag)
        
        entranceLibraryView.inviteCode.rx.tap
            .asDriver()
            .drive {[weak self] _ in
                let alert = MiniLibraryAlertController(title: "招待コードを入力して図書館に入る", message: nil, textFieldConfiguration: TextfieldConfiguration(placeholder: "招待コードを入力", keyboardType: .numberPad))
                alert.addActions([MiniLibraryAlertAction(message: "キャンセル", option: .cancel, handler: nil), MiniLibraryAlertAction(message: "入る", option: .normal, handler: {
                    if let text = alert.textField?.text {
                        self?.viewModel.inputs.inviteCodeSubject.onNext(text)
                    }else{
                        print("参加できませんでした")
                    }
                    alert.dismiss(animated: true, completion: nil)
                })])
                self?.present(alert, animated: true, completion: nil)
            }
            .disposed(by: disposeBag)
        
        viewModel.outputs.isSuccessedAddLibrary
            .asObservable()
            .subscribe(onNext: { _ in
                print("作成が完了しました")
            }, onError: {[weak self] error in
                let alert = MiniLibraryAlertController(title: "作成に失敗しました", message: error.localizedDescription, textFieldConfiguration: nil, actions: [MiniLibraryAlertAction(message: "OK", option: .normal, handler: nil)])
                self?.present(alert, animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
        
        viewModel.outputs.isSuccessedParticipateInLibrary
            .asObservable()
            .subscribe(onNext: { _ in
                print("参加が完了しました")
            }, onError: {[weak self] error in
                let alert = MiniLibraryAlertController(title: "参加に失敗しました", message: error.localizedDescription, textFieldConfiguration: nil, actions: [MiniLibraryAlertAction(message: "OK", option: .normal, handler: nil)])
                self?.present(alert, animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
    }
    
    private func setupViews() {
        entranceLibraryView = EntranceLibraryView()
        view.addSubview(entranceLibraryView)
        
        entranceLibraryView.snp.makeConstraints {
            $0.top.left.right.equalToSuperview()
            $0.height.equalTo(90)
        }
    }
    
}

class EntranceLibraryView : UIView {
    
    private var hstack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.alignment = .center
        return stack
    }()
    
    let makeLibraryButton = EntranceCardView(systemName: "building.columns.fill", title: "作る")
    let inviteCode = EntranceCardView(systemName: "mail", title: "招待コード")
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .white
        setup()
    }
    
    private func setup() {
        hstack.addArrangedSubviews([makeLibraryButton, inviteCode])
        addSubview(hstack)
        
        hstack.snp.makeConstraints {
            $0.width.equalToSuperview().multipliedBy(0.65)
            $0.centerX.centerY.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class EntranceCardView : UIButton {
    
    private var vstack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.distribution = .fillProportionally
        stack.alignment = .center
        stack.spacing = 15
        stack.isUserInteractionEnabled = false
        return stack
    }()
    
    let systemName:String
    let title:String
    
    init(systemName: String, title: String) {
        self.systemName = systemName
        self.title = title
        super.init(frame: .zero)
        setup()
    }
    
    private func setup() {
        let imageView = UIImageView(image: UIImage(systemName: systemName, withConfiguration: UIImage.SymbolConfiguration(pointSize: 26, weight: .light, scale: .large)))
        let titleLabel = MiniLibraryLabel(size: 14)
        imageView.tintColor = .black
        titleLabel.text = title
        vstack.addArrangedSubviews([imageView, titleLabel])
        addSubview(vstack)
        vstack.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
