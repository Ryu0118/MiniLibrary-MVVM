//
//  LoginViewModel.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/15.
//

import RxSwift
import RxCocoa
import FirebaseAuth

protocol LoginViewModelInputs: AnyObject {
    var emailObserver: AnyObserver<String> { get }
    var passwordObserver: AnyObserver<String> { get }
    var loginObserver: AnyObserver<LoginInfo> { get }
}

protocol LoginViewModelOutputs: AnyObject {
    var isValidEmail: Driver<Bool> { get }
    var isValidPassword: Driver<Bool> { get }
    var isEnabledButton: Driver<Bool> { get }
    var isSuccessLogin: PublishRelay<Bool> { get }
}

protocol LoginViewModelType: AnyObject {
    var inputs: LoginViewModelInputs { get }
    var outputs: LoginViewModelOutputs { get }
}

class LoginViewModel : LoginViewModelType, LoginViewModelInputs, LoginViewModelOutputs {
    var inputs: LoginViewModelInputs { return self }
    var outputs: LoginViewModelOutputs { return self }
    
    //inputs
    private var emailSubject = BehaviorSubject<String>(value: "")
    var emailObserver: AnyObserver<String> {
        return emailSubject.asObserver()
    }
    private var passwordSubject = BehaviorSubject<String>(value: "")
    var passwordObserver: AnyObserver<String> {
        return passwordSubject.asObserver()
    }
    private var loginSubject = PublishSubject<LoginInfo>()
    var loginObserver: AnyObserver<LoginInfo> {
        return loginSubject.asObserver()
    }
    
    //outputs
    var isValidEmail: Driver<Bool>
    var isValidPassword: Driver<Bool>
    var isEnabledButton: Driver<Bool>
    var isSuccessLogin = PublishRelay<Bool>()
    
    private let disposeBag = DisposeBag()
    
    init() {
        
        isValidEmail = emailSubject.asObservable().flatMapLatest { email -> Observable<Bool> in
            return Observable<Bool>.just(Regex.isValidEmail(email))
        }
        .asDriver(onErrorJustReturn: false)
        
        isValidPassword = passwordSubject.asObservable().flatMapLatest { password -> Observable<Bool> in
            return Observable<Bool>.just(Regex.isValidPassword(password))
        }
        .asDriver(onErrorJustReturn: false)
        
        isEnabledButton = Observable.combineLatest(isValidEmail.asObservable(), isValidPassword.asObservable()) {
            return $0 && $1
        }
        .asDriver(onErrorJustReturn: false)
        
        loginSubject
            .asObservable()
            .flatMapLatest { info in
                return FirebaseUtil.signIn(info: info)
            }
            .bind(to: self.isSuccessLogin)
            .disposed(by: disposeBag)
        
    }
}
