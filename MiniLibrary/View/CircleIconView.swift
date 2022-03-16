//
//  CircleIconView.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/16.
//

import UIKit
import SnapKit

class CircleIconView : UIView {
    let initial: String
    var observers = [NSKeyValueObservation]()
    private let label = MiniLibraryLabel(size: 12)
    
    let colors = [
        UIColor(hex: "ffb6b9"),
        UIColor(hex: "fae3d9"),
        UIColor(hex: "bbded6"),
        UIColor(hex: "8ac6d1"),
    ]
    
    init(initialName: String) {
        self.initial = initialName
        super.init(frame: .zero)
        setup()
        circle()
    }
    
    private func setup() {
        label.text = String(initial.prefix(1))
        backgroundColor = colors.randomElement()
        addSubview(label)
        label.snp.makeConstraints {
            $0.centerX.centerY.equalToSuperview()
        }
    }
    
    private func circle() {
        observers.append(self.observe(\.bounds, changeHandler: { view, newValue in
            print("changed!!")
//            guard let rect = newValue.newValue else { return }
//            print(rect)
            self.layer.cornerRadius = view.bounds.width / 2
            self.layoutIfNeeded()
        }))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
