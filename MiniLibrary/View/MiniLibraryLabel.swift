//
//  MiniLibraryLabel.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/15.
//

import UIKit

class MiniLibraryLabel : UILabel {
    
    init(size: CGFloat) {
        super.init(frame: .zero)
        self.font = .appFont(size: size)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
