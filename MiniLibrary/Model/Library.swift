//
//  Library.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/16.
//

import Foundation

struct Library {
    let administrator: String
    let administrator_name: String
    let book_count: Int
    let invite_code: String
    let library_name: String
    let library_code: String
    let users: [String]
    let users_data: [String:String]
    let users_name: [String]
    
    var usersNameAndColorCode:[(String,String)] {
        var usersData = [(String, String)]()
        self.users.enumerated().forEach { i, uid in
            let user_name = self.users_name[i]
            if let color_code = self.users_data[uid] {
                usersData.append((user_name, color_code))
            }
        }
        return usersData
    }
}
