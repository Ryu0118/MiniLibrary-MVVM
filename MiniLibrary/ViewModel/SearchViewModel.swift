//
//  SearchViewModel.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/21.
//

import RxSwift
import RxCocoa
import KRProgressHUD

protocol SearchViewModelInputs: AnyObject {
    var searchObserver: AnyObserver<String> { get }
    var textObserver: AnyObserver<String> { get }
}

protocol SearchViewModelOutputs: AnyObject {
    var bookInformations: Driver<[BookInfo]> { get }
    var addBookResponse: PublishSubject<String> { get }
}

protocol SearchViewModelType: AnyObject {
    var inputs: SearchViewModelInputs { get }
    var outputs: SearchViewModelOutputs { get }
}

class SearchViewModel: SearchViewModelType, SearchViewModelInputs, SearchViewModelOutputs {
    
    var inputs: SearchViewModelInputs { return self }
    var outputs: SearchViewModelOutputs { return self }
    
    //inputs
    private var searchSubject = PublishSubject<String>()
    private let textSubject = PublishSubject<String>()
    var textObserver: AnyObserver<String> {
        return textSubject.asObserver()
    }
    var searchObserver: AnyObserver<String> {
        return searchSubject.asObserver()
    }
    
    //outputs
    private let bookInformationsSubject = PublishSubject<[BookInfo]>()
    var bookInformations: Driver<[BookInfo]> {
        return bookInformationsSubject.asDriver(onErrorJustReturn: [])
    }
    
    var addBookResponse = PublishSubject<String>()
    
    private let disposeBag = DisposeBag()
    
    init() {
        
        searchSubject
            .asObservable()
            .filter { !$0.isEmpty }
            .distinctUntilChanged()
            .flatMap { searchString -> Observable<[BookInfo]> in
                return GoogleBooksAPI.searchBooks(keyword: searchString)
            }
            .bind(to: bookInformationsSubject)
            .disposed(by: disposeBag)
        
        textSubject
            .asObservable()
            .subscribe(onNext: {[weak self] text in
                if text.isEmpty {
                    self?.bookInformationsSubject.onNext([])
                    KRProgressHUD.dismiss()
                }
            })
            .disposed(by: disposeBag)
        
    }
    
    func addBook(libraryCode: String, bookinfo: BookInfo) {
        
        FirebaseUtil.addBook(libraryCode: libraryCode, bookinfo: bookinfo)
            .bind(to: addBookResponse)
            .disposed(by: disposeBag)
        
    }

}
