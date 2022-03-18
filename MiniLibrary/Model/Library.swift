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
    let users_books: [String:[String]]//[UUIDString:[BookIdentifier]]
    
    var userLists: [UserList] {
        var list = [UserList]()
        self.users.enumerated().forEach { i, uid in
            if let name = getNameFromUID(uid),
               let colorCode = self.users_data[uid] {
                let bookCount = users_books[uid]?.count ?? 0
                list.append(UserList(userName: name, uid: uid, colorCode: colorCode, bookCount: bookCount))
            }
        }
        return list
    }
    
    func getNameFromUID(_ uid: String) -> String? {
        return users_name[safe: users.firstIndex(of: uid) ?? 0]
    }
    
}
