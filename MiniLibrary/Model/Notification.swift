//
//  Notification.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/19.
//

import Foundation

struct Notification {
    let from_colorCode: String
    let from_name: String
    let from_uid: String
    let to_name: String
    let to_uid: String
    let rent_period: Int
    let date: Date
    let books_data: [String:String]
    
    var imageURL: String? {
        return books_data["image_url"]
    }
    var lowResImageURL: String? {
        return books_data["small_image_url"]
    }
    var title: String {
        return books_data["title"] ?? ""
    }
    var identifier: String {
        return books_data["identifier"] ?? ""
    }
}
