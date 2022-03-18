//
//  Array.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/18.
//

import Foundation

public extension Array {
    public subscript (safe index: Int) -> Element? {
        return self.indices ~= index ? self[index] : nil
    }
}
