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
    
    //inputs
    
    //outputs
    var items = BehaviorRelay<[LibraryListSectionModel]>(value: [])
    
    func updateItems() {
        var sections = [LibraryListSectionModel]()
        
        //create mock data
        let item1 = LibraryItem.library(library: Library(title: "法政大学図書館", users: ["りき", "たなか", "喜多村","りき", "たなか", "喜多村","りき", "たなか", "喜多村"], bookCount: 20))
        let item2 = LibraryItem.library(library: Library(title: "明治大学図書館", users: ["澁谷", "上條", "喜多村"], bookCount: 20))
        let item3 = LibraryItem.library(library: Library(title: "立教大学図書館", users: ["しぶ", "たけし", "つとむ"], bookCount: 20))
        let librarySection = LibraryListSectionModel(model: .library, items: [item1, item2, item3])
        sections.append(librarySection)
        
        items.accept(sections)
    }
    
}
