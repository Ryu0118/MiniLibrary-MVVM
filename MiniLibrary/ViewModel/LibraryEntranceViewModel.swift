//
//  LibraryEntranceViewModel.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/17.
//

import RxSwift
import RxCocoa

protocol LibraryEntranceViewModelInputs: AnyObject {
    var libraryNameSubject: PublishSubject<String> { get }
    var inviteCodeSubject: PublishSubject<String> { get }
}

protocol LibraryEntranceViewModelOutputs: AnyObject {
    var isSuccessedAddLibrary: PublishSubject<()> { get }
    var isSuccessedParticipateInLibrary: PublishSubject<()> { get }
}

protocol LibraryEntranceViewModelType: AnyObject {
    var inputs: LibraryEntranceViewModelInputs { get }
    var outputs: LibraryEntranceViewModelOutputs { get }
}

class LibraryEntranceViewModel: LibraryEntranceViewModelType, LibraryEntranceViewModelInputs, LibraryEntranceViewModelOutputs {
    
    var inputs: LibraryEntranceViewModelInputs { return self }
    var outputs: LibraryEntranceViewModelOutputs { return self }
    
    //inputs
    var libraryNameSubject = PublishSubject<String>()
    var inviteCodeSubject = PublishSubject<String>()

    
    //outputs
    var isSuccessedAddLibrary = PublishSubject<()>()
    var isSuccessedParticipateInLibrary = PublishSubject<()>()
    
    private let disposeBag = DisposeBag()
    
    init() {
        
        libraryNameSubject
            .asObservable()
            .flatMapLatest { name in
                return FirebaseUtil.addLibrary(libraryName: name, administrator: FirebaseUtil.userName!)
            }
            .bind(to: outputs.isSuccessedAddLibrary)
            .disposed(by: disposeBag)
        
        inviteCodeSubject
            .asObservable()
            .flatMapLatest { code in
                return FirebaseUtil.participateInLibrary(inviteCode: code)
            }
            .bind(to: outputs.isSuccessedParticipateInLibrary)
            .disposed(by: disposeBag)
        
    }
    
}
