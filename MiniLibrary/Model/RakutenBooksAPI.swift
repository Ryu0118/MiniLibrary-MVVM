//
//  RakutenBooksAPI.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/18.
//

import RxSwift
import RxCocoa
import SwiftyJSON
import RxAlamofire
import Alamofire
import FirebaseAuth


final class RakutenBooksAPI {
    
    static let apiURL = "https://app.rakuten.co.jp/services/api/BooksBook/Search/20170404"
    
    static func getBookInformation(isbn: String) -> Observable<BookInfo> {
        let parameters: [String:Any] = [
            "format" : "json",
            "isbn" : Int(isbn)!,
            "applicationId" : "1098153373585542188" //Application Name: Rakuten Api Explorer
        ]
        
        return Session.default.rx.responseJSON(.get, apiURL, parameters: parameters)
            .observe(on: MainScheduler.instance)
            .flatMap { response, jsonObject -> Observable<BookInfo> in
                let json = JSON(jsonObject)
                
                if let item = json["Items"].array?.first?["Item"],
                   let title = item["title"].string,
                   let owner = FirebaseUtil.userName,
                   let uid = Auth.auth().currentUser?.uid {
                    
                    let author = item["author"].string
                    let publication_date = item["salesDate"].string
                    let lowResURL = item["smallImageUrl"].string
                    let highResURL = item["largeImageUrl"].string
                    let caption = item["itemCaption"].string
                    let bookIdentifier = UUID().uuidString
                    
                    let rent_info: [String:Any] = [
                        "owner_uid" : uid,
                        "current_owner" : nil,
                        "current_owner_uid" : nil,
                        "current_owner_colorCode" : nil,
                        "rent_period" : nil,
                        "deadline" : nil,
                        "identifier" : bookIdentifier,
                        "is_rented" : false,
                        "owner" : owner,
                        "rent_date" : nil
                    ]
                        .compactMapValues {
                            $0
                        }
                    
                    let metadata: [String:String] = [
                        "title" : title,
                        "identifier" : bookIdentifier,
                        "publication_date" : publication_date,
                        "author" : author,
                        "image_url" : highResURL,
                        "small_image_url" : lowResURL,
                        "owner" : owner,
                        "owner_uid" : uid,
                        "caption" : caption
                    ]
                        .compactMapValues {
                            $0
                        }
                    
                    let bookinfo = BookInfo(rent_info: rent_info, metadata: metadata)
                    
                    return Observable<BookInfo>.just(bookinfo)
                }
                else{
                    return Observable<BookInfo>.error("本が見つかりませんでした")
                }
            }
    }
    
}
