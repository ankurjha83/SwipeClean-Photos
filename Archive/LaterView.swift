//
//  LaterView.swift
//  PhotoZ
//
//  Created by Swati Pareek on 13/08/25.
//


import Photos
import SwiftUI

struct LaterView: View {
    @Environment(\.dismiss) var dismiss
    @State private var items: [PHAsset] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], spacing: 8) {
                    ForEach(items, id: \.localIdentifier) { asset in
                        LaterThumb(asset: asset)
                    }
                }
                .padding(12)
            }
            .navigationTitle("Later")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear") {
                        for id in LaterStore.load() { LaterStore.remove(id) }
                        load()
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear(perform: load)
    }

    private func load() {
        let ids = Array(LaterStore.load())
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
        var out: [PHAsset] = []
        assets.enumerateObjects { asset, _, _ in out.append(asset) }
        items = out
    }
}

struct LaterThumb: View {
    let asset: PHAsset
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let ui = image {
                Image(uiImage: ui).resizable().scaledToFill()
            } else {
                Color.secondary.opacity(0.2)
            }
        }
        .frame(height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            PHCachingImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: 400, height: 400),
                contentMode: PHImageContentMode.aspectFill,
                options: nil
            ) { img, _ in
                image = img
            }
        }
    }
}
