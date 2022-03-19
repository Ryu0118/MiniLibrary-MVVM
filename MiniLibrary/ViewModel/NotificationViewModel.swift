//
//  NotificationViewModel.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/19.
//

import RxSwift
import RxCocoa
import FirebaseAuth

protocol NotificationViewModelInputs: AnyObject {
    func updateItems(libraryCode: String)
}

protocol NotificationViewModelOutputs: AnyObject {
    var notifications: BehaviorSubject<[Notification]> { get }
}

protocol NotificationViewModelType: AnyObject {
    var inputs: NotificationViewModelInputs { get }
    var outputs: NotificationViewModelOutputs { get }
}

class NotificationViewModel: NotificationViewModelType, NotificationViewModelInputs, NotificationViewModelOutputs {
    
    var inputs: NotificationViewModelInputs { return self }
    var outputs: NotificationViewModelOutputs { return self }
    
    private let disposeBag = DisposeBag()
    
    //outputs
    var notifications = BehaviorSubject<[Notification]>(value: [])
    
    //inputs
    func updateItems(libraryCode: String) {
        
        FirebaseUtil.notificationListListener(libraryCode: libraryCode)
            .bind(to: notifications)
            .disposed(by: disposeBag)
        
    }
    
}
