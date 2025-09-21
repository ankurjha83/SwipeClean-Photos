import Photos

extension Album {
    var title: String { collection.localizedTitle ?? "Album" }
    var count: Int { PHAsset.fetchAssets(in: collection, options: nil).count }
}
