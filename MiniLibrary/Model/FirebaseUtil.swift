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
                            "name" : registration.name
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
    
    static func addDocument(_ collection: String, data: [String:Any]) -> Observable<()> {
        Observable<()>.create { observer -> Disposable in
            db.collection(collection).addDocument(data: data) { err in
                if let error = err {
                    observer.onError(error)
                }else{
                    observer.onNext(())
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }
    
    static func addLibrary(libraryName: String, administrator: String) -> Observable<()> {
        if let uid = Auth.auth().currentUser?.uid {
            return addDocument("library", data: [
                "library_name" : libraryName,
                "administrator" : uid,
                "administrator_name" : administrator,
                "users" : [uid],
                "users_name" : [administrator],
                "books" : [:],
                "invite_code" : createInviteCode(),
            ])
        }
        else {
            return Observable<()>.create {
                $0.onError("current user not found")
                return Disposables.create()
            }
        }
    }
    
    static func updateDocument(_ collection: String, document:String, updateData: [String:Any]) -> Observable<()> {
        return Observable.create { observer -> Disposable in
            db.collection(collection).document(document).updateData(updateData) {error in
                if let error = error {
                    observer.onError(error)
                }else{
                    observer.onNext(())
                    observer.onCompleted()
                }
            }
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
        

    static func participateInLibrary(inviteCode: String) -> Observable<()> {
        
        return findDocuments("library", key: "invite_code", isEqualTo: inviteCode)
            .flatMap { snapshot -> Observable<()> in
                
                if let docID = snapshot.documents.first?.documentID,
                   let data = snapshot.documents.first?.data(),
                   var users = data["users"] as? [String],
                   var users_name = data["users_name"] as? [String],
                   let uid = Auth.auth().currentUser?.uid,
                   let currentUserName = FirebaseUtil.userName {
                    
                    if users.contains(uid) {
                        return Observable<()>.create {
                            $0.onError("既に参加しています")
                            return Disposables.create()
                        }
                    }else{
                        users.append(uid)
                        users_name.append(currentUserName)
                        
                        return updateDocument("library", document: docID, updateData: [
                            "users" : users,
                            "users_name" : users_name
                        ])
                    }
                    
                }else{
                    
                    return Observable<()>.create {
                        $0.onError("found nil value")
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
