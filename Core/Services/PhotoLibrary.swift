import Foundation
import Photos
import UIKit
import PhotosUI

@MainActor
final class PhotoLibrary: ObservableObject {

    // MARK: Source of the current stack
    enum Source: Equatable {
        case all
        case later
        case album(PHAssetCollection)

        static func == (lhs: Source, rhs: Source) -> Bool {
            switch (lhs, rhs) {
            case (.all, .all), (.later, .later): return true
            case let (.album(a), .album(b)): return a.localIdentifier == b.localIdentifier
            default: return false
            }
        }
    }

    // One common "last action" for global Undo
    enum LastAction {
        case kept(PHAsset)
        case favorited(PHAsset, touchedLaterStore: Bool)
        case markedDelete(PHAsset, touchedLaterStore: Bool)
        case later(PHAsset, addedToLater: Bool)
    }

    @Published var stack: [PHAsset] = []
    @Published var authStatus: PHAuthorizationStatus = .notDetermined

    @Published var source: Source = .all
    @Published var pendingDeleteIDs: Set<String> = []
    @Published var lastCommittedDeleteCount: Int = 0

    @Published var lastAction: LastAction?   // <— for the common Undo

    private let cacheMgr = PHCachingImageManager()

    // MARK: - Auth
    func requestAccessAndLoad() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            Task { @MainActor in
                self?.authStatus = status
                guard status == .authorized || status == .limited else { return }
                self?.loadAll()
            }
        }
    }

    // MARK: - Loads
    func loadAll(limit: Int = 500) {
        source = .all
        let opts = PHFetchOptions()
        opts.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let result = PHAsset.fetchAssets(with: .image, options: opts)

        var assets: [PHAsset] = []
        let count = min(result.count, limit)
        if count > 0 {
            result.enumerateObjects { asset, idx, stop in
                if idx < count { assets.append(asset) } else { stop.pointee = true }
            }
        }
        stack = assets
        prefetchNext(12)
    }

    func loadLater() {
        source = .later
        let ids = Array(LaterStore.load())
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
        var list: [PHAsset] = []
        assets.enumerateObjects { a, _, _ in list.append(a) }
        stack = list.sorted { ($0.creationDate ?? .distantPast) > ($1.creationDate ?? .distantPast) }
        prefetchNext(12)
    }

    func loadAlbum(named name: String) {
        let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
        var found: PHAssetCollection?
        collections.enumerateObjects { coll, _, stop in
            if coll.localizedTitle == name { found = coll; stop.pointee = true }
        }
        if let c = found { load(from: c) }
    }

    func loadAlbum(withIdentifier id: String) {
        let collections = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [id], options: nil)
        if let c = collections.firstObject { load(from: c) }
    }

    private func load(from collection: PHAssetCollection) {
        source = .album(collection)
        let opts = PHFetchOptions()
        opts.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let result = PHAsset.fetchAssets(in: collection, options: opts)
        var list: [PHAsset] = []
        result.enumerateObjects { a, _, _ in list.append(a) }
        stack = list
        prefetchNext(12)
    }

    // MARK: - Images & Prefetch
    func prefetchNext(_ n: Int) {
        let next = Array(stack.prefix(n))
        cacheMgr.startCachingImages(
            for: next,
            targetSize: CGSize(width: 1200, height: 1600),
            contentMode: .aspectFill,
            options: nil
        )
    }

    func requestThumb(for asset: PHAsset,
                      target: CGSize = CGSize(width: 900, height: 1200),
                      completion: @escaping (UIImage?) -> Void) {
        let opts = PHImageRequestOptions()
        opts.deliveryMode = .opportunistic
        opts.isNetworkAccessAllowed = false
        cacheMgr.requestImage(for: asset,
                              targetSize: target,
                              contentMode: .aspectFill,
                              options: opts) { img, _ in
            completion(img)
        }
    }

    func requestFullImage(for asset: PHAsset, completion: @escaping (UIImage?) -> Void) {
        let opts = PHImageRequestOptions()
        opts.deliveryMode = .highQualityFormat
        opts.isNetworkAccessAllowed = true
        let target = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
        cacheMgr.requestImage(for: asset, targetSize: target, contentMode: .aspectFit, options: opts) { img, _ in
            completion(img)
        }
    }

    func requestLivePhoto(for asset: PHAsset, completion: @escaping (PHLivePhoto?) -> Void) {
        let opts = PHLivePhotoRequestOptions()
        opts.deliveryMode = .highQualityFormat
        opts.isNetworkAccessAllowed = true
        cacheMgr.requestLivePhoto(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: opts) { live, _ in
            completion(live)
        }
    }

    func checkCloudStatus(for asset: PHAsset, completion: @escaping (Bool) -> Void) {
        let opts = PHImageRequestOptions()
        opts.isNetworkAccessAllowed = false
        opts.deliveryMode = .fastFormat
        cacheMgr.requestImageDataAndOrientation(for: asset, options: opts) { _, _, _, info in
            let inCloud = (info?[PHImageResultIsInCloudKey] as? NSNumber)?.boolValue ?? false
            completion(inCloud)
        }
    }

    private func popTop() {
        if !stack.isEmpty { _ = stack.removeFirst() }
        prefetchNext(12)
    }

    // MARK: - Actions (Keep/Favorite/Delete/Later)
    func keepTop() {
        guard let asset = stack.first else { return }
        lastAction = .kept(asset)
        popTop()
    }

    func favoriteTop() {
        guard let asset = stack.first else { return }
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest(for: asset).isFavorite = true
        }) { [weak self] _, _ in
            Task { @MainActor in
                let touchedLater = (self?.source == .later)
                if touchedLater { LaterStore.remove(asset.localIdentifier) }
                self?.lastAction = .favorited(asset, touchedLaterStore: touchedLater)
                self?.popTop()
            }
        }
    }

    func markDeleteTop() {
        guard let asset = stack.first else { return }
        pendingDeleteIDs.insert(asset.localIdentifier)
        let touchedLater = (source == .later)
        if touchedLater { LaterStore.remove(asset.localIdentifier) }
        lastAction = .markedDelete(asset, touchedLaterStore: touchedLater)
        popTop()
    }

    func commitDeletes() {
        let ids = Array(pendingDeleteIDs)
        guard !ids.isEmpty else { return }
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
        let count = assets.count
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(assets)
        }) { [weak self] _, _ in
            Task { @MainActor in
                self?.lastCommittedDeleteCount = count
                self?.pendingDeleteIDs.removeAll()
            }
        }
    }

    func decideLaterTop() {
        guard let asset = stack.first else { return }
        let added = (source == .all)
        if added { LaterStore.add(asset.localIdentifier) }
        lastAction = .later(asset, addedToLater: added)
        popTop()
    }

    // MARK: - Common Undo
    func undoLast() {
        guard let action = lastAction else { return }
        switch action {
        case .kept(let asset):
            stack.insert(asset, at: 0)

        case .favorited(let asset, let touchedLater):
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest(for: asset).isFavorite = false
            }) { [weak self] _, _ in
                Task { @MainActor in
                    if touchedLater { LaterStore.add(asset.localIdentifier) }
                }
            }
            stack.insert(asset, at: 0)

        case .markedDelete(let asset, let touchedLater):
            pendingDeleteIDs.remove(asset.localIdentifier)
            if touchedLater { LaterStore.add(asset.localIdentifier) }
            stack.insert(asset, at: 0)

        case .later(let asset, let addedToLater):
            if addedToLater { LaterStore.remove(asset.localIdentifier) }
            stack.insert(asset, at: 0)
        }
        lastAction = nil
        prefetchNext(12)
    }

    // MARK: - Limited Library
    func presentLimitedLibraryEditor(from vc: UIViewController) {
        PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: vc)
    }
}
