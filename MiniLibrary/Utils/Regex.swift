//
//  Regex.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/15.
//

import Foundation

class Regex {
    static func evaluate(_ text: String, pattern: String) -> Bool {
        let regex = NSPredicate(format:"SELF MATCHES %@", pattern)
        let result = regex.evaluate(with: text)
        return result
    }
}

extension Regex {
    static func isValidEmail(_ text:String) -> Bool {
        return evaluate(text, pattern: "^[a-zA-Z0-9_+-]+(.[a-zA-Z0-9_+-]+)*@([a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]*.)+[a-zA-Z]{2,}$")
    }
    
    static func isValidPassword(_ text:String) -> Bool {
        return evaluate(text, pattern: "^[a-zA-Z0-9]{8,24}$")
    }
}
