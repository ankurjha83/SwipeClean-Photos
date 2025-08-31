//
//  PhotoLibraryProtocol.swift
//  PhotoZ
//
//  Created by Swati Pareek on 17/08/25.
//


import Photos

extension PhotoLibraryService: PhotoLibraryProtocol {
    public var authorizationStatus: PhotoAuthStatus {
        PhotoAuthStatus(photoKitRaw: PHPhotoLibrary.authorizationStatus(for: .readWrite).rawValue)
    }

    public func requestAuthorization() async -> PhotoAuthStatus {
        await withCheckedContinuation { cont in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                cont.resume(returning: PhotoAuthStatus(photoKitRaw: status.rawValue))
            }
        }
    }

    public func fetchAllPhotos(includeFavorites: Bool) -> [PhotoAsset] {
        let opts = PHFetchOptions()
        opts.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        if !includeFavorites { opts.predicate = NSPredicate(format: "isFavorite == NO") }
        let result = PHAsset.fetchAssets(with: .image, options: opts)
        var out: [PhotoAsset] = []
        out.reserveCapacity(result.count)
        result.enumerateObjects { a,_,_ in out.append(PhotoAsset(a)) }
        return out
    }

    public func fetch(in album: Album, includeFavorites: Bool) -> [PhotoAsset] {
        let opts = PHFetchOptions()
        opts.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        if !includeFavorites { opts.predicate = NSPredicate(format: "isFavorite == NO") }
        let result = PHAsset.fetchAssets(in: album.collection, options: opts)
        var out: [PhotoAsset] = []
        out.reserveCapacity(result.count)
        result.enumerateObjects { a,_,_ in out.append(PhotoAsset(a)) }
        return out
    }

    public func delete(localIDs: [String]) async throws {
        try await withCheckedThrowingContinuation { cont in
            let toDelete = PHAsset.fetchAssets(withLocalIdentifiers: localIDs, options: nil)
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets(toDelete)
            }, completionHandler: { success, error in
                if let error { cont.resume(throwing: error) }
                else if success { cont.resume() }
                else { cont.resume(throwing: NSError(domain: "PhotoZ", code: -1, userInfo: [NSLocalizedDescriptionKey:"Unknown delete failure"])) }
            })
        }
    }
}
