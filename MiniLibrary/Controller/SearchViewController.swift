//
//  SearchViewController.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/20.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import KRProgressHUD


class SearchViewController : UIViewController {
    
    var tableView: UITableView!
    var searchBar: UISearchBar!
    
    private let viewModel = SearchViewModel()
    private let disposeBag = DisposeBag()
    
    let libraryCode: String
    
    init(libraryCode: String) {
        self.libraryCode = libraryCode
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bind()
    }
    
}

extension SearchViewController {
    
    private func setupViews() {
        if let navigationBarFrame = navigationController?.navigationBar.frame {
            searchBar = UISearchBar(frame: navigationBarFrame)
            searchBar.placeholder = "検索するキーワードを入力"
            searchBar.barStyle = .default
            searchBar.tintColor = .gray
            searchBar.keyboardType = .default
            navigationItem.titleView = searchBar
            navigationItem.titleView?.frame = searchBar.frame
        }
        
        tableView = UITableView(frame: .zero, style: .plain)
        tableView.register(SearchResultCell.self, forCellReuseIdentifier: SearchResultCell.identifier)
        view.addSubview(tableView)
        
        tableView.snp.makeConstraints {
            $0.top.bottom.left.right.equalTo(view.safeAreaLayoutGuide)
        }
        
    }
    
    private func bind() {
        
        searchBar.rx.searchButtonClicked
            .withLatestFrom(searchBar.rx.text.orEmpty)
            .distinctUntilChanged()
            .do {[weak self] text in
                KRProgressHUD.show()
                self?.searchBar.resignFirstResponder()
            }
            .bind(to: viewModel.inputs.searchObserver)
            .disposed(by: disposeBag)
        
        
        searchBar.rx.text
            .orEmpty
            .bind(to: viewModel.inputs.textObserver)
            .disposed(by: disposeBag)
        
        viewModel.outputs.bookInformations
            .drive(tableView.rx.items(cellIdentifier: SearchResultCell.identifier, cellType: SearchResultCell.self)) { indexPath, bookinfo, cell in
                KRProgressHUD.dismiss()
                cell.setup(bookinfo: bookinfo)
            }
            .disposed(by: disposeBag)
        
        tableView.rx.itemSelected
            .withLatestFrom(viewModel.outputs.bookInformations) { indexPath, bookinfomations -> BookInfo in
                return bookinfomations[indexPath.row]
            }
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .subscribe(onNext: { strongSelf, bookinfo in
                let alert = strongSelf.presentBookDetailView(bookinfo: bookinfo, isPresentOwner: false)
                let cancel = MiniLibraryAlertAction(message: "キャンセル", option: .cancel, handler: nil)
                let add = MiniLibraryAlertAction(message: "追加", option: .normal, handler: {
                    strongSelf.viewModel.addBook(libraryCode: strongSelf.libraryCode, bookinfo: bookinfo)
                })
                alert.addActions([cancel, add])
                strongSelf.present(alert, animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
        
        viewModel.outputs.addBookResponse
            .asObservable()
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .subscribe(onNext: { strongSelf, response in
                if !response.isEmpty {
                    MiniLibraryAlertController.showErrorAlert(target: strongSelf, title: response)
                }
                else{
                    MiniLibraryAlertController.showErrorAlert(target: strongSelf, title: "追加しました")
                }
            })
            .disposed(by: disposeBag)
        
    }
    
    @discardableResult
    private func presentBookDetailView(bookinfo: BookInfo, customView: UIView? = nil, isPresentOwner: Bool = true) -> MiniLibraryAlertController {
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
    
}

class SearchResultCell : UITableViewCell {
    
    static let identifier = "SearchResultCell"
    var detailView: BookDetailView!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func setup(bookinfo: BookInfo) {
        subviews.forEach {
            $0.removeFromSuperview()
        }
        detailView = BookDetailView(bookinfo: bookinfo, isPresentOwner: false)
        addSubview(detailView)
        
        detailView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(ConstraintInsets(top: 3, left: 3, bottom: 3, right: 3))
        }
    }
    
}
