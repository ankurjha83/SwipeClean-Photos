import UIKit
import Photos

/// Loads thumbnails from PhotoKit with PHCachingImageManager + simple prefetch.
final class ImageLoaderService: ImageLoading {

    static let shared = ImageLoaderService()

    private let manager = PHCachingImageManager()
    private let queue   = DispatchQueue(label: "ImageLoaderService.queue")

    private let requestOptions: PHImageRequestOptions = {
        let o = PHImageRequestOptions()
        o.isNetworkAccessAllowed = true
        o.deliveryMode = .opportunistic
        o.resizeMode = .fast
        return o
    }()

    // MARK: - ImageLoading

    func thumbnail(for asset: PhotoAsset, targetSize: CGSize) async -> UIImage? {
        await withCheckedContinuation { cont in
            queue.async { [manager, requestOptions] in
                manager.requestImage(
                    for: asset.phAsset,
                    targetSize: targetSize,
                    contentMode: .aspectFill,
                    options: requestOptions
                ) { image, _ in
                    cont.resume(returning: image)
                }
            }
        }
    }

    func startPrefetch(assets: [PhotoAsset], targetSize: CGSize) {
        let phAssets = assets.map(\.phAsset)
        queue.async { [manager, requestOptions] in
            manager.startCachingImages(
                for: phAssets,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: requestOptions
            )
        }
    }

    func stopPrefetch(assets: [PhotoAsset], targetSize: CGSize) {
        let phAssets = assets.map(\.phAsset)
        queue.async { [manager, requestOptions] in
            manager.stopCachingImages(
                for: phAssets,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: requestOptions
            )
        }
    }
}
