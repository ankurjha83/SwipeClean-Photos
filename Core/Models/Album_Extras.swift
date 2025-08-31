import Photos

extension Album {
    /// Localized album title (falls back to "Album").
    var title: String {
        collection.localizedTitle ?? "Album"
    }

    /// Number of assets in this album.
    var count: Int {
        PHAsset.fetchAssets(in: collection, options: nil).count
    }
}
