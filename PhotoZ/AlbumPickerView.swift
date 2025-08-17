import SwiftUI
import Photos

struct AlbumPickerView: View {
    @ObservedObject var lib: PhotoLibrary
    @Environment(\.dismiss) private var dismiss

    @State private var smartAlbums: [AlbumRow] = []
    @State private var userAlbums: [AlbumRow] = []

    var body: some View {
        NavigationStack {
            List {
                if !smartAlbums.isEmpty {
                    Section("Smart Albums") {
                        ForEach(smartAlbums) { row in
                            Button {
                                lib.loadAlbum(withIdentifier: row.id)
                                dismiss()
                            } label: {
                                AlbumRowView(row: row)
                            }
                        }
                    }
                }
                if !userAlbums.isEmpty {
                    Section("My Albums") {
                        ForEach(userAlbums) { row in
                            Button {
                                lib.loadAlbum(withIdentifier: row.id)
                                dismiss()
                            } label: {
                                AlbumRowView(row: row)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Choose Album")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task { loadAlbums() }
        }
    }

    // MARK: - Loaders
    private func loadAlbums() {
        // Count only images (we’re photo-only for now)
        let imgOnly = PHFetchOptions()
        imgOnly.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)

        // Smart albums to show
        let wantedSmart: [PHAssetCollectionSubtype] = [
            .smartAlbumUserLibrary,
            .smartAlbumFavorites,
            .smartAlbumSelfPortraits,
            .smartAlbumScreenshots,
            .smartAlbumBursts,
            .smartAlbumRecentlyAdded,
            .smartAlbumPanoramas
        ]
        var smarts: [AlbumRow] = []
        for subtype in wantedSmart {
            let r = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: subtype, options: nil)
            r.enumerateObjects { c, _, _ in
                let count = PHAsset.fetchAssets(in: c, options: imgOnly).count
                guard count > 0 else { return }
                smarts.append(AlbumRow(id: c.localIdentifier,
                                       title: c.localizedTitle ?? "Untitled",
                                       count: count,
                                       collection: c))
            }
        }

        // User albums
        var mine: [AlbumRow] = []
        let user = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
        user.enumerateObjects { c, _, _ in
            let count = PHAsset.fetchAssets(in: c, options: imgOnly).count
            guard count > 0 else { return }
            mine.append(AlbumRow(id: c.localIdentifier,
                                 title: c.localizedTitle ?? "Untitled",
                                 count: count,
                                 collection: c))
        }

        mine.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        smartAlbums = smarts
        userAlbums = mine
    }
}

// MARK: - Row types

struct AlbumRow: Identifiable {
    let id: String
    let title: String
    let count: Int
    let collection: PHAssetCollection
}

struct AlbumRowView: View {
    let row: AlbumRow
    var body: some View {
        HStack(spacing: 12) {
            AlbumThumbView(collection: row.collection)
            Text(row.title)
                .lineLimit(1)
            Spacer()
            Text("\(row.count)")
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }
}

struct AlbumThumbView: View {
    let collection: PHAssetCollection
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.15))
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .frame(width: 48, height: 48)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onAppear(perform: load)
    }

    private func load() {
        let opts = PHFetchOptions()
        opts.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        opts.fetchLimit = 1
        let assets = PHAsset.fetchAssets(in: collection, options: opts)
        guard let asset = assets.firstObject else { return }

        let requestOpts = PHImageRequestOptions()
        requestOpts.deliveryMode = .fastFormat
        requestOpts.resizeMode = .fast
        requestOpts.isNetworkAccessAllowed = true

        let target = CGSize(width: 96, height: 96) // small, crisp thumbnail
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: target,
            contentMode: .aspectFill,
            options: requestOpts
        ) { img, _ in
            self.image = img
        }
    }
}
