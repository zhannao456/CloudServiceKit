//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CloudServiceKit
import UIKit

class DriveBrowserViewController: UIViewController {

    enum Section {
        case main
    }

    private var collectionView: UICollectionView!

    private var dataSource: UICollectionViewDiffableDataSource<Section, CloudItem>!

    let provider: CloudServiceProvider

    let directory: CloudItem

    init(provider: CloudServiceProvider, directory: CloudItem) {
        self.provider = provider
        self.directory = directory
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = directory.name
        setupCollectionView()
        setupDataSource()
        applySnapshot()
    }
}

// MARK: - Setup

extension DriveBrowserViewController {

    private func setupCollectionView() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        view.addSubview(collectionView)
    }

    private func createLayout() -> UICollectionViewLayout {
        let configuration = UICollectionLayoutListConfiguration(appearance: .plain)
        return UICollectionViewCompositionalLayout.list(using: configuration)
    }

    private func setupDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, CloudItem> { cell, _, item in
            var content = cell.defaultContentConfiguration()
            content.image = item.isDirectory ? UIImage(named: "folder_32x32_") : UIImage(named: "file_32x32_")
            content.text = item.name
            cell.contentConfiguration = content
        }
        dataSource = UICollectionViewDiffableDataSource<Section, CloudItem>(
            collectionView: collectionView,
            cellProvider: { collectionView, indexPath, item in
                collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
            }
        )
    }

    private func applySnapshot() {
        provider.contentsOfDirectory(directory) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .success(items):
                var snapshot = NSDiffableDataSourceSnapshot<Section, CloudItem>()
                snapshot.appendSections([.main])
                snapshot.appendItems(items)
                self.dataSource.apply(snapshot, animatingDifferences: false)
            case let .failure(error):
                print(error)
            }
        }
    }
}

// MARK: - UICollectionViewDelegate

extension DriveBrowserViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else {
            return
        }
        if item.isDirectory {
            let vc = DriveBrowserViewController(provider: provider, directory: item)
            navigationController?.pushViewController(vc, animated: true)
        } else {
            print("Do with files")
        }
    }
}

// MARK: - CloudDriveKit

extension DriveBrowserViewController {

    // You can test more function, eg: add trailing context
    func removeItem(_ item: CloudItem) {
        provider.removeItem(item) { response in
            switch response.result {
            case .success:
                print("Remove success")
            case let .failure(error):
                print("Remove failed:\(error.localizedDescription)")
            }
        }
    }
}
