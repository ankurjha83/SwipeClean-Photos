import UIKit
@preconcurrency import Photos

/// Loads thumbnails from PhotoKit with PHCachingImageManager + simple prefetch.
/// Kept on the main actor because PhotoKit image APIs are main-thread oriented.
@MainActor
final class ImageLoaderService: ImageLoading {

    static let shared = ImageLoaderService()
    private init() {}

    private let manager = PHCachingImageManager()

    private let requestOptions: PHImageRequestOptions = {
        let o = PHImageRequestOptions()
        o.isSynchronous = false
        o.deliveryMode = .opportunistic            // may call back multiple times
        o.resizeMode = .fast
        o.isNetworkAccessAllowed = true
        return o
    }()

    // MARK: - ImageLoading

    func thumbnail(for asset: PhotoAsset, targetSize: CGSize) async -> UIImage? {
        await withCheckedContinuation { (cont: CheckedContinuation<UIImage?, Never>) in
            var didResume = false

            _ = manager.requestImage(
                for: asset.phAsset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: requestOptions
            ) { image, info in

                // Result metadata flags
                let cancelled = (info?[PHImageCancelledKey] as? NSNumber)?.boolValue ?? false
                let error     = (info?[PHImageErrorKey] as? NSError)
                let degraded  = (info?[PHImageResultIsDegradedKey] as? NSNumber)?.boolValue ?? false

                // If cancelled or errored, finish once with nil
                if cancelled || error != nil {
                    if !didResume { didResume = true; cont.resume(returning: nil) }
                    return
                }

                // We only want the *final* high-quality image.
                guard let image = image, degraded == false else { return }

                if !didResume {
                    didResume = true
                    cont.resume(returning: image)
                }
            }
        }
    }

    func startPrefetch(assets: [PhotoAsset], targetSize: CGSize) {
        let phAssets = assets.map(\.phAsset)
        let o = PHImageRequestOptions()
        o.isSynchronous = false
        o.deliveryMode = .fastFormat
        o.resizeMode = .fast
        o.isNetworkAccessAllowed = true

        manager.startCachingImages(
            for: phAssets,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: o
        )
    }

    func stopPrefetch(assets: [PhotoAsset], targetSize: CGSize) {
        let phAssets = assets.map(\.phAsset)
        manager.stopCachingImages(
            for: phAssets,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: requestOptions
        )
    }

    func clearCache() {
        manager.stopCachingImagesForAllAssets()
    }
}
