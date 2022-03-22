//
//  GoogleBooksAPI.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/19.
//

import RxAlamofire
import RxSwift
import RxCocoa
import Alamofire
import SwiftyJSON
import FirebaseAuth

final class GoogleBooksAPI {
    
    private static let apiURL = "https://www.googleapis.com/books/v1/volumes?q="
    
    static func searchBooks(keyword: String) -> Observable<[BookInfo]> {
        print(#function, keyword)
        let url = (apiURL + keyword).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return Session.default.rx.responseJSON(.get, url)
            .observe(on: MainScheduler.instance)
            .flatMap { response, jsonObject -> Observable<[BookInfo]> in
                
                let json = JSON(jsonObject)
                print(json)
                
                guard let items = json["items"].array else { return Observable<[BookInfo]>.just([]) }
                
                var bookinfomations = [BookInfo]()
                
                for item in items {
                    if let title = item["volumeInfo"]["title"].string,
                       let owner = FirebaseUtil.userName,
                       let uid = Auth.auth().currentUser?.uid {
                        
                        let authors = item["volumeInfo"]["authors"].array?.compactMap { $0.string }
                        let author = authors?.joined(separator: "/")
                        let publication_date = item["volumeInfo"]["publishedDate"].string
                        let lowResURL = item["volumeInfo"]["imageLinks"]["smallThumbnail"].string
                        let highResURL = item["volumeInfo"]["imageLinks"]["thumbnail"].string
                        let caption = item["volumeInfo"]["description"].string
                        let bookIdentifier = UUID().uuidString
                        
                        
                        let rent_info: [String:Any] = [
                            "owner_uid" : uid,
                            "current_owner" : nil,
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
                        
                        let bookInfo = BookInfo(rent_info: rent_info, metadata: metadata)
                        bookinfomations.append(bookInfo)
                    }
                }
                return Observable<[BookInfo]>.just(bookinfomations)
            }
    }
    
    static func getBookInformation(isbn: String) -> Observable<BookInfo> {
        
        return Session.default.rx.responseJSON(.get, apiURL + "isbn:" + isbn)
            .observe(on: MainScheduler.instance)
            .flatMap { response, jsonObject -> Observable<BookInfo> in
                
                let json = JSON(jsonObject)
                print(json)
                
                if let item = json["items"].array?.first,
                   let title = item["volumeInfo"]["title"].string,
                   let owner = FirebaseUtil.userName,
                   let uid = Auth.auth().currentUser?.uid {
                    
                    let authors = item["volumeInfo"]["authors"].array?.compactMap { $0.string }
                    let author = authors?.joined(separator: "/")
                    let publication_date = item["volumeInfo"]["publishedDate"].string
                    let lowResURL = item["volumeInfo"]["imageLinks"]["smallThumbnail"].string
                    let highResURL = item["volumeInfo"]["imageLinks"]["thumbnail"].string
                    let caption = item["volumeInfo"]["description"].string
                    let bookIdentifier = UUID().uuidString
                    
                    let rent_info: [String:Any] = [
                        "owner_uid" : uid,
                        "current_owner" : nil,
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
                    
                    let bookInfo = BookInfo(rent_info: rent_info, metadata: metadata)
                    print(bookInfo)
                    return Observable<BookInfo>.just(bookInfo)
                    
                }
                else {
                    return Observable<BookInfo>.error("本が見つかりませんでした")
                }
                
            }
    }
    
}

