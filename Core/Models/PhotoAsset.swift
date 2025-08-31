import Photos

public struct PhotoAsset: Identifiable, Hashable {
    public let id: String               // PHAsset.localIdentifier
    public let phAsset: PHAsset
    public init(_ asset: PHAsset) {
        self.phAsset = asset
        self.id = asset.localIdentifier
    }
}
