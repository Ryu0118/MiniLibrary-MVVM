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
    
}

