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
    
    static let colorCodes = [
        "ffb6b9",
        "fae3d9",
        "bbded6",
        "8ac6d1"
    ]
    
    let colorCode: String?
    
    let colors = [
        UIColor(hex: "ffb6b9"),
        UIColor(hex: "fae3d9"),
        UIColor(hex: "bbded6"),
        UIColor(hex: "8ac6d1"),
        UIColor(hex: "f38181"),
        UIColor(hex: "fce38a"),
        UIColor(hex: "eaffd0"),
        UIColor(hex: "95e1d3")
    ]
    
    init(initialName: String, colorCode: String? = nil) {
        self.initial = initialName
        self.colorCode = colorCode
        super.init(frame: .zero)
        setup()
        circle()
    }
    
    deinit {
        observers.forEach { $0.invalidate() }
        observers.removeAll()
    }
    
    private func setup() {
        label.text = String(initial.prefix(1))

        backgroundColor = colors.randomElement()
        addSubview(label)
        label.snp.makeConstraints {
            $0.centerX.centerY.equalToSuperview()
        }
        
        if let colorCode = colorCode {
            backgroundColor = UIColor(hex: colorCode)
        }
    }
    
    private func circle() {
        observers.append(self.observe(\.bounds, changeHandler: { view, newValue in
            self.layer.cornerRadius = view.bounds.width / 2
        }))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
