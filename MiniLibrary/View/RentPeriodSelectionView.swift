//
//  RentPeriodSelectionView.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/19.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

class RentPeriodSelectionView : UIButton {
    
    let selections: [String] = {
        var selections = [String]()
        for i in 1...60 {
            selections.append("\(i)日")
        }
        return selections
    }()
    
    private let disposeBag = DisposeBag()
    
    var selectedRentPeriod = 1
    
    var pickerView: UIPickerView! {
        didSet {
            
            Observable.just(selections)
                .bind(to: pickerView.rx.itemTitles) { _, str in
                    return str
                }
                .disposed(by: disposeBag)
            
            pickerView.rx.modelSelected(String.self)
                .map { $0.first }
                .subscribe(onNext: {[weak self] str in
                    guard let self = self else { return }
                    if let str = str {
                        let title = str
                        
                        var str = str
                        str.removeLast()
                        self.selectedRentPeriod = Int(str) ?? 1
                        self.setTitle(title, for: .normal)
                    }
                })
                .disposed(by: disposeBag)
            
        }
    }
    
    override var inputView: UIView? {
        pickerView = UIPickerView()
        pickerView.selectRow(0, inComponent: 0, animated: true)
        return pickerView
    }
    
    override var inputAccessoryView: UIView? {
        let toolbar = UIToolbar()
        toolbar.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: 44)

        let space = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: self, action: nil)
        space.width = 12
        let cancelItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: nil)
        let flexSpaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let doneButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: nil)
        let toolbarItems = [space, cancelItem, flexSpaceItem, doneButtonItem, space]
        toolbar.setItems(toolbarItems, animated: true)
        
        cancelItem.rx.tap
            .asObservable()
            .withUnretained(self)
            .subscribe(onNext:{ _ in
                self.resignFirstResponder()
            })
            .disposed(by: disposeBag)
        
        doneButtonItem.rx.tap
            .asObservable()
            .withUnretained(self)
            .subscribe (onNext: { _ in
                self.resignFirstResponder()
            })
            .disposed(by: disposeBag)

        return toolbar
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setTitleColor(.black, for: .normal)
        self.titleLabel?.font = .appFont(size: 18)
        self.titleLabel?.adjustsFontSizeToFitWidth = true
        self.setTitle("1日", for: .normal)
        self.rx.tap
            .asObservable()
            .withUnretained(self)
            .subscribe { _ in
                self.becomeFirstResponder()
            }
            .disposed(by: disposeBag)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        let line = UIView()
        line.backgroundColor = .appTextColor
        addSubview(line)
        
        line.snp.makeConstraints {
            $0.bottom.equalTo(snp.bottom).offset(-4)
            $0.centerX.equalToSuperview()
            $0.width.equalToSuperview().multipliedBy(0.7)
            $0.height.equalTo(2)
        }
    }
    
}
