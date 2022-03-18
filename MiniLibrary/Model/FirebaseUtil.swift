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
                   var book_count = querySnapshot.documents.first?.data()["book_count"] as? Int
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
                    
                    let updateData: [String : Any] = [
                        "rent_info" : gotRentInfo,
                        "books" : gotBooks,
                        "books_data" : gotBooksData
                    ]
                
                    return Observable.combineLatest(updateDocument("books", documentID: libraryCode, updateData: updateData), updateDocument("library", documentID: docID, updateData: ["book_count" : book_count]))
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
                       var book_count = document.data()["book_count"] as? Int {
                        book_count += 1
                        return Observable.combineLatest(addDocument("books", documentID: libraryCode, data: data), updateDocument("library", documentID: document.documentID, updateData: ["book_count" : book_count]))
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
            return addDocument("library", data: [
                "library_name" : libraryName,
                "library_code" : UUID().uuidString,
                "administrator" : uid,
                "administrator_name" : administrator,
                "users_data" : [uid:FirebaseUtil.colorCode ?? "8ac6d1"],
                "users" : [uid],
                "users_name" : [administrator],
                "book_count" : 0,
                "invite_code" : createInviteCode(),
            ])
        }
        else {
            return Observable<String>.create {
                $0.onNext("ログイン中のユーザーが見つかりませんでした")
                return Disposables.create()
            }
        }
    }
    
    static func exitLibrary(libraryCode: String) -> Observable<String> {
        return findDocuments("library", key: "library_code", isEqualTo: libraryCode)
            .flatMap { snapshot -> Observable<String> in

                if let uid = Auth.auth().currentUser?.uid,
                   let docID = snapshot.documents.first?.documentID,
                   let data = snapshot.documents.first?.data(),
                   var users = data["users"] as? [String],
                   var users_name = data["users_name"] as? [String],
                   var users_data = data["users_data"] as? [String:String],
                   let firstIndex = users.firstIndex(of: uid) {
                
                    users.remove(at: firstIndex)
                    users_name.remove(at: firstIndex)
                    users_data.removeValue(forKey: uid)
                    
                    let updateData: [String:Any] = [
                        "users" : users,
                        "users_name" : users_name,
                        "users_data" : users_data
                    ]
                    
                    return updateDocument("library", documentID: docID, updateData: updateData)
                    
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
    
    static func addLibraryListListener() -> Observable<[Library]> {
        guard let uid = user?.uid else {
            return Observable<[Library]>.just([])
        }
        return addSnapshotListner("library", key: "users", arrayContains: uid)
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
                               let users_name = data["users_name"] as? [String] {
                                
                                return Library(administrator: administrator,
                                               administrator_name: administrator_name,
                                               book_count: book_count,
                                               invite_code: invite_code,
                                               library_name: library_name,
                                               library_code: library_code,
                                               users: users,
                                               users_data: users_data,
                                               users_name: users_name
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
            .flatMap { snapshot -> Observable<Library> in
                if let data = snapshot.documents.first?.data(),
                   let administrator = data["administrator"] as? String,
                   let administrator_name = data["administrator_name"] as? String,
                   let book_count = data["book_count"] as? Int,
                   let invite_code = data["invite_code"] as? String,
                   let library_name = data["library_name"] as? String,
                   let library_code = data["library_code"] as? String,
                   let users = data["users"] as? [String],
                   let users_data = data["users_data"] as? [String:String],
                   let users_name = data["users_name"] as? [String] {
                    
                    return Observable<Library>.just(
                        Library(administrator: administrator,
                                administrator_name: administrator_name,
                                book_count: book_count,
                                invite_code: invite_code,
                                library_name: library_name,
                                library_code: library_code,
                                users: users,
                                users_data: users_data,
                                users_name: users_name
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
                               let users_name = data["users_name"] as? [String] {
                                
                                return Library(administrator: administrator,
                                               administrator_name: administrator_name,
                                               book_count: book_count,
                                               invite_code: invite_code,
                                               library_name: library_name,
                                               library_code: library_code,
                                               users: users,
                                               users_data: users_data,
                                               users_name: users_name
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
