//
//  DeleteReviewView.swift
//  PhotoZ
//

import SwiftUI
import Photos

private struct ThumbnailCell: View {
    let asset: PHAsset
    let side: CGFloat
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let ui = image {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Color.secondary.opacity(0.12))
                    .overlay(ProgressView())
            }
        }
        .frame(width: side, height: side)
        .clipped()
        .cornerRadius(12)
        .task {
            // Ask Photos for a small, fast, network-allowed thumbnail
            let scale = UIScreen.main.scale
            let target = CGSize(width: side * scale, height: side * scale)
            let opts = PHImageRequestOptions()
            opts.isSynchronous = false
            opts.isNetworkAccessAllowed = true
            opts.deliveryMode = .opportunistic
            opts.resizeMode = .fast

            PHImageManager.default().requestImage(
                for: asset,
                targetSize: target,
                contentMode: .aspectFill,
                options: opts
            ) { img, _ in
                if let img { self.image = img }
            }
        }
    }
}

struct DeleteReviewView: View {
    @EnvironmentObject private var store: DecisionStore

    @State private var assets: [PHAsset] = []
    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 10)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(assets, id: \.localIdentifier) { asset in
                        ZStack(alignment: .topTrailing) {
                            ThumbnailCell(asset: asset, side: 110)

                            // Unstage this one
                            Button {
                                store.unstageDelete(asset.localIdentifier)
                                reload()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .symbolRenderingMode(.hierarchical)
                                    .font(.system(size: 18))
                                    .padding(6)
                            }
                            .tint(.secondary)
                        }
                    }
                }
                .padding(12)
            }
            .navigationTitle("Review Deletes")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear All") {
                        store.clearAllDeletes()
                        reload()
                    }
                    .disabled(store.deleteIDs.isEmpty)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        performDeletion()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .tint(.red)
                    .disabled(store.deleteIDs.isEmpty)
                }
            }
            .onAppear(perform: reload)
            .onReceive(store.objectWillChange) { _ in reload() }
        }
    }

    private func reload() {
        let ids = Array(store.deleteIDs)
        guard !ids.isEmpty else {
            assets = []
            return
        }
        let fetched = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
        var result: [PHAsset] = []
        result.reserveCapacity(fetched.count)
        fetched.enumerateObjects { a, _, _ in result.append(a) }
        assets = result
    }

    private func performDeletion() {
        let ids = Array(store.deleteIDs)
        let fetched = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(fetched as NSFastEnumeration)
        }) { success, error in
            DispatchQueue.main.async {
                if success { store.clearAllDeletes() }
                // (Optional) you can show a toast/alert based on error
                reload()
            }
        }
    }
}
