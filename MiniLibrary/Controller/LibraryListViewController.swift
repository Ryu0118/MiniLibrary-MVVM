//
//  ViewController.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/15.
//

import Firebase
import FirebaseAuth
import FirebaseFirestore
import RxSwift
import RxDataSources
import SnapKit

enum LibraryListSection {
    case library
}

enum LibraryListItem {
    case library(library: Library)
}

typealias LibraryListSectionModel = SectionModel<LibraryListSection, LibraryListItem>

class LibraryListViewController: UIViewController, RequireLogin {
    
    var rightBarItem: UIBarButtonItem!
    var leftBarLabel: MiniLibraryLabel!
    var titleLabel: MiniLibraryLabel!
    var collectionView: UICollectionView!
    var entranceVC: LibraryEntranceViewController!
    
    private let disposeBag = DisposeBag()
    private var viewModel = LibraryListViewModel()
    private lazy var dataSource = RxCollectionViewSectionedReloadDataSource<LibraryListSectionModel>(configureCell: configureCell)
    private lazy var configureCell: RxCollectionViewSectionedReloadDataSource<LibraryListSectionModel>.ConfigureCell = { [weak self] (_, tableView, indexPath, item) in
        print(item, indexPath)
        guard let self = self else { return UICollectionViewCell() }
        switch item {
        case .library(let library):
            return self.librarycell(indexPath: indexPath, library: library)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = .white
        
        setupNavigationBar()
        setName()
        setupCollectionView()
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if leftBarLabel.isHidden {
            leftBarLabel.isHidden = false
            titleLabel?.isHidden = true
        }
    }
    
}

//private methods
extension LibraryListViewController {
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .appBackgroundColor
        collectionView.contentInset.top = 20
        
        collectionView.register(LibraryListCell.self, forCellWithReuseIdentifier: "LibraryListCell")
        collectionView.rx.setDelegate(self).disposed(by: disposeBag)
        collectionView.rx.itemSelected
            .map { [weak self] indexPath -> LibraryListItem? in
                return self?.dataSource[indexPath]
            }
            .subscribe { [weak self] item in
                guard let item = item.element, let item = item else { return }
                switch item {
                case .library(let library):
                    let libraryVC = LibraryViewController(library: library)
                    self?.navigationController?.pushViewController(libraryVC, animated: true)
                    self?.leftBarLabel.isHidden = true
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
    
    private func bind() {
        viewModel.outputs.items
            .bind(to:collectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        viewModel.updateItems()
    }
    
    private func setName() {
        getUserName()
            .subscribe { name in
                if let name = name.element {
                    print(name)
                    FirebaseUtil.userName = name
                }
            }
            .disposed(by: disposeBag)
        
        getColorCode()
            .subscribe { colorCode in
                if let code = colorCode.element {
                    FirebaseUtil.colorCode = code
                }
            }
            .disposed(by: disposeBag)
    }
    
    private func librarycell(indexPath: IndexPath, library: Library) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LibraryListCell", for: indexPath) as? LibraryListCell {
            cell.update(library: library)
            return cell
        }
        return UICollectionViewCell()
    }
    
    private func setupNavigationBar() {
        
        if let navigationBar = self.navigationController?.navigationBar {
            
            leftBarLabel = MiniLibraryLabel(size: 25)
            leftBarLabel.text = "MiniLibrary"
            navigationBar.addSubview(leftBarLabel)
            leftBarLabel.snp.makeConstraints {
                $0.left.equalToSuperview().offset(15)
                $0.centerY.equalToSuperview()
            }
            rightBarItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addLibraryButtonTapped))
            rightBarItem.tintColor = .black
            navigationBar.shadowImage = UIImage()
            navigationBar.backgroundColor = .white
            navigationBar.tintColor = .white
            navigationBar.barTintColor = .white
            navigationItem.title = ""
            navigationItem.rightBarButtonItem = self.rightBarItem
            
        }
    }
    
    @objc private func addLibraryButtonTapped() {
        if let navigationBar = self.navigationController?.navigationBar {
            
            leftBarLabel.removeFromSuperview()
            titleLabel = MiniLibraryLabel(size: 16)
            titleLabel.text = "図書館を追加"
            navigationItem.titleView = titleLabel
            
            rightBarItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.close, target: self, action: #selector(exitButtonPressed))
            rightBarItem.tintColor = .black
            navigationItem.rightBarButtonItem = rightBarItem
            
            navigationBar.shadowImage = UIImage()
            navigationBar.backgroundColor = .white
            navigationBar.tintColor = .white
            navigationBar.barTintColor = .white
            
            entranceVC = LibraryEntranceViewController()
            view.addSubview(entranceVC.view)
            entranceVC.willMove(toParent: self)
            entranceVC.view.snp.makeConstraints {
                $0.bottom.left.right.equalToSuperview()
                $0.top.equalTo(view.safeAreaLayoutGuide)
            }
            
            entranceVC.viewModel.completionSubject
                .asObservable()
                .asDriver(onErrorJustReturn: ())
                .drive {[weak self] _ in
                    self?.exitButtonPressed()
                }
                .disposed(by: disposeBag)
            
        }
    }
    
    @objc private func exitButtonPressed() {
        titleLabel.removeFromSuperview()
        setupNavigationBar()
        entranceVC.view.removeFromSuperview()
        self.didMove(toParent: entranceVC)
    }
    
}

extension LibraryListViewController : UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 15
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width - (LibraryListCell.cellMargin * 2)
        return CGSize(width: width, height: LibraryListCell.cellHeight)
    }
    
}


//        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//            let vc = LoginViewController()
//            vc.modalPresentationStyle = .fullScreen
//            vc.modalTransitionStyle = .coverVertical
//            self.present(vc, animated: true)
//        }
