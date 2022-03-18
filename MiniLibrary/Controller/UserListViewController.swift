//
//  UserListViewController.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/17.
//

import UIKit
import FirebaseAuth
import RxSwift
import RxCocoa
import SnapKit

class UserListViewController : UIViewController {
    
    let library: Library
    
    var rightBarButton: UIBarButtonItem!
    //var isAdministrator = false
    
    var tableView: UITableView!
    var inviteButton: RegisterButton! {
        didSet {
            inviteButton.setTitle("友達を招待", for: .normal)
        }
    }
    let viewModel = UserListViewModel()
    
    private let disposeBag = DisposeBag()
    
    init(library: Library) {
        self.library = library
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupNavigationBar()
        setupInviteButton()
        setupTableView()
        bind()
    }
    
}

extension UserListViewController {
    
    private func bind() {
        
        viewModel.inputs.libraryCodeObserver.onNext(library.library_code)
        
        viewModel.outputs.usersDataObserver
            .asDriver(onErrorJustReturn: library.userLists)
            .drive(tableView.rx.items(cellIdentifier: MemberCell.identifier, cellType: MemberCell.self)) { indexPath, userList, cell in
                cell.setup(userList: userList)
                cell.selectionStyle = .none
            }
            .disposed(by: disposeBag)
        
        
        inviteButton.rx.tap.asDriver()
            .drive {[weak self] _ in
                guard let self = self else { return }
                let alert = MiniLibraryAlertController(title: "招待コード", bigMessage: self.library.invite_code, textFieldConfiguration: nil, actions: [MiniLibraryAlertAction(message: "閉じる", option: .cancel, handler: nil)])
                self.present(alert, animated: true, completion: nil)
            }
            .disposed(by: disposeBag)
        
        rightBarButton.rx.tap.asDriver()
            .drive {[weak self] _ in
                guard let self = self else { return }
                
                let alert = MiniLibraryAlertController(title: "警告", message: "本当に退会しますか？", textFieldConfiguration: nil)
                let cancel = MiniLibraryAlertAction(message: "キャンセル", option: .cancel, handler: nil)
                let yes = MiniLibraryAlertAction(message: "はい", option: .normal, handler: {
                    alert.dismiss(animated: true, completion: {
                        self.viewModel.exitLibraryObserver.onNext(self.library.library_code)
                    })
                })
                alert.addActions([cancel, yes])
                
                self.present(alert, animated: true, completion: nil)
            }
            .disposed(by: disposeBag)
        
        viewModel.exitLibraryResponse
            .withUnretained(self)
            .subscribe(onNext: { controller, response in
                if !response.isEmpty {
                    let alert = MiniLibraryAlertController(title: "エラー", message: response, actions: [MiniLibraryAlertAction(message: "OK", option: .normal, handler: nil)])
                    controller.present(alert, animated: true, completion: nil)
                }else{
                    controller.navigationController?.popToRootViewController(animated: true)
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func setupInviteButton() {
        inviteButton = RegisterButton(isBoundAnimationEnabled: false, cornerRadius: 0)
        view.addSubview(inviteButton)
        inviteButton.snp.makeConstraints {
            $0.left.right.bottom.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(58)
        }
    }
    
    private func setupTableView() {
        tableView = UITableView(frame: .zero, style: .plain)
        tableView.register(MemberCell.self, forCellReuseIdentifier: MemberCell.identifier)
        tableView.separatorStyle = .none
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.left.right.equalTo(view.safeAreaLayoutGuide)
            $0.bottom.equalTo(inviteButton.snp.top)
        }
    }
    
    private func setupNavigationBar() {
        self.navigationItem.backButtonTitle = ""
        self.navigationItem.backButtonDisplayMode = .default
        
        if let navigationBar = self.navigationController?.navigationBar {
            
            navigationBar.tintColor = .black
            
            let titleLabel = MiniLibraryLabel(size: 16)
            titleLabel.text = "メンバー"
            navigationItem.titleView = titleLabel
            navigationBar.shadowImage = UIImage()
            navigationBar.backgroundColor = .white
            navigationBar.barTintColor = .white
            
            navigationItem.title = ""
            rightBarButton = UIBarButtonItem(title: "退会", style: .plain, target: nil, action: nil)
            navigationItem.rightBarButtonItem = rightBarButton

        }
    }
    
}
