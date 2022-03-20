//
//  NotificationViewController.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/19.
//

import UIKit
import RxSwift
import RxCocoa
import FirebaseAuth
import SnapKit

class NotificationViewController : UIViewController {
    
    let libraryCode: String
    
    private let viewModel = NotificationViewModel()
    private let disposeBag = DisposeBag()
    
    var tableView: UITableView!
    
    init(libraryCode: String) {
        self.libraryCode = libraryCode
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupNavigationBar()
        setupTableView()
        bind()
    }
    
}

extension NotificationViewController {
    
    private func setupTableView() {
        tableView = UITableView(frame: .zero, style: .plain)
        tableView.register(NotificationCell.self, forCellReuseIdentifier: NotificationCell.identifier)
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    private func bind() {
        
        viewModel.outputs.notifications
            .asDriver(onErrorJustReturn: [])
            .drive(tableView.rx.items(cellIdentifier: NotificationCell.identifier, cellType: NotificationCell.self)) { indexPath, notification, cell in
                cell.update(notification: notification)
                cell.selectionStyle = .none
            }
            .disposed(by: disposeBag)
        
        tableView.rx.itemSelected
            .observe(on: MainScheduler.instance)
            .withLatestFrom(viewModel.outputs.notifications) { indexPath, notifications -> Notification in
                return notifications[indexPath.row]
            }
            .withUnretained(self)
            .subscribe(onNext: { strongSelf, notification in
                print(notification.title)
                let bookinfo = BookInfo(rent_info: [:], metadata: notification.books_data)
                let alert = strongSelf.rentalApplicationAlert(bookinfo: bookinfo)
                let cancel = MiniLibraryAlertAction(message: "キャンセル", option: .normal, handler: nil)
                let action = MiniLibraryAlertAction(message: "貸出申請を許可", option: .normal, handler: {
                    strongSelf.viewModel.inputs.permitRentalApplication(libraryCode: strongSelf.libraryCode, notification: notification)
                })
                alert.addActions([cancel, action])
                strongSelf.present(alert, animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
        
        viewModel.outputs.permitRentBookResponse
            .asObservable()
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .subscribe(onNext: { strongSelf, response in
                if !response.isEmpty {
                    MiniLibraryAlertController.showErrorAlert(target: strongSelf, title: response)
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.inputs.updateItems(libraryCode: libraryCode)
        
    }
    
    @discardableResult
    private func rentalApplicationAlert(bookinfo: BookInfo, customView: UIView? = nil, isPresentOwner: Bool = true) -> MiniLibraryAlertController {
        let detailView = BookDetailView(bookinfo: bookinfo, isPresentOwner: isPresentOwner)
        
        var captionView: MiniLibraryLabel? = MiniLibraryLabel(size: 12)
        captionView?.textColor = .grayTextColor
        captionView?.text = bookinfo.caption
        captionView?.sizeToFit()
        captionView?.numberOfLines = 0
        if let caption = bookinfo.caption, caption.isEmpty { captionView = nil }
        
        let alert = MiniLibraryAlertController(customViews: [detailView, captionView, customView].compactMap { $0 }, multipledBy: 0.9)
        return alert
    }
    
    private func setupNavigationBar() {
        
        self.navigationItem.backButtonTitle = ""
        self.navigationItem.backButtonDisplayMode = .default
        
        if let navigationBar = self.navigationController?.navigationBar {
            
            navigationBar.tintColor = .black
            
            let titleLabel = MiniLibraryLabel(size: 16)
            titleLabel.text = "通知"
            navigationItem.titleView = titleLabel
            navigationBar.shadowImage = UIImage()
            navigationBar.backgroundColor = .white
            navigationBar.barTintColor = .white
            
        }
    }
    
}
