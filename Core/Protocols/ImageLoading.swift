import UIKit
import CoreGraphics

public protocol ImageLoading: AnyObject {
    func thumbnail(for asset: PhotoAsset, targetSize: CGSize) async -> UIImage?
    func startPrefetch(assets: [PhotoAsset], targetSize: CGSize)
    func stopPrefetch(assets: [PhotoAsset], targetSize: CGSize)
}
