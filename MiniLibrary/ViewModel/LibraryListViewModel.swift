//
//  LibraryListViewModel.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/16.
//

import RxSwift
import RxCocoa
import Firebase
import FirebaseAuth
import FirebaseFirestore

protocol LibraryListViewModelInputs: AnyObject {
    
}

protocol LibraryListViewModelOutputs: AnyObject {
    var items: BehaviorRelay<[LibraryListSectionModel]> { get }
}

protocol LibraryListViewModelType: AnyObject {
    var inputs: LibraryListViewModelInputs { get }
    var outputs: LibraryListViewModelOutputs { get }
}

class LibraryListViewModel: LibraryListViewModelType, LibraryListViewModelInputs, LibraryListViewModelOutputs {
    
    var inputs: LibraryListViewModelInputs { return self }
    var outputs: LibraryListViewModelOutputs { return self }
    
    private let disposeBag = DisposeBag()
    
    //inputs
    
    //outputs
    var items = BehaviorRelay<[LibraryListSectionModel]>(value: [])
    
    func updateItems() {
        
        FirebaseUtil.addLibraryListListener()
            .subscribe {[weak self] libraries in
                guard let libraries = libraries.element else { return }
                let libraryItems = libraries.map { LibraryListItem.library(library: $0) }
                let librarySection = [LibraryListSectionModel(model: .library, items: libraryItems)]
                self?.items.accept(librarySection)
            }
            .disposed(by: disposeBag)
        
    }
    
}
