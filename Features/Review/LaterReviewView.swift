//////
//////  LaterReviewView.swift
//////  PhotoZ
//////
////
////import SwiftUI
////import Photos
////
////private struct LaterThumbCell: View {
////    let asset: PHAsset
////    let side: CGFloat
////    let onUnstage: (String) -> Void
////    @State private var image: UIImage?
////
////    var body: some View {
////        ZStack(alignment: .topTrailing) {
////            ZStack {
////                if let ui = image {
////                    Image(uiImage: ui).resizable().scaledToFill()
////                } else {
////                    Rectangle().fill(Color.secondary.opacity(0.12)).overlay(ProgressView())
////                }
////            }
////            .frame(width: side, height: side)
////            .clipped()
////            .cornerRadius(12)
////            .task { await loadThumb(side: side) }
////
////            Button { onUnstage(asset.localIdentifier) } label: {
////                Image(systemName: "xmark.circle.fill")
////                    .symbolRenderingMode(.hierarchical)
////                    .font(.system(size: 18))
////                    .padding(6)
////            }
////            .tint(.secondary)
////        }
////    }
////
////    private func loadThumb(side: CGFloat) async {
////        let scale = UIScreen.main.scale
////        let target = CGSize(width: side * scale, height: side * scale)
////        let opts = PHImageRequestOptions()
////        opts.isSynchronous = false
////        opts.isNetworkAccessAllowed = true
////        opts.deliveryMode = .opportunistic
////        opts.resizeMode = .fast
////
////        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
////            PHImageManager.default().requestImage(
////                for: asset,
////                targetSize: target,
////                contentMode: .aspectFill,
////                options: opts
////            ) { img, _ in
////                if let img { self.image = img }
////                cont.resume()
////            }
////        }
////    }
////}
////
////struct LaterReviewView: View {
////    @EnvironmentObject private var store: DecisionStore
////    @Environment(\.photoLibrary) private var lib
////
////    @State private var assets: [PHAsset] = []
////    @State private var showDeck = false
////
////    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 10)]
////    private let cellSide: CGFloat = 110
////
////    var body: some View {
////        NavigationStack {
////            content
////                .navigationTitle("Decide Later")
////                .toolbar {
////                    ToolbarItem(placement: .topBarLeading) {
////                        Button("Start Review") { showDeck = true }
////                            .disabled(store.laterIDs.isEmpty)
////                    }
////                    ToolbarItem(placement: .topBarTrailing) {
////                        Button("Clear All") {
////                            store.clearAllLater()
////                            reload()
////                        }
////                        .disabled(store.laterIDs.isEmpty)
////                    }
////                }
////        }
////        .onAppear(perform: reload)
////        .onReceive(store.$decisions) { _ in reload() }
////        .fullScreenCover(isPresented: $showDeck) {
////            LaterDeckView()
////                .environmentObject(store)
////                .environment(\.photoLibrary, lib)
////        }
////    }
////
////    @ViewBuilder
////    private var content: some View {
////        if assets.isEmpty {
////            ContentUnavailableView(
////                "No 'Decide Later' photos",
////                systemImage: "clock.badge.exclamationmark",
////                description: Text("Swipe a photo up on the main deck to add it here.")
////            )
////        } else {
////            ScrollView {
////                LazyVGrid(columns: columns, spacing: 10) {
////                    ForEach(assets, id: \.localIdentifier) { asset in
////                        LaterThumbCell(asset: asset, side: cellSide) { id in
////                            store.unstageLater(Set([id]))
////                            reload()
////                        }
////                    }
////                }
////                .padding(12)
////            }
////        }
////    }
////
////    private func reload() {
////        let ids = Array(store.laterIDs)
////        guard !ids.isEmpty else {
////            assets = []
////            return
////        }
////        let fetched = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
////        var result: [PHAsset] = []
////        result.reserveCapacity(fetched.count)
////        fetched.enumerateObjects { a, _, _ in result.append(a) }
////        assets = result
////    }
////}
//
//
////
////  LaterReviewView.swift
////  PhotoZ
////
//
//import SwiftUI
//
//struct LaterReviewView: View {
//    @Environment(\.photoLibrary) private var lib
//    @Environment(\.imageLoader)  private var images
//    @EnvironmentObject private var store: DecisionStore
//
//    @State private var assets: [PhotoAsset] = []
//    @State private var showDeck = false
//
//    private let cols = [ GridItem(.adaptive(minimum: 110), spacing: 10) ]
//
//    var body: some View {
//        NavigationStack {
//            Group {
//                if assets.isEmpty {
//                    ContentUnavailableView(
//                        "Nothing in Later",
//                        systemImage: "clock",
//                        description: Text("Swipe up from the deck to stage photos here.")
//                    )
//                } else {
//                    ScrollView {
//                        LazyVGrid(columns: cols, spacing: 10) {
//                            ForEach(assets, id: \.id) { asset in
//                                ThumbTile(asset: asset)
//                                    .aspectRatio(1, contentMode: .fit)
//                            }
//                        }
//                        .padding(12)
//                    }
//                }
//            }
//            .navigationTitle("Decide Later")
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    if !assets.isEmpty {
//                        Button {
//                            showDeck = true
//                        } label: {
//                            Label("Review", systemImage: "rectangle.stack")
//                        }
//                    }
//                }
//                ToolbarItem(placement: .navigationBarLeading) {
//                    if !assets.isEmpty {
//                        Button(role: .destructive) {
//                            store.clearAllLater()
//                            reload()
//                        } label: {
//                            Label("Clear", systemImage: "xmark.circle")
//                        }
//                    }
//                }
//            }
//        }
//        .onAppear(perform: reload)
//        .onChange(of: store.laterIDs) { _, _ in reload() }
//        .fullScreenCover(isPresented: $showDeck) {
//            LaterDeckView(assets: assets)
//                .environment(\.photoLibrary, lib)
//                .environment(\.imageLoader, images)
//                .environmentObject(store)
//        }
//    }
//
//    private func reload() {
//        // turn the staged IDs back into PhotoAsset objects
//        // adapt the accessor to your PhotoLibraryService:
//        assets = store.laterIDs
//            .compactMap { lib.asset(forLocalIdentifier: $0) }  // or lib.asset(for:), lib.asset(id:), etc.
//            .map { PhotoAsset($0) }
//    }
//}
//
//// MARK: - Thumbnail tile (no continuations here)
//
//private struct ThumbTile: View {
//    let asset: PhotoAsset
//    @Environment(\.imageLoader) private var images
//    @State private var img: UIImage?
//
//    var body: some View {
//        ZStack {
//            if let ui = img {
//                Image(uiImage: ui)
//                    .resizable()
//                    .scaledToFill()
//                    .clipped()
//                    .cornerRadius(12)
//            } else {
//                RoundedRectangle(cornerRadius: 12, style: .continuous)
//                    .fill(Color.secondary.opacity(0.12))
//                    .overlay(ProgressView())
//            }
//        }
//        .task(id: asset.id) {
//            // crisp grid thumbs ~160pt square
//            let s = UIScreen.main.scale
//            let target = CGSize(width: 160 * s, height: 160 * s)
//            img = await images.thumbnail(for: asset, targetSize: target)
//        }
//    }
//}

import SwiftUI

struct LaterReviewView: View {
    @Environment(\.photoLibrary) private var lib
    @Environment(\.imageLoader)  private var images
    @ObservedObject private var store = DecisionStore.shared

    @State private var assets: [PhotoAsset] = []
    @State private var showDeck = false

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 10)]

    var body: some View {
        NavigationStack {
            Group {
                if assets.isEmpty {
                    ContentUnavailableView(
                        "No items marked Later",
                        systemImage: "clock",
                        description: Text("Swipe up on a photo to stage it for Later.")
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(assets, id: \.id) { asset in
                                ThumbTile(asset: asset)
                                    .onTapGesture { showDeck = true } // quick way to jump into review
                            }
                        }
                        .padding(12)
                    }
                }
            }
            .navigationTitle("Later")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Review") { showDeck = true }
                        .disabled(assets.isEmpty)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear All") {
                        store.clearAllLater()
                        reload()
                    }
                    .disabled(assets.isEmpty)
                }
            }
        }
        .onAppear(perform: reload)
        .onChange(of: store.laterIDs) { _, _ in reload() }
        .fullScreenCover(isPresented: $showDeck) {
            LaterDeckView(items: assets) {
                reload()
            }
        }
    }

    private func reload() {
        // ✅ use the protocol’s batch lookup (order preserved)
        let ids = Array(store.laterIDs)
        assets = lib.assets(withIDs: ids)
    }
}

// Small square thumbnail that uses the shared image loader (no continuations)
private struct ThumbTile: View {
    let asset: PhotoAsset
    @Environment(\.imageLoader) private var images
    @State private var img: UIImage?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.secondary.opacity(0.12))

            if let ui = img {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                ProgressView().controlSize(.small)
            }
        }
        .frame(width: 110, height: 110)
        .task(id: asset.id) {
            let s = UIScreen.main.scale
            img = await images.thumbnail(for: asset, targetSize: .init(width: 110*s, height: 110*s))
        }
    }
}
