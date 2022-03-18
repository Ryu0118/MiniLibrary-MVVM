//
//  LibraryViewModel.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/17.
//

import RxSwift
import RxCocoa
import RxNuke
import Nuke
import KRProgressHUD

protocol LibraryViewModelInputs: AnyObject {
    var bookinfoObserver: AnyObserver<BookInfo> { get }
    var addBookObserver: AnyObserver<(BookInfo, Library)> { get }
}

protocol LibraryViewModelOutputs: AnyObject {
    var metadataResponse: Driver<(UIImage, BookInfo)> { get }
    var addBookResponse: Observable<String> { get }
    var items: BehaviorRelay<[LibrarySectionModel]> { get }
    var bookinfo: PublishSubject<[BookInfo]> { get }
}

protocol LibraryViewModelType: AnyObject {
    var inputs: LibraryViewModelInputs { get }
    var outputs: LibraryViewModelOutputs { get }
}


typealias Metadata = (UIImage, BookInfo)

class LibraryViewModel: LibraryViewModelType, LibraryViewModelOutputs, LibraryViewModelInputs {

    var inputs: LibraryViewModelInputs { return self }
    var outputs: LibraryViewModelOutputs { return self }
    
    //inputs
    private var bookinfoSubject = PublishSubject<BookInfo>()
    var bookinfoObserver: AnyObserver<BookInfo> {
        return bookinfoSubject.asObserver()
    }
    private var addBookSubject = PublishSubject<(BookInfo, Library)>()
    var addBookObserver: AnyObserver<(BookInfo, Library)> {
        return addBookSubject.asObserver()
    }
    
    
    //outputs
    var metadataResponse: Driver<Metadata>
    var addBookResponse: Observable<String>
    var items = BehaviorRelay<[LibrarySectionModel]>(value: [])
    var bookinfo = PublishSubject<[BookInfo]>()
    
    private let disposeBag = DisposeBag()
    
    init() {
        
        addBookResponse = addBookSubject
            .asObservable()
            .do { _ in KRProgressHUD.show() }
            .flatMap { bookinfo, library -> Observable<String> in
                return FirebaseUtil.addBook(libraryCode: library.library_code, bookinfo: bookinfo)
            }
        
        metadataResponse = bookinfoSubject
            .asObservable()
            .flatMap { bookinfo -> Observable<Metadata> in
                if let url = bookinfo.imageURL {
                    return ImagePipeline.shared.rx.loadImage(with: URL(string: url)!)
                        .asObservable()
                        .flatMap { imageResponse -> Observable<Metadata> in
                            return Observable<Metadata>.just((imageResponse.image, bookinfo))
                        }
                }
                else{
                    return Observable<Metadata>.just((UIImage.noimage, bookinfo))
                }
                    
            }
            .asDriver(onErrorJustReturn: (UIImage.noimage, BookInfo(rent_info: [:], metadata: [:])))
            
    }
    
    func updateItems(libraryCode: String) {
        FirebaseUtil.addBooksListener(libraryCode: libraryCode)
            .subscribe(onNext: {[weak self] bookinfo in
                
                self?.outputs.bookinfo.onNext(bookinfo)
                
                var rentingItems = [LibraryItem]()
                var allBooksItems = [LibraryItem]()
                
                for book in bookinfo {
                    if book.isRented {
                        let libraryItem = LibraryItem.renting(bookinfo: book)
                        rentingItems.append(libraryItem)
                    }
                    else {
                        let libraryItem = LibraryItem.allbooks(bookinfo: book)
                        allBooksItems.append(libraryItem)
                    }
                }
                
                let librarySection = [
                    LibrarySectionModel(model: .renting, items: rentingItems),
                    LibrarySectionModel(model: .allbooks, items: allBooksItems)
                ]
                self?.items.accept(librarySection)
            })
            .disposed(by: disposeBag)
    }
    
}

