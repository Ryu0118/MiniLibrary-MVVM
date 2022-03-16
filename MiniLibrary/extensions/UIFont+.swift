//
//  UIFont.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/15.
//

import UIKit

extension UIFont {
    
    static var appFont: UIFont {
        return UIFont(name: "AvenirNextCondensed-HeavyItalic", size: 15)!
    }
    
    static func appFont(size: CGFloat) -> UIFont {
        return UIFont(name: "AvenirNextCondensed-HeavyItalic", size: size)!
    }
    
    static var appAttributes: [NSAttributedString.Key : Any] = [
        .font: UIFont.appFont
    ]
}
