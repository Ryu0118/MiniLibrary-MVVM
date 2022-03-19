//
//  BookInfo.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/17.
//

import Foundation


struct BookInfo {
    var rent_info: [String:Any]
    let metadata: [String:String]
    
    //rent_info
    var rentPeriod: Int? {
        return rent_info["rent_period"] as? Int
    }
    var deadline: Date? {
        return rent_info["deadline"] as? Date
    }
    var identifier: String {
        return rent_info["identifier"] as! String
    }
    var isRented: Bool {
        return rent_info["is_rented"] as! Bool
    }
    var rentDate: Date? {
        return rent_info["rent_date"] as? Date
    }
    var currentOwner: String? {
        return rent_info["current_owner"] as? String
    }
    
    //metadata
    var imageURL: String? {
        return metadata["image_url"]
    }
    var lowResImageURL: String? {
        return metadata["small_image_url"]
    }
    var title: String {
        return metadata["title"] ?? ""
    }
    var book_identifier: String {
        return metadata["identifier"] ?? ""
    }
    var publication_date: String? {
        return metadata["publication_date"]
    }
    var author: String? {
        return metadata["author"]
    }
    var owner: String {
        return metadata["owner"] ?? ""
    }
    var owner_uid: String {
        return metadata["owner_uid"] ?? ""
    }
    var caption: String? {
        return metadata["caption"]
    }
    
}

extension BookInfo {
    mutating func updateRentInfoValue(key: String, value: Any) {
        rent_info.updateValue(value, forKey: key)
    }
}
