//
//  PhotoLibraryService.swift
//  PhotoZ
//

import Foundation
import Photos
import UIKit

// MARK: - Model helpers (assumes you already have these types)
// enum PhotoAuthStatus { case notDetermined, authorized, limited, denied }
// struct PhotoAsset { let id: String; let phAsset: PHAsset
//     init(_ ph: PHAsset) { self.id = ph.localIdentifier; self.phAsset = ph }
// }
// struct Album: Identifiable, Hashable { let id: String; let collection: PHAssetCollection
//     init(_ c: PHAssetCollection) { self.collection = c; self.id = c.localIdentifier }
// }

// MARK: - Service

@MainActor
final class PhotoLibraryService: PhotoLibraryProtocol {
    static let shared = PhotoLibraryService()   // ← add this
    private init() {}                           // ← and this

    // MARK: Auth

    var authorizationStatus: PhotoAuthStatus {
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
        case .authorized: return .authorized
        case .limited:    return .limited
        case .denied:     return .denied
        case .notDetermined: return .notDetermined
        default:          return .denied
        }
    }

    @discardableResult
    func requestAuthorization() async -> PhotoAuthStatus {
        await withCheckedContinuation { cont in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { _ in
                let mapped = self.authorizationStatus
                cont.resume(returning: mapped)
            }
        }
    }

    // MARK: Fetch photos

    func fetchAllPhotos(includeFavorites: Bool) -> [PhotoAsset] {
        let opts = PHFetchOptions()
        opts.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        if !includeFavorites {
            opts.predicate = NSPredicate(format: "isFavorite == NO")
        }
        let result = PHAsset.fetchAssets(with: .image, options: opts)
        var out: [PhotoAsset] = []
        out.reserveCapacity(result.count)
        result.enumerateObjects { ph, _, _ in out.append(PhotoAsset(ph)) }
        return out
    }

    func fetch(in album: Album, includeFavorites: Bool) -> [PhotoAsset] {
        let opts = PHFetchOptions()
        opts.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        if !includeFavorites {
            opts.predicate = NSPredicate(format: "isFavorite == NO")
        }
        let result = PHAsset.fetchAssets(in: album.collection, options: opts)
        var out: [PhotoAsset] = []
        out.reserveCapacity(result.count)
        result.enumerateObjects { ph, _, _ in out.append(PhotoAsset(ph)) }
        return out
    }

    // MARK: Look up by IDs (order preserved)

    func assets(withIDs ids: [String]) -> [PhotoAsset] {
        guard !ids.isEmpty else { return [] }
        let result = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
        var wrapped: [PhotoAsset] = []
        wrapped.reserveCapacity(result.count)
        result.enumerateObjects { ph, _, _ in wrapped.append(PhotoAsset(ph)) }
        let map = Dictionary(uniqueKeysWithValues: wrapped.map { ($0.id, $0) })
        return ids.compactMap { map[$0] }
    }

    // MARK: Albums (SINGLE implementation — keep only this one)

    func fetchAlbums() -> [Album] {
        var out: [Album] = []

        // 1) User Library (“Recents”)
        let userLibrary = PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil
        )
        userLibrary.enumerateObjects { coll, _, _ in out.append(Album(coll)) }

        // 2) Favorites (optional)
        let favorites = PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum, subtype: .smartAlbumFavorites, options: nil
        )
        favorites.enumerateObjects { coll, _, _ in out.append(Album(coll)) }

        // 3) User-created albums
        let userAlbums = PHAssetCollection.fetchAssetCollections(
            with: .album, subtype: .albumRegular, options: nil
        )
        userAlbums.enumerateObjects { coll, _, _ in out.append(Album(coll)) }

        // De-dup by identifier (defensive)
        var seen = Set<String>()
        out = out.filter { a in
            if seen.contains(a.id) { return false }
            seen.insert(a.id)
            return true
        }

        // Keep first two (User Library, Favorites), then sort the rest by title
        if out.count > 2 {
            let head = Array(out.prefix(2))
            let tail = out.dropFirst(2).sorted {
                ($0.collection.localizedTitle ?? "") < ($1.collection.localizedTitle ?? "")
            }
            return head + tail
        } else {
            return out
        }
    }
}
