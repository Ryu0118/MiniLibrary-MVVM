//
//  UIAlertController.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/15.
//

import UIKit

extension UIAlertController {
    static func show(target: UIViewController, title: String? = nil, message: String? = nil, prefferedStyle: Style, actionTitles: [String], actionStyles: [UIAlertAction.Style], actionHandlers: [((UIAlertAction) -> ())?]) {
        guard actionTitles.count == actionStyles.count && actionHandlers.count == actionStyles.count else {
            fatalError()
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: prefferedStyle)
        actionTitles.enumerated().forEach { i, title in
            let action = UIAlertAction(title: title, style: actionStyles[i], handler: actionHandlers[i])
            alert.addAction(action)
        }
        target.present(alert, animated: true, completion: nil)
    }
}

