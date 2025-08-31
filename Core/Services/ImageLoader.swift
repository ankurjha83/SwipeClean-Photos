import Foundation
import Photos
import PhotosUI
import UIKit

/// Centralized image loader with a small, memory-safe prefetch window.
/// High-quality thumbs, Swift-6 actor-isolated.
actor ImageLoader {
    static let shared = ImageLoader()

    // Configure these without touching `self` to avoid Swift 6 init warnings.
    private let cache: NSCache<NSString, UIImage> = {
        let c = NSCache<NSString, UIImage>()
        c.countLimit = 400
        c.totalCostLimit = 32 * 1024 * 1024 // ~32MB
        return c
    }()

    private let manager: PHCachingImageManager = {
        let m = PHCachingImageManager()
        m.allowsCachingHighQualityImages = false
        return m
    }()

    private var cachedIDs = Set<String>()                    // current prefetch window
    private var requestIDs: [String: PHImageRequestID] = [:] // in-flight by localID

    init() {}

    // MARK: - High-quality thumb

    /// Returns a high-quality image sized for `target` (no degraded frames).
    func thumb(for localID: String, target: CGSize) async -> UIImage? {
        if let cached = cache.object(forKey: localID as NSString) {
            return cached
        }

        let scale: CGFloat = await MainActor.run { UIScreen.main.scale }
        let px = CGSize(width: max(1, target.width * scale),
                        height: max(1, target.height * scale))

        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localID], options: nil)
        guard let asset = assets.firstObject else { return nil }

        // Ask for the final, exact-sized image only.
        let opts = PHImageRequestOptions()
        opts.isNetworkAccessAllowed = true
        opts.deliveryMode = .highQualityFormat
        opts.resizeMode = .exact

        return await withTaskCancellationHandler(operation: {
            await withCheckedContinuation { cont in
                let id = manager.requestImage(for: asset,
                                              targetSize: px,
                                              contentMode: .aspectFill,
                                              options: opts) { [weak self] image, info in
                    guard let self else { return }

                    if let cancelled = info?[PHImageCancelledKey] as? Bool, cancelled {
                        cont.resume(returning: nil); return
                    }

                    if let img = image {
                        let w = img.size.width * img.scale
                        let h = img.size.height * img.scale
                        self.cache.setObject(img,
                                             forKey: localID as NSString,
                                             cost: Int(w * h * 4)) // RGBA est.
                    }
                    cont.resume(returning: image)
                }
                requestIDs[localID] = id
            }
        }, onCancel: { [weak self] in
            Task { await self?.cancel(for: localID) }
        })
    }

    /// Cancel an in-flight thumbnail request
    func cancel(for localID: String) {
        if let id = requestIDs.removeValue(forKey: localID) {
            manager.cancelImageRequest(id)
        }
    }

    // MARK: - Windowed prefetch

    /// Cache the current top and next few assets; stop caching anything else.
    func prefetchWindow(top: String?, next: [String], target: CGSize) async {
        let scale: CGFloat = await MainActor.run { UIScreen.main.scale }
        // Prefetch slightly larger for crispness, but still memory-friendly.
        let px = CGSize(width: max(1, target.width * scale * 0.9),
                        height: max(1, target.height * scale * 0.9))

        let opts = PHImageRequestOptions()
        opts.deliveryMode = .opportunistic
        opts.resizeMode = .fast
        opts.isNetworkAccessAllowed = true

        let windowIDs = Set((top.map { [$0] } ?? []) + next)
        let toStart = windowIDs.subtracting(cachedIDs)
        let toStop  = cachedIDs.subtracting(windowIDs)

        if !toStart.isEmpty {
            let fr = PHAsset.fetchAssets(withLocalIdentifiers: Array(toStart), options: nil)
            var arr = [PHAsset](); arr.reserveCapacity(fr.count)
            for i in 0..<fr.count { arr.append(fr.object(at: i)) }
            manager.startCachingImages(for: arr, targetSize: px, contentMode: .aspectFill, options: opts)
            cachedIDs.formUnion(toStart)
        }

        if !toStop.isEmpty {
            let fr = PHAsset.fetchAssets(withLocalIdentifiers: Array(toStop), options: nil)
            var arr = [PHAsset](); arr.reserveCapacity(fr.count)
            for i in 0..<fr.count { arr.append(fr.object(at: i)) }
            manager.stopCachingImages(for: arr, targetSize: px, contentMode: .aspectFill, options: opts)
            cachedIDs.subtract(toStop)
        }
    }

    /// Stop caching everything we started in the current window.
    func clearAllCaching(target: CGSize) async {
        guard !cachedIDs.isEmpty else { return }
        let fr = PHAsset.fetchAssets(withLocalIdentifiers: Array(cachedIDs), options: nil)
        var arr = [PHAsset](); arr.reserveCapacity(fr.count)
        for i in 0..<fr.count { arr.append(fr.object(at: i)) }
        let scale: CGFloat = await MainActor.run { UIScreen.main.scale }
        let px = CGSize(width: max(1, target.width * scale),
                        height: max(1, target.height * scale))
        manager.stopCachingImages(for: arr, targetSize: px, contentMode: .aspectFill, options: nil)
        cachedIDs.removeAll()
    }

    // MARK: - Live Photo

    /// Load a live photo (if available). Returns the final (non-degraded) result.
    func livePhoto(for localID: String, target: CGSize) async -> PHLivePhoto? {
        let scale: CGFloat = await MainActor.run { UIScreen.main.scale }
        let px = CGSize(width: max(1, target.width * scale),
                        height: max(1, target.height * scale))

        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localID], options: nil)
        guard let asset = assets.firstObject else { return nil }

        let opts = PHLivePhotoRequestOptions()
        opts.isNetworkAccessAllowed = true
        opts.deliveryMode = .opportunistic

        return await withCheckedContinuation { cont in
            var didResume = false
            func finish(_ lp: PHLivePhoto?) { if !didResume { didResume = true; cont.resume(returning: lp) } }

            PHImageManager.default().requestLivePhoto(for: asset,
                                                      targetSize: px,
                                                      contentMode: .aspectFill,
                                                      options: opts) { live, info in
                if let cancelled = info?[PHImageCancelledKey] as? Bool, cancelled { finish(nil); return }
                let degraded = (info?[PHImageResultIsDegradedKey] as? Bool) == true
                if degraded { return }
                finish(live)
            }
        }
    }
}
