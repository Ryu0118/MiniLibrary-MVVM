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
    func permitRentalApplication(libraryCode: String, notification: Notification)
}

protocol NotificationViewModelOutputs: AnyObject {
    var notifications: BehaviorSubject<[Notification]> { get }
    var permitRentBookResponse: PublishSubject<String> { get }
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
    var permitRentBookResponse = PublishSubject<String>()
    //inputs
    func updateItems(libraryCode: String) {
        
        FirebaseUtil.notificationListListener(libraryCode: libraryCode)
            .bind(to: notifications)
            .disposed(by: disposeBag)
        
    }
    
    func permitRentalApplication(libraryCode: String, notification: Notification) {
        
        FirebaseUtil.permitRentBook(libraryCode: libraryCode, notification: notification)
            .bind(to: permitRentBookResponse)
            .disposed(by: disposeBag)
        
    }
    
}
