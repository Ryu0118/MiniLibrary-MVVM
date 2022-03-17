//
//  LibraryViewModel.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/17.
//

import RxSwift
import RxCocoa

protocol LibraryViewModelInputs: AnyObject {
    
}

protocol LibraryViewModelOutputs: AnyObject {
    
}

protocol LibraryViewModelType: AnyObject {
    var inputs: LibraryViewModelInputs { get }
    var outputs: LibraryViewModelOutputs { get }
}

class LibraryViewModel: LibraryViewModelType, LibraryViewModelOutputs, LibraryViewModelInputs {
    
    var inputs: LibraryViewModelInputs { return self }
    var outputs: LibraryViewModelOutputs { return self }
    
    init() {
        
    }
    
}

