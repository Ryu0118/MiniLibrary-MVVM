//
//  RegistrationViewModel.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/15.
//

import RxSwift
import RxCocoa
import RxRelay
import Firebase
import FirebaseAuth
import FirebaseFirestore

protocol RegistrationViewModelInputs: AnyObject {
    var nameObserver: AnyObserver<String> { get }
    var emailObserver: AnyObserver<String> { get }
    var passwordObserver: AnyObserver<String> { get }
    var registrationObserver: AnyObserver<Registration> { get }
}

protocol RegistrationViewModelOutputs: AnyObject {
    var isValidName: Driver<Bool> { get }
    var isValidEmail: Driver<Bool> { get }
    var isValidPassword: Driver<Bool> { get }
    var isEnabledButton: Driver<Bool> { get }
    var isSuccessRegistration: PublishRelay<Bool> { get }
}

protocol RegistrationViewModelType: AnyObject {
    var inputs: RegistrationViewModelInputs { get }
    var outputs: RegistrationViewModelOutputs { get }
}

class RegistrationViewModel : RegistrationViewModelType, RegistrationViewModelInputs, RegistrationViewModelOutputs {
    var inputs: RegistrationViewModelInputs { return self }
    var outputs: RegistrationViewModelOutputs { return self }
    
    //inputs
    private var nameSubject = BehaviorSubject<String>(value: "")
    var nameObserver: AnyObserver<String> {
        return nameSubject.asObserver()
    }
    private var emailSubject = BehaviorSubject<String>(value: "")
    var emailObserver: AnyObserver<String> {
        return emailSubject.asObserver()
    }
    private var passwordSubject = BehaviorSubject<String>(value: "")
    var passwordObserver: AnyObserver<String> {
        return passwordSubject.asObserver()
    }
    private var registrationSubject = PublishSubject<Registration>()
    var registrationObserver: AnyObserver<Registration> {
        return registrationSubject.asObserver()
    }
    
    //outputs
    var isValidEmail: Driver<Bool>
    var isValidPassword: Driver<Bool>
    var isEnabledButton: Driver<Bool>
    var isValidName: Driver<Bool>
    var isSuccessRegistration = PublishRelay<Bool>()
    
    private let disposeBag = DisposeBag()
    
    init() {
        
        isValidEmail = emailSubject
            .asObservable()
            .flatMapLatest { email -> Observable<Bool> in
            return Observable<Bool>.just(Regex.isValidEmail(email))
        }
        .asDriver(onErrorJustReturn: false)
        
        isValidPassword = passwordSubject
            .asObservable()
            .flatMapLatest { password -> Observable<Bool> in
            return Observable<Bool>.just(Regex.isValidPassword(password))
        }
        .asDriver(onErrorJustReturn: false)
        
        
        isValidName = nameSubject
            .asObservable()
            .flatMapLatest { name -> Observable<Bool> in
                return Observable<Bool>.just(!name.isEmpty)
            }
            .asDriver(onErrorJustReturn: false)
        
        isEnabledButton = Observable.combineLatest(isValidEmail.asObservable(), isValidPassword.asObservable(), isValidName.asObservable()) {
            return $0 && $1 && $2
        }
        .asDriver(onErrorJustReturn: false)
        
        registrationSubject
            .asObservable()
            .subscribe {[weak self] registration in
                guard let registration = registration.element,
                      let self = self else { return }
                
                print(registration)
                
                Auth.auth().createUser(withEmail: registration.email, password: registration.password, completion: { result, error in
                    
                    if let user = result?.user {
                        print("ユーザー作成完了 uid:" + user.uid)
                        
                        Firestore.firestore()
                            .collection("users")
                            .document(user.uid)
                            .setData([
                                "name" : registration.name
                            ], completion: { error in
                                if let error = error {
                                    print("Firestore 新規登録失敗" + error.localizedDescription)
                                    self.isSuccessRegistration.accept(false)
                                }else{
                                    print("ユーザー作成完了 name:" + registration.name)
                                    self.isSuccessRegistration.accept(true)
                                }
                            })
                    }
                    else if let error = error {
                        print("Firebase Auth 新規登録失敗" + error.localizedDescription)
                        self.isSuccessRegistration.accept(false)
                    }
                    else {
                        print("ユーザーが見つかりませんでした")
                        self.isSuccessRegistration.accept(false)
                    }
                    
                })
            }
            .disposed(by: disposeBag)
        
    }
}
