//
//  LibraryViewController.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/17.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import SnapKit
import BarcodeScanner
import KRProgressHUD


enum LibrarySection {
    case renting
    case allbooks
}

enum LibraryItem {
    case renting(bookinfo: BookInfo)
    case allbooks(bookinfo: BookInfo)
}

typealias LibrarySectionModel = SectionModel<LibrarySection, LibraryItem>

class LibraryViewController : UIViewController {
    
    let library: Library
    var profileBarButtonItem: UIBarButtonItem!
    var bellBarButtonItem: UIBarButtonItem!
    var addBookButtonItem: UIBarButtonItem!
    var backButtonItem: UIBarButtonItem!
    var collectionView: UICollectionView!
    
    private let viewModel = LibraryViewModel()
    private let disposeBag = DisposeBag()
    
    private lazy var dataSource = RxCollectionViewSectionedReloadDataSource<LibrarySectionModel>(configureCell: configureCell, configureSupplementaryView: titleForHeaderInSection)
    
    private lazy var configureCell: RxCollectionViewSectionedReloadDataSource<LibrarySectionModel>.ConfigureCell = {[weak self] _, tableView, indexPath, item in
        guard let self = self else { return UICollectionViewCell() }
        switch item {
        case .renting(let bookinfo):
            return self.renting(indexPath: indexPath, bookinfo: bookinfo)
        case .allbooks(let bookinfo):
            return self.allbooks(indexPath: indexPath, bookinfo: bookinfo)
        }
    }
    private lazy var titleForHeaderInSection: RxCollectionViewSectionedReloadDataSource<LibrarySectionModel>.ConfigureSupplementaryView = { [weak self] (dataSource, collectionView, kind, indexPath) in
        guard let self = self else { return UICollectionReusableView() }
        return self.headerCell(indexPath: indexPath, kind: kind)
    }
    
    init(library: Library) {
        self.library = library
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationbar()
        bind()
        setupCollectionView()
        view.backgroundColor = .white
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //groupedButtonView.removeFromSuperview()
    }
    
}

extension LibraryViewController {
    
    private enum SectionLayoutKind: Int, CaseIterable {
        case renting
        case allbooks
        
        func scrollingBehavior() -> UICollectionLayoutSectionOrthogonalScrollingBehavior {
            switch self {
            case .renting:
                return .continuous
            default:
                return .none
            }
        }
        
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let sectionProvider = { (sectionIndex: Int,
            layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            guard let sectionKind = SectionLayoutKind(rawValue: sectionIndex) else { fatalError() }
            
            switch sectionKind {
            case .renting:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                      heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupWidth = layoutEnvironment.container.effectiveContentSize.width - 15 * 2 - 5
                let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(groupWidth),
                                                       heightDimension: .absolute(150))
                let group: NSCollectionLayoutGroup
                group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 2)
                group.interItemSpacing = NSCollectionLayoutSpacing.fixed(10)
                
                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = sectionKind.scrollingBehavior()
                section.interGroupSpacing = 10
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 15)
                
                let sectionHeaderSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                               heightDimension: .estimated(44))
                let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: sectionHeaderSize, elementKind: "header", alignment: .top)
                section.boundarySupplementaryItems = [sectionHeader]
                return section
                
            case .allbooks:
                let itemCount = 4
                let lineCount = itemCount - 1
                let itemSpacing = CGFloat(8)
                let itemLength = (layoutEnvironment.container.effectiveContentSize.width - (itemSpacing * CGFloat(lineCount))) * 0.75 / CGFloat(itemCount)

                let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .absolute(itemLength),heightDimension: .absolute(itemLength * 28/13)))

                let items = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),heightDimension: .fractionalHeight(1.0)),subitem: item,count: itemCount)
                items.interItemSpacing = .fixed(itemSpacing)
                
                let groups = NSCollectionLayoutGroup.vertical(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),heightDimension: .absolute(itemLength)),subitems: [items])

                let section = NSCollectionLayoutSection(group: groups)
                let leadingInset = (layoutEnvironment.container.effectiveContentSize.width - itemLength) / 2
                section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: leadingInset, bottom: 0, trailing: leadingInset)

                section.interGroupSpacing = itemSpacing
                return section
            }

        }
        
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = 30

        let layout = UICollectionViewCompositionalLayout(sectionProvider: sectionProvider, configuration: config)
        return layout
        
    }
    
    
    private func setupCollectionView() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.backgroundColor = .appBackgroundColor
        collectionView.register(AllBooksCell.self, forCellWithReuseIdentifier: AllBooksCell.identifier)
        collectionView.register(RentingCell.self, forCellWithReuseIdentifier: RentingCell.identifier)
        collectionView.rx.setDelegate(self).disposed(by: disposeBag)
        collectionView.rx.itemSelected
            .map { [weak self] indexpath -> LibraryItem? in
                return self?.dataSource[indexpath]
            }
            .subscribe { [weak self] item in
                guard let item = item.element, let item = item else { return }
                
                switch item {
                case .renting(let bookinfo):
                    print(bookinfo)
                    break
                case .allbooks(let bookinfo):
                    print(bookinfo)
                    break
                }
            }
            .disposed(by: disposeBag)
        
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints {
            $0.top.left.right.equalTo(view.safeAreaLayoutGuide)
            $0.bottom.equalToSuperview()
        }
    }
    
    private func setupNavigationbar() {
        
        self.navigationItem.backButtonTitle = ""
        self.navigationItem.backButtonDisplayMode = .default
        
        if let navigationBar = self.navigationController?.navigationBar {
            
            navigationBar.tintColor = .black
            
            let titleLabel = MiniLibraryLabel(size: 16)
            titleLabel.text = library.library_name
            navigationItem.titleView = titleLabel
            navigationBar.shadowImage = UIImage()
            navigationBar.backgroundColor = .white
            navigationBar.barTintColor = .white
            
            bellBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "bell"), style: .plain, target: self, action: nil)
            
            profileBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "person", withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .regular, scale: .default)), style: .plain, target: self, action: nil)
            addBookButtonItem = UIBarButtonItem(systemItem: .add, menu: configureUIMenu())
            backButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"), style: .plain, target: self, action: #selector(goBack))
            navigationItem.title = ""
            navigationItem.leftBarButtonItems = [backButtonItem, bellBarButtonItem]
            navigationItem.rightBarButtonItems = [profileBarButtonItem ,addBookButtonItem]
            
        }
    }
    
    @objc private func goBack() {
        navigationController?.popViewController(animated: true)
    }
    
    private func configureUIMenu() -> UIMenu {
        var actions = [UIMenuElement]()
        actions.append(UIAction(title: "バーコードを読み取る", image: UIImage(systemName: "barcode"), state: .off , handler: {[weak self] _ in
            guard let self = self else { return }
            let barcodeScanner = BarcodeScannerViewController()
            barcodeScanner.codeDelegate = self
            barcodeScanner.errorDelegate = self
            barcodeScanner.dismissalDelegate = self
            barcodeScanner.headerViewController.titleLabel.text = "バーコードを読み取る"
            self.navigationController?.pushViewController(barcodeScanner, animated: true)
        }))
        actions.append(UIAction(title: "検索する", image: UIImage(systemName: "magnifyingglass"), state: .off , handler: { _ in
            
        }))
        return UIMenu(title: "", options: .displayInline, children: actions)
    }
    
    //MARK: bind
    private func bind() {
        bellBarButtonItem.rx.tap
            .asDriver()
            .drive { _ in
            print("leftButtonPressed")
        }
        .disposed(by: disposeBag)
        
        profileBarButtonItem.rx.tap
            .asDriver()
            .drive {[weak self] _ in
                guard let self = self else { return }
                let userListVC = UserListViewController(library: self.library)
                self.navigationController?.pushViewController(userListVC, animated: true)
            }
            .disposed(by: disposeBag)
        
        viewModel.outputs.metadataResponse
            .drive {[weak self] image, bookinfo in
                let alert = MiniLibraryAlertController(title: bookinfo.title, image: image)
                let cancel = MiniLibraryAlertAction(message: "キャンセル", option: .cancel, handler: nil)
                let add = MiniLibraryAlertAction(message: "追加", option: .normal, handler: {[weak self] in
                    guard let self = self else { return }
                    self.viewModel.inputs.addBookObserver.onNext((bookinfo, self.library))
                    alert.dismiss(animated: true)
                })
                alert.addActions([cancel, add])
                self?.present(alert, animated: true)
            }
            .disposed(by: disposeBag)
        
        viewModel.outputs.addBookResponse
            .subscribe(onNext: {[weak self] response in
                KRProgressHUD.dismiss()
                if response.isEmpty {
                    let alert = MiniLibraryAlertController(title: "追加しました", actions: [MiniLibraryAlertAction(message: "OK", option: .normal, handler: nil)])
                    self?.present(alert, animated: true)
                }else{
                    let alert = MiniLibraryAlertController(title: "失敗しました", message: response, actions: [MiniLibraryAlertAction(message: "OK", option: .normal, handler: nil)])
                    self?.present(alert, animated: true)
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func renting(indexPath: IndexPath, bookinfo: BookInfo) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LibraryListCell", for: indexPath) as? RentingCell {
            cell.update(bookinfo: bookinfo)
            return cell
        }
        return UICollectionViewCell()
    }
    
    private func allbooks(indexPath: IndexPath, bookinfo: BookInfo) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LibraryListCell", for: indexPath) as? AllBooksCell {
            cell.update(bookinfo: bookinfo)
            return cell
        }
        return UICollectionViewCell()
    }
    
    private func headerCell(indexPath: IndexPath, kind: String) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Section", for: indexPath)
        let titleLabel = MiniLibraryLabel(size: 25)
        titleLabel.text = indexPath.section == 0 ? "貸出中の本" : "全ての本"
        headerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.left.centerY.equalToSuperview()
        }
        return headerView
    }


    
}

//MARK: BarcodeScannerCodeDelegate
extension LibraryViewController : BarcodeScannerCodeDelegate, BarcodeScannerDismissalDelegate, BarcodeScannerErrorDelegate {
    
    func scanner(_ controller: BarcodeScannerViewController, didCaptureCode code: String, type: String) {
        RakutenBooksAPI.getBookInformation(isbn: code)
            .withUnretained(self)
            .subscribe(onNext: { viewController, bookinfo in
                viewController.viewModel.inputs.bookinfoObserver.onNext(bookinfo)
                controller.reset()
            }, onError: {error in
                controller.resetWithError(message: error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
    
    func scannerDidDismiss(_ controller: BarcodeScannerViewController) {
        controller.dismiss(animated: true)
    }
    
    func scanner(_ controller: BarcodeScannerViewController, didReceiveError error: Error) {
        let alert = MiniLibraryAlertController(title: "エラーが発生しました", actions: [MiniLibraryAlertAction(message: "OK", option: .normal, handler: nil)])
        present(alert, animated: true, completion: nil)
    }
    
}

//MARK: UICollectionViewDelegate
extension LibraryViewController : UICollectionViewDelegate {
    
}
