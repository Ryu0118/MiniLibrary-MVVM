//
//  UserListViewModel.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/17.
//

import RxSwift
import RxCocoa

protocol UserListViewModelInputs: AnyObject {
    var libraryCodeObserver: PublishSubject<String> { get }
    var exitLibraryObserver: AnyObserver<String> { get }
}

protocol UserListViewModelOutputs: AnyObject {
    var usersDataObserver: PublishSubject<[(String, String)]> { get }
}

protocol UserListViewModelType: AnyObject {
    var inputs: UserListViewModelInputs { get }
    var outputs: UserListViewModelOutputs { get }
    var exitLibraryResponse: PublishRelay<String> { get }
}

class UserListViewModel: UserListViewModelType, UserListViewModelInputs, UserListViewModelOutputs {
    
    var inputs: UserListViewModelInputs { return self }
    var outputs: UserListViewModelOutputs { return self }
    
    //inputs
    var libraryCodeObserver = PublishSubject<String>()
    private var exitLibrarySubject = PublishSubject<String>()
    var exitLibraryObserver: AnyObserver<String> {
        return exitLibrarySubject.asObserver()
    }
    //outputs
    var usersDataObserver = PublishSubject<[(String, String)]>()
    var exitLibraryResponse = PublishRelay<String>()
    
    private let disposeBag = DisposeBag()
    
    init() {
        
        exitLibrarySubject
            .flatMap { libraryCode -> Observable<String> in
                return FirebaseUtil.exitLibrary(libraryCode: libraryCode)
            }
            .bind(to: exitLibraryResponse)
            .disposed(by: disposeBag)
            
        
        libraryCodeObserver
            .flatMapLatest { code in
                return FirebaseUtil.addLibraryListener(libraryCode: code)
            }
            .flatMap { library in
                return Observable<[(String, String)]>.just(library.usersNameAndColorCode)
            }
            .bind(to: usersDataObserver)
            .disposed(by: disposeBag)

    }

}
