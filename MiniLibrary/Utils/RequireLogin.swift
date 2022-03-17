//
//  RequireLogin.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/16.
//

import Firebase
import FirebaseAuth
import FirebaseFirestore
import RxSwift
import RxCocoa

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}

protocol RequireLogin: AnyObject {
    var user: User? { get }
    var db: Firestore { get }
}

extension RequireLogin {
    
    static var db: Firestore {
        return Firestore.firestore()
    }
    
    static var user: User? {
        return Auth.auth().currentUser
    }
    
    static func getColorCode() -> Observable<String> {
        
        return Observable<String>.create { observer -> Disposable in
            guard let uid = self.user?.uid else {
                observer.onError("failed to fetch user")
                return Disposables.create()
            }
            
            db.collection("users").document(uid).getDocument(completion: { snapshot, error in
                if let snapshot = snapshot,
                   let dic = snapshot.data(),
                   let name = dic["color_code"] as? String,
                   snapshot.exists {
                    observer.onNext(name)
                    observer.onCompleted()
                }
                else if let error = error {
                    print("fetch colorcode failed:", error.localizedDescription)
                }
            })
            return Disposables.create()

        }
        
    }
    
    static func getUserName() -> Observable<String> {
        
        return Observable<String>.create { observer -> Disposable in
            guard let uid = self.user?.uid else {
                observer.onError("failed to fetch user")
                return Disposables.create()
            }
            
            db.collection("users").document(uid).getDocument(completion: { snapshot, error in
                if let snapshot = snapshot,
                   let dic = snapshot.data(),
                   let name = dic["name"] as? String,
                   snapshot.exists {
                    observer.onNext(name)
                    observer.onCompleted()
                }
                else if let error = error {
                    print("fetch username failed:", error.localizedDescription)
                }
            })
            return Disposables.create()
            
        }
    }
    
    var db: Firestore {
        return Firestore.firestore()
    }
    
    var user: User? {
        return Auth.auth().currentUser
    }
    
    func getUserName() -> Observable<String> {
        
        return Observable<String>.create {[weak self] observer -> Disposable in
            guard let self = self else {
                observer.onError("instance is already deallocated")
                return Disposables.create()
            }
            guard let uid = self.user?.uid else {
                observer.onError("failed to fetch user")
                return Disposables.create()
            }
            
            self.db.collection("users").document(uid).getDocument(completion: { snapshot, error in
                if let snapshot = snapshot,
                   let dic = snapshot.data(),
                   let name = dic["name"] as? String,
                   snapshot.exists {
                    observer.onNext(name)
                    observer.onCompleted()
                }
                else if let error = error {
                    print("fetch username failed:", error.localizedDescription)
                }
            })
            return Disposables.create()
            
        }
    }
    
    func getColorCode() -> Observable<String> {
        
        return Observable<String>.create {[weak self] observer -> Disposable in
            guard let uid = self?.user?.uid else {
                observer.onError("failed to fetch user")
                return Disposables.create()
            }
            
            self?.db.collection("users").document(uid).getDocument(completion: { snapshot, error in
                if let snapshot = snapshot,
                   let dic = snapshot.data(),
                   let name = dic["color_code"] as? String,
                   snapshot.exists {
                    observer.onNext(name)
                    observer.onCompleted()
                }
                else if let error = error {
                    print("fetch colorcode failed:", error.localizedDescription)
                }
            })
            return Disposables.create()

        }
        
    }
    
}
