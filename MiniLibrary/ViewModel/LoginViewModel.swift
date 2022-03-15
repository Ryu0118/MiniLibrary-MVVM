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
            .subscribe {[weak self] info in
                guard let self = self,
                      let info = info.element else { return }
                
                Auth.auth().signIn(withEmail: info.email, password: info.password, completion: { result, error in
                    if let _ = result?.user {
                        self.isSuccessLogin.accept(true)
                    }
                    else if let error = error {
                        print("Failed Login: ", error.localizedDescription)
                        self.isSuccessLogin.accept(false)
                    }else{
                        print("User Not found")
                        self.isSuccessLogin.accept(false)
                    }
                })
                
            }
            .disposed(by: disposeBag)
        
    }
}
