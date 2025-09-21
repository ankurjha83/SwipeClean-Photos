import UIKit

public protocol ImageLoading: AnyObject {
    @MainActor func thumbnail(for asset: PhotoAsset, targetSize: CGSize) async -> UIImage?
    @MainActor func startPrefetch(assets: [PhotoAsset], targetSize: CGSize)
    @MainActor func stopPrefetch(assets: [PhotoAsset], targetSize: CGSize)
    @MainActor func clearCache()
}
