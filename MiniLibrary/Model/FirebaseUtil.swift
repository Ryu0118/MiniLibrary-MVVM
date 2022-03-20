//
//  FirebaseUtil.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/16.
//

import Firebase
import FirebaseAuth
import FirebaseFirestore
import RxSwift
import RxCocoa

class FirebaseUtil: RequireLogin {
    
    static var userName: String?
    static var colorCode: String?
    
    static func signIn(info: LoginInfo) -> Observable<Bool> {
        Observable<Bool>.create { observer -> Disposable in
            
            Auth.auth().signIn(withEmail: info.email, password: info.password, completion: { result, error in
                if let _ = result?.user {
                    observer.onNext(true)
                    observer.onCompleted()
                }
                else if let error = error {
                    print("Failed Login: ", error.localizedDescription)
                    observer.onNext(false)
                    observer.onCompleted()
                }else{
                    print("User Not found")
                    observer.onNext(false)
                    observer.onCompleted()
                }
            })
            
            return Disposables.create()
        }
    }
    
    static func createUser(registration: Registration) -> Observable<Bool> {
        
        Observable<Bool>.create { observer -> Disposable in
            Auth.auth().createUser(withEmail: registration.email, password: registration.password, completion: { result, error in
                
                if let user = result?.user {
                    print("ユーザー作成完了 uid:" + user.uid)
                    
                    db
                        .collection("users")
                        .document(user.uid)
                        .setData([
                            "name" : registration.name,
                            "color_code" : CircleIconView.colorCodes.randomElement() ?? "8ac6d1"
                        ], completion: { error in
                            if let error = error {
                                print("Firestore 新規登録失敗" + error.localizedDescription)
                                observer.onNext(false)
                                observer.onCompleted()
                            }else{
                                print("ユーザー作成完了 name:" + registration.name)
                                observer.onNext(true)
                                observer.onCompleted()
                            }
                        })
                }
                else if let error = error {
                    print("Firebase Auth 新規登録失敗" + error.localizedDescription)
                    observer.onNext(false)
                    observer.onCompleted()
                }
                else {
                    print("ユーザーが見つかりませんでした")
                    observer.onNext(false)
                    observer.onCompleted()
                }
                
            })
            return Disposables.create()
        }
    }
    
    static func addDocument(_ collection: String, documentID: String? = nil, data: [String:Any]) -> Observable<String> {
        Observable<String>.create { observer -> Disposable in
            if let documentID = documentID {
                db.collection(collection).document(documentID).setData(data) { err in
                    if let error = err {
                        observer.onError(error.localizedDescription)
                    }else{
                        observer.onNext("")
                        observer.onCompleted()
                    }
                }
                return Disposables.create()
            }else{
                db.collection(collection).addDocument(data: data) { err in
                    if let error = err {
                        observer.onError(error.localizedDescription)
                    }else{
                        observer.onNext("")
                        observer.onCompleted()
                    }
                }
                return Disposables.create()
            }
        }
    }
    
    static func addBook(libraryCode: String, bookinfo: BookInfo) -> Observable<String> {
        
        let rentinfo = [bookinfo.rent_info]
        let books = [bookinfo.book_identifier]
        let metadata = [bookinfo.metadata]
        
        let data: [String:Any] = [
            "rent_info" : rentinfo,
            "books" : books,
            "books_data" : metadata
        ]
        
        return Observable.combineLatest(getDocument("books", documentID: libraryCode), findDocuments("library", key: "library_code", isEqualTo: libraryCode))
            .flatMap { documentSnapshot, querySnapshot -> Observable<String> in
                
                if let snapshot = documentSnapshot?.data(),
                   var gotRentInfo = snapshot["rent_info"] as? [[String:Any]],
                   var gotBooks = snapshot["books"] as? [String],
                   var gotBooksData = snapshot["books_data"] as? [[String:String]],
                   let docID = querySnapshot.documents.first?.documentID,
                   var book_count = querySnapshot.documents.first?.data()["book_count"] as? Int,
                   var users_books = querySnapshot.documents.first?.data()["users_books"] as? [String:[String]],
                   let uid = Auth.auth().currentUser?.uid
                {
                    if gotBooksData.contains(where: { element -> Bool in
                        return element.contains(where: { key, value -> Bool in
                            key == "image_url" && value == bookinfo.imageURL
                        })
                    }) {
                        return Observable<String>.just("既に追加しています")
                    }
                    book_count += 1
                    gotRentInfo.append(contentsOf: rentinfo)
                    gotBooks.append(contentsOf: books)
                    gotBooksData.append(contentsOf: metadata)
                    
                    if var user_books = users_books[uid] {
                        user_books.append(bookinfo.book_identifier)
                        users_books.updateValue(user_books, forKey: uid)
                    }else{
                        users_books.updateValue([bookinfo.book_identifier], forKey: uid)
                    }

                    let updateData: [String : Any] = [
                        "rent_info" : gotRentInfo,
                        "books" : gotBooks,
                        "books_data" : gotBooksData,
                    ]
                
                    return Observable.combineLatest(
                        updateDocument("books",
                                       documentID: libraryCode,
                                       updateData: updateData
                                      ),
                        updateDocument("library",
                                       documentID: docID,
                                       updateData: ["book_count" : book_count, "users_books" : users_books]
                                      )
                    )
                        .flatMap { books, library -> Observable<String> in
                            if books == library {
                                return Observable<String>.just("")
                            }
                            else {
                                return Observable<String>.just(books.isEmpty ? library : books)
                            }
                        }
                }
                else{
                    if let document = querySnapshot.documents.first,
                       var book_count = document.data()["book_count"] as? Int,
                       var users_books = document.data()["users_books"] as? [String:[String]],
                       let uid = Auth.auth().currentUser?.uid {
                        
                        book_count += 1
                        
                        if var user_books = users_books[uid] {
                            user_books.append(bookinfo.book_identifier)
                            users_books.updateValue(user_books, forKey: uid)
                        }else{
                            users_books.updateValue([bookinfo.book_identifier], forKey: uid)
                        }
                        
                        return Observable.combineLatest(addDocument("books", documentID: libraryCode, data: data), updateDocument("library", documentID: document.documentID, updateData: ["book_count" : book_count, "users_books" : users_books]))
                            .flatMap { addDoc, updateDoc -> Observable<String> in
                                if addDoc == updateDoc {
                                    return Observable<String>.just("")
                                }
                                else {
                                    return Observable<String>.just(addDoc.isEmpty ? updateDoc : addDoc)
                                }
                            }
                    }else{
                        return addDocument("books", documentID: libraryCode, data: data)
                    }
                }
            }
        
    }
    
    static func addLibrary(libraryName: String, administrator: String) -> Observable<String> {
        
        if let uid = Auth.auth().currentUser?.uid {
            
            let libraryCode = UUID().uuidString
            
            let addLibraryObserver =
            addDocument("library", data: [
                "library_name" : libraryName,
                "library_code" : libraryCode,
                "administrator" : uid,
                "administrator_name" : administrator,
                "users_data" : [uid:FirebaseUtil.colorCode ?? "8ac6d1"],
                "users" : [uid],
                "users_name" : [administrator],
                "book_count" : 0,
                "users_books" : [:],
                "invite_code" : createInviteCode(),
            ])
            
            let addNotificationObserver =
            addDocument("notifications", documentID: libraryCode, data: [
                "applyNotifications" : [:]
            ])
            
            return Observable.combineLatest(addLibraryObserver, addNotificationObserver)
                .flatMap { res0, res1 -> Observable<String> in
                    if res0 == res1 {
                        return Observable<String>.just(res0)
                    }else{
                        return Observable<String>.just(res0.isEmpty ? res1 : res0)
                    }
                }
            
        }
        else {
            return Observable<String>.create {
                $0.onNext("ログイン中のユーザーが見つかりませんでした")
                return Disposables.create()
            }
        }
    }
    
    static func removeBook(libraryCode: String, bookinfo: BookInfo) -> Observable<String> {
        
        let books = getDocument("books", documentID: libraryCode)
        let library = findDocuments("library", key: "library_code", isEqualTo: libraryCode)
        let notifications = getDocument("notifications", documentID: libraryCode)
        
        return Observable.combineLatest(books, library, notifications)
            .flatMap { books, library, notifications -> Observable<String> in
                
                guard let booksData = books?.data(),
                      let uid = Auth.auth().currentUser?.uid,
                      var rent_info = booksData["rent_info"] as? [[String : Any]],
                      let rent_info_index = rent_info.firstIndex(where: {($0["identifier"] as? String) == bookinfo.book_identifier }),
                      var books = booksData["books"] as? [String],
                      var books_data = booksData["books_data"] as? [[String : String]],
                      let books_data_index = books_data.firstIndex(where: { element in
                          element["identifier"] == bookinfo.book_identifier
                      })
                else {
                    
                    return Observable<String>.just("booksのドキュメントが見つかりませんでした")
                }
                
                guard let document = library.documents.first else {
                    return Observable<String>.just("Libraryが見つかりませんでした")
                }
                
                rent_info.remove(at: rent_info_index)
                books.removeAll(where: { book in
                    book == bookinfo.book_identifier
                })
                books_data.remove(at: books_data_index)
                
                let booksUpdateObserver = updateDocument("books", documentID: libraryCode, updateData: [
                    "rent_info" : rent_info,
                    "books" : books,
                    "books_data" : books_data
                ])
                
                //library collection
                
                let libraryDocumentID = document.documentID
                let libraryData = document.data()
                var library_book_count = libraryData["book_count"] as! Int
                var usersBooks = libraryData["users_books"] as? [String : [String]]
                var mybook = usersBooks?[uid]
                
                mybook?.removeAll(where: { book in
                    book == bookinfo.book_identifier
                })
                usersBooks?.updateValue(mybook ?? [], forKey: uid)
                library_book_count -= 1
                
                let libraryUpdateObserver = updateDocument("library", documentID: libraryDocumentID, updateData: [
                    "book_count" : library_book_count,
                    "users_books" : usersBooks as Any
                ])
                
                if let notificationsData = notifications?.data(),
                   var applyNotifications = notificationsData["applyNotifications"] as? [String : [[String : Any]]],
                   var myNotifications = applyNotifications[uid],
                   let index = myNotifications.firstIndex(where: { element in
                       (element["books_data"] as? [String : String])?["identifier"] == bookinfo.book_identifier
                   }) {
                    
                    myNotifications.remove(at: index)
                    applyNotifications.updateValue(myNotifications, forKey: uid)
                    
                    let notificationsObserver = updateDocument("notifications", documentID: libraryCode, updateData: [
                        "applyNotifications" : applyNotifications
                    ])
                    
                    return Observable.combineLatest(booksUpdateObserver, libraryUpdateObserver, notificationsObserver)
                        .flatMap { res0, res1, res2 -> Observable<String> in
                            if res0 == res1 && res1 == res2 {
                                return Observable<String>.just(res0)
                            }
                            else {
                                return Observable<String>.just("内部のエラーが発生しました")
                            }
                        }
                    
                }
                
                return Observable.combineLatest(booksUpdateObserver, libraryUpdateObserver)
                    .flatMap { res0, res1 -> Observable<String> in
                        if res0 == res1 {
                            return Observable<String>.just(res0)
                        }
                        else {
                            return Observable<String>.just(res0.isEmpty ? res1 : res0)
                        }
                    }
                
                
                
            }
    }
    
    static func returnBook(libraryCode: String, bookinfo: BookInfo) -> Observable<String> {
        return getDocument("books", documentID: libraryCode)
            .flatMap { books -> Observable<String> in
                
                guard let booksData = books?.data(),
                var rent_info = booksData["rent_info"] as? [[String : Any]],
                let rent_info_index = rent_info.firstIndex(where: {($0["identifier"] as? String) == bookinfo.book_identifier }),
                var targetRent_info = rent_info.filter({ ($0["identifier"] as? String) == bookinfo.book_identifier }).first else {
                    return Observable<String>.just("ドキュメントが見つかりませんでした")
                }
                
                targetRent_info.removeValue(forKey: "current_owner_uid")
                targetRent_info.removeValue(forKey: "current_owner")
                targetRent_info.removeValue(forKey: "current_owner_colorCode")
                targetRent_info.removeValue(forKey: "rent_period")
                targetRent_info.removeValue(forKey: "deadline")
                targetRent_info.removeValue(forKey: "rent_date")
                targetRent_info.updateValue(false, forKey: "is_rented")
                
                rent_info[rent_info_index] = targetRent_info
                
                return updateDocument("books", documentID: libraryCode, updateData: [
                    "rent_info" : rent_info
                ])
                
            }
        
    }
    
    static func permitRentBook(libraryCode: String, notification: Notification) -> Observable<String> {
        //TODO: remove notification based on date and identifier
        //TODO: update rent_info
        let notificationsObserver = getDocument("notifications", documentID: libraryCode)
        let booksObserver = getDocument("books", documentID: libraryCode)
        
        return Observable.combineLatest(notificationsObserver, booksObserver)
            .flatMap { notifications, books -> Observable<String> in
                
                guard let notificationsData = notifications?.data(),
                      let uid = Auth.auth().currentUser?.uid,
                      var applyNotifications = notificationsData["applyNotifications"]
                        as? [String : [[String : Any]]],
                      var myNotifications = applyNotifications[uid],
                      let notificationIndex = myNotifications.firstIndex(where: {
                          ($0["date"] as? Timestamp)?.dateValue() == notification.date && ($0["from_uid"] as? String) == notification.from_uid }),
                      let booksData = books?.data(),
                      var rent_info = booksData["rent_info"] as? [[String : Any]],
                      let rent_info_index = rent_info.firstIndex(where: {($0["identifier"] as? String) == notification.identifier }),
                      var targetRent_info = rent_info.filter({ ($0["identifier"] as? String) == notification.identifier }).first else {
                          return Observable<String>.just("ドキュメントが見つかりませんでした")
                      }
                
                let deadline = Timestamp(date: Date().addDate(notification.rent_period))
                
                myNotifications.remove(at: notificationIndex)
                applyNotifications.updateValue(myNotifications, forKey: uid)
                
                targetRent_info.updateValue(notification.from_uid, forKey: "current_owner_uid")
                targetRent_info.updateValue(notification.from_name, forKey: "current_owner")
                targetRent_info.updateValue(notification.from_colorCode, forKey: "current_owner_colorCode")
                targetRent_info.updateValue(notification.rent_period, forKey: "rent_period")
                targetRent_info.updateValue(deadline, forKey: "deadline")
                targetRent_info.updateValue(true, forKey: "is_rented")
                targetRent_info.updateValue(Timestamp(date: Date()), forKey: "rent_date")
                
                rent_info[rent_info_index] = targetRent_info
                
                let updateNotification = updateDocument("notifications", documentID: libraryCode, updateData: ["applyNotifications" : applyNotifications])
                let updatebook = updateDocument("books", documentID: libraryCode, updateData: [
                    "rent_info" : rent_info
                ])
                
                return Observable.combineLatest(updateNotification, updatebook)
                    .flatMap { res0, res1 -> Observable<String> in
                        if res0 == res1 {
                            return Observable<String>.just(res0)
                        }
                        else {
                            return Observable<String>.just(res1)
                        }
                    }
                
            }
    }
    
    static func applyRentBook(bookinfo: BookInfo, libraryCode: String, userList: UserList) -> Observable<String> {
        return getDocument("notifications", documentID: libraryCode)
            .flatMap { snapshot -> Observable<String> in
                
                guard let snapshot = snapshot,
                      let data = snapshot.data() else {
                    return Observable<String>.just("ドキュメントが見つかりませんでした")
                }
                guard let rentPeriod = bookinfo.rentPeriod else{
                    return Observable<String>.just("貸出日数が設定されていません")
                }
                
                let applyNotifications = data["applyNotifications"] as? [String : [[String : Any]]]
                let ownerNotification = applyNotifications?[bookinfo.owner_uid]
                let message: [String : Any] = [
                    "from_uid" : userList.uid,
                    "from_colorCode" : userList.colorCode,
                    "from_name" : userList.userName,
                    "to_uid" : bookinfo.owner_uid,
                    "to" : bookinfo.owner,
                    "rent_period" : rentPeriod,
                    "date" : Timestamp(),
                    "books_data" : bookinfo.metadata,
                ]
                if var ownerNotification = ownerNotification {
                    ownerNotification.append(message)
                    
                    return updateDocument("notifications", documentID: libraryCode, updateData: [
                        "applyNotifications" : [bookinfo.owner_uid : ownerNotification]
                    ])
                }
                else{
                    
                    return updateDocument("notifications", documentID: libraryCode, updateData: [
                        "applyNotifications" : [bookinfo.owner_uid : [message]]
                    ])
                }
            }
    }
    
    static func exitLibrary(libraryCode: String) -> Observable<String> {
        
        return Observable.combineLatest(findDocuments("library", key: "library_code", isEqualTo: libraryCode), getDocument("books", documentID: libraryCode))
            .flatMap { snapshot, documentSnapshot -> Observable<String> in
                
                if let uid = Auth.auth().currentUser?.uid,
                   let docID = snapshot.documents.first?.documentID,
                   let data = snapshot.documents.first?.data(),
                   var users = data["users"] as? [String],
                   var users_name = data["users_name"] as? [String],
                   var users_data = data["users_data"] as? [String:String],
                   var users_books = data["users_books"] as? [String:[String]],
                   let firstIndex = users.firstIndex(of: uid),
                   let books_field = documentSnapshot?.data(),
                   var books = books_field["books"] as? [String],
                   var books_data = books_field["books_data"] as? [[String:String]],
                   var rent_info = books_field["rent_info"] as? [[String:Any]] {
                    
                    users.remove(at: firstIndex)
                    users_name.remove(at: firstIndex)
                    users_data.removeValue(forKey: uid)
                    users_books.removeValue(forKey: uid)
                    
                    var i = books_data.count - 1
                    books_data = books_data.reversed().filter { book -> Bool in
                        defer { i -= 1 }
                        if uid == book["owner_uid"] {
                            books.remove(at: i)
                            rent_info.remove(at: i)
                            return false
                        }
                        else {
                            return true
                        }
                    }
                    
                    let updateData: [String:Any] = [
                        "book_count" : books.count,
                        "users" : users,
                        "users_name" : users_name,
                        "users_data" : users_data,
                        "users_books" : users_books
                    ]
                    
                    let updateData_books: [String:Any] = [
                        "books" : books,
                        "books_data" : books_data,
                        "rent_info" : rent_info
                    ]
                    
                    return Observable.combineLatest(updateDocument("library", documentID: docID, updateData: updateData), updateDocument("books", documentID: libraryCode, updateData: updateData_books))
                        .flatMap { res0, res1 -> Observable<String> in
                            if res0 == res1 {
                                return Observable<String>.just(res0)
                            }
                            else {
                                return Observable<String>.just(res0.isEmpty ? res1 : res0)
                            }
                        }
                }
                else {
                    return Observable<String>.just("An error has occured")
                }
            }
    }
    
    static func updateDocument(_ collection: String, documentID:String, updateData: [String:Any]) -> Observable<String> {
        return Observable<String>.create { observer -> Disposable in
            db.collection(collection).document(documentID).updateData(updateData) {error in
                if let error = error {
                    observer.onNext(error.localizedDescription)
                }else{
                    observer.onNext("")
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }
    
    static func findDocumentIDs(_ collection: String, key: String, arrayContains: Any) -> Observable<[String]> {
        
        return findDocuments(collection, key: key, arrayContains: arrayContains)
            .flatMap { snapshot -> Observable<[String]> in
                let documents = snapshot.documents.map { $0.documentID }
                return Observable<[String]>.just(documents)
            }
        
    }
    
    static func findDocumentIDs(_ collection: String, key: String, isEqualTo: Any) -> Observable<[String]> {
        
        return findDocuments(collection, key: key, isEqualTo: isEqualTo)
            .flatMap { snapshot -> Observable<[String]> in
                let documents = snapshot.documents.map { $0.documentID }
                return Observable<[String]>.just(documents)
            }
        
    }
    
    static func getDocument(_ collection: String, documentID: String) -> Observable<DocumentSnapshot?> {
        return Observable<DocumentSnapshot?>.create { observer -> Disposable in
            let docRef = db.collection(collection).document(documentID)
            
            docRef.getDocument { document, error in
                observer.onNext(document)
            }
            return Disposables.create()
        }
    }
    
    static func findDocuments(_ collection:String, key:String, arrayContains: Any) -> Observable<QuerySnapshot> {
        Observable<QuerySnapshot>.create { observer -> Disposable in
            let ref = db.collection("library")
            ref.whereField(key, arrayContains: arrayContains)
                .getDocuments(completion: { snapshot, error in
                    if let snapshot = snapshot {
                        observer.onNext(snapshot)
                    }
                    else if let error = error {
                        observer.onError(error)
                    }
                })
            
            return Disposables.create()
        }
    }
    
    static func findDocuments(_ collection: String, key: String, isEqualTo: Any) ->  Observable<QuerySnapshot> {
        Observable<QuerySnapshot>.create { observer -> Disposable in
            let ref = db.collection("library")
            ref.whereField(key, isEqualTo: isEqualTo)
                .getDocuments(completion: { snapshot, error in
                    if let snapshot = snapshot {
                        observer.onNext(snapshot)
                    }
                    else if let error = error {
                        observer.onError(error)
                    }
                })
            
            return Disposables.create()
        }
    }
    
    static func addSnapshotListner(_ collection: String, key: String, isEqualTo: Any) -> Observable<QuerySnapshot> {
        
        Observable<QuerySnapshot>.create { observer -> Disposable in
            
            db.collection(collection).whereField(key, isEqualTo: isEqualTo)
                .addSnapshotListener { snapshot, error in
                    if let snapshot = snapshot {
                        observer.onNext(snapshot)
                    }
                    else if let error = error {
                        observer.onError(error)
                    }
                }
            
            return Disposables.create()
        }
        
    }
    
    static func addSnapshotListner(_ collection: String, key: String, arrayContains: Any) -> Observable<QuerySnapshot> {
        
        Observable<QuerySnapshot>.create { observer -> Disposable in
            
            db.collection(collection).whereField(key, arrayContains: arrayContains)
                .addSnapshotListener { snapshot, error in
                    if let snapshot = snapshot {
                        observer.onNext(snapshot)
                    }
                    else if let error = error {
                        observer.onError(error)
                    }
                }
            
            return Disposables.create()
        }
        
    }
    
    static func addSnapshotListener(_ collection: String, documentID: String) -> Observable<DocumentSnapshot> {
        
        return Observable<DocumentSnapshot>.create { observer -> Disposable in
            db.collection(collection).document(documentID).addSnapshotListener { document, error in
                if let error = error {
                    observer.onError(error)
                }
                else if let document = document {
                    observer.onNext(document)
                }
            }
            return Disposables.create()
        }
        
    }
    
    static func notificationListListener(libraryCode: String) -> Observable<[Notification]> {
        guard let uid = Auth.auth().currentUser?.uid else {
            return Observable<[Notification]>.just([])
        }
        return addSnapshotListener("notifications", documentID: libraryCode)
            .flatMap { document -> Observable<[Notification]> in
                    
                guard let data = document.data(),
                      let applyNotifications = data["applyNotifications"] as? [String : [[String : Any]]],
                      let myNotifications = applyNotifications[uid] else {
                          return Observable<[Notification]>.just([])
                      }
                
                return Observable<[Notification]>.just(
                    
                    myNotifications.compactMap { info -> Notification? in
                        if let books_data = info["books_data"] as? [String : String],
                           let from_colorCode = info["from_colorCode"] as? String,
                           let from_name = info["from_name"] as? String,
                           let from_uid = info["from_uid"] as? String,
                           let rent_period = info["rent_period"] as? Int,
                           let date = info["date"] as? Timestamp,
                           let to_name = info["to"] as? String,
                           let to_uid = info["to_uid"] as? String {
                            
                            return Notification(from_colorCode: from_colorCode, from_name: from_name, from_uid: from_uid, to_name: to_name, to_uid: to_uid, rent_period: rent_period, date: date.dateValue(), books_data: books_data)
                            
                        }
                        else {
                            return nil
                        }
                    }.reversed()
                )
    
            }
    }
    
    static func addBooksListener(libraryCode: String) -> Observable<[BookInfo]> {
        return addSnapshotListener("books", documentID: libraryCode)
            .flatMapLatest { document -> Observable<[BookInfo]> in
                if let data = document.data(),
                   let rent_info = data["rent_info"] as? [[String : Any]],
                   let metadata  = data["books_data"] as? [[String : String]] {
                    
                    return Observable<[BookInfo]>.just(
                        zip(rent_info, metadata).map { rent, meta -> BookInfo in
                            return BookInfo(rent_info: rent, metadata: meta)
                        }
                    )
                }
                else {
                    return Observable<[BookInfo]>.error("本のリストが見つかりませんでした")
                }
            }
    }
    
    static func addLibraryListListener() -> Observable<[Library]> {
        guard let uid = user?.uid else {
            return Observable<[Library]>.just([])
        }
        return addSnapshotListner("library", key: "users", arrayContains: uid)
            .flatMapLatest { snapshot -> Observable<[Library]> in
                
                return Observable<[Library]>
                    .just(
                        snapshot.documents.compactMap { document -> Library? in
                            
                            let data = document.data()
                            
                            if let administrator = data["administrator"] as? String,
                               let administrator_name = data["administrator_name"] as? String,
                               let book_count = data["book_count"] as? Int,
                               let invite_code = data["invite_code"] as? String,
                               let library_name = data["library_name"] as? String,
                               let library_code = data["library_code"] as? String,
                               let users = data["users"] as? [String],
                               let users_data = data["users_data"] as? [String:String],
                               let users_name = data["users_name"] as? [String],
                               let users_books = data["users_books"] as? [String:[String]] {
                                
                                return Library(administrator: administrator,
                                               administrator_name: administrator_name,
                                               book_count: book_count,
                                               invite_code: invite_code,
                                               library_name: library_name,
                                               library_code: library_code,
                                               users: users,
                                               users_data: users_data,
                                               users_name: users_name,
                                               users_books: users_books
                                )
                                
                            }else{
                                return nil
                            }
                            
                        }
                    )
            }
    }
    
    static func addLibraryListener(libraryCode: String) -> Observable<Library> {
        return addSnapshotListner("library", key: "library_code", isEqualTo: libraryCode)
            .flatMapLatest { snapshot -> Observable<Library> in
                if let data = snapshot.documents.first?.data(),
                   let administrator = data["administrator"] as? String,
                   let administrator_name = data["administrator_name"] as? String,
                   let book_count = data["book_count"] as? Int,
                   let invite_code = data["invite_code"] as? String,
                   let library_name = data["library_name"] as? String,
                   let library_code = data["library_code"] as? String,
                   let users = data["users"] as? [String],
                   let users_data = data["users_data"] as? [String:String],
                   let users_name = data["users_name"] as? [String],
                   let users_books = data["users_books"] as? [String:[String]] {
                    
                    return Observable<Library>.just(
                        Library(administrator: administrator,
                                administrator_name: administrator_name,
                                book_count: book_count,
                                invite_code: invite_code,
                                library_name: library_name,
                                library_code: library_code,
                                users: users,
                                users_data: users_data,
                                users_name: users_name,
                                users_books: users_books
                        )
                    )
                }
                else {
                    return Observable.error("not found library")
                }
            }
        
    }
    
    static func getLibraryList() -> Observable<[Library]> {
        guard let uid = user?.uid else {
            return Observable<[Library]>.just([])
        }
        return findDocuments("library", key: "users", arrayContains: uid)
            .flatMap { snapshot -> Observable<[Library]> in
                
                return Observable<[Library]>
                    .just(
                        snapshot.documents.compactMap { document -> Library? in
                            
                            let data = document.data()
                            
                            if let administrator = data["administrator"] as? String,
                               let administrator_name = data["administrator_name"] as? String,
                               let book_count = data["book_count"] as? Int,
                               let invite_code = data["invite_code"] as? String,
                               let library_name = data["library_name"] as? String,
                               let library_code = data["library_code"] as? String,
                               let users = data["users"] as? [String],
                               let users_data = data["users_data"] as? [String:String],
                               let users_name = data["users_name"] as? [String],
                               let users_books = data["users_books"] as? [String:[String]] {
                                
                                return Library(administrator: administrator,
                                               administrator_name: administrator_name,
                                               book_count: book_count,
                                               invite_code: invite_code,
                                               library_name: library_name,
                                               library_code: library_code,
                                               users: users,
                                               users_data: users_data,
                                               users_name: users_name,
                                               users_books: users_books
                                )
                                
                            }else{
                                return nil
                            }
                            
                        }
                    )
            }
    }

    static func participateInLibrary(inviteCode: String) -> Observable<String> {
        
        return findDocuments("library", key: "invite_code", isEqualTo: inviteCode)
            .flatMap { snapshot -> Observable<String> in
                
                if let docID = snapshot.documents.first?.documentID,
                   let data = snapshot.documents.first?.data(),
                   var users = data["users"] as? [String],
                   var users_data = data["users_data"] as? [String:String],
                   var users_name = data["users_name"] as? [String],
                   let uid = Auth.auth().currentUser?.uid,
                   let color_code = FirebaseUtil.colorCode,
                   let currentUserName = FirebaseUtil.userName {
                    
                    if users.contains(uid) {
                        return Observable<String>.create { observer -> Disposable in
                            observer.onNext("既に参加しています")
                            return Disposables.create()
                        }
                    }else{
                        users_data.updateValue(color_code, forKey: uid)
                        users.append(uid)
                        users_name.append(currentUserName)
                        
                        return updateDocument("library", documentID: docID, updateData: [
                            "users" : users,
                            "users_data" : users_data,
                            "users_name" : users_name
                        ])
                    }
                    
                }else{
                    
                    return Observable<String>.create {
                        $0.onNext("招待コードを間違えています")
                        return Disposables.create()
                    }
                    
                }
            }
        
    }
    
    private static func createInviteCode() -> String {
        let letters : NSString = "0123456789"
        let len = UInt32(letters.length)

        var randomString = ""

        for _ in 0 ..< 8 {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }

        return randomString
    }
    
}

extension Array {
    
    mutating func multipleDelete(at: [Int]) {
        let sortedAt = at.sorted { $0 > $1 }
        sortedAt.forEach { at in
            self.remove(at: at)
        }
    }
    
}
