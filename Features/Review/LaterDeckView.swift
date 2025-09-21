////
////  LaterDeckView.swift
////  PhotoZ
////
//
//import SwiftUI
//
//struct LaterDeckView: View {
//    @Environment(\.imageLoader)  private var images
//    @EnvironmentObject private var store: DecisionStore
//
//    private let assets: [PhotoAsset]
//    @State private var items: [PhotoAsset] = []
//    @State private var currentIndex = 0
//
//    private let visibleWindow  = 4
//    private let prefetchWindow = 16
//
//    init(assets: [PhotoAsset]) {
//        self.assets = assets
//    }
//
//    var body: some View {
//        GeometryReader { geo in
//            let cardSize = computeCardSize(in: geo.size)
//
//            ZStack {
//                ForEach(visibleIndices, id: \.self) { idx in
//                    let asset = items[idx]
//                    let z = Double(visibleWindow - (idx - currentIndex))
//
//                    PhotoCard(
//                        asset: asset,
//                        size: cardSize,
//                        onDelete: { stage(.delete, size: cardSize) },
//                        onLater:  { stage(.later,  size: cardSize) },
//                        onKeep:   { stage(.keep,   size: cardSize) }
//                    )
//                    .frame(width: cardSize.width, height: cardSize.height)
//                    .padding(.top, 12)
//                    .zIndex(z)
//                }
//            }
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
//            .background(.black.opacity(0.001)) // keep gestures/taps sane
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button { dismiss() } label: {
//                        Label("Close", systemImage: "xmark")
//                    }
//                }
//            }
//        }
//        .navigationTitle("Review Later")
//        .navigationBarTitleDisplayMode(.inline)
//        .task {
//            items = assets
//            currentIndex = 0
//            prefetchAroundCurrent(CGSize(width: 600, height: 600))
//        }
//    }
//
//    // MARK: - Derived
//
//    private var visibleIndices: [Int] {
//        guard !items.isEmpty else { return [] }
//        let end = min(items.count, currentIndex + visibleWindow)
//        return Array(currentIndex..<end)
//    }
//
//    // MARK: - Actions
//
//    private enum Action { case keep, delete, later }
//
//    private func stage(_ action: Action, size: CGSize) {
//        guard currentIndex < items.count else { return }
//        let asset = items[currentIndex]
//        switch action {
//        case .keep:   store.stage(assetID: asset.id, as: .keep)
//        case .delete: store.stage(assetID: asset.id, as: .delete)
//        case .later:  store.stage(assetID: asset.id, as: .later)
//        }
//        advance(size)
//    }
//
//    private func advance(_ size: CGSize) {
//        currentIndex = min(currentIndex + 1, max(items.count - 1, 0))
//        prefetchAroundCurrent(size)
//        if currentIndex >= items.count - 1 {
//            // optional: auto-dismiss when done
//        }
//    }
//
//    private func prefetchAroundCurrent(_ size: CGSize) {
//        guard !items.isEmpty else { return }
//        let end = min(items.count, currentIndex + prefetchWindow)
//        let window = Array(items[currentIndex..<end])
//        images.startPrefetch(assets: window, targetSize: size)
//    }
//
//    private func computeCardSize(in size: CGSize) -> CGSize {
//        let insetTop: CGFloat = 8
//        let insetSides: CGFloat = 16
//        let w = size.width - insetSides * 2
//        let h = size.height - insetTop - 12
//        return CGSize(width: w, height: h)
//    }
//
//    @Environment(\.dismiss) private var dismiss
//}
import SwiftUI

struct LaterDeckView: View {
    @Environment(\.imageLoader) private var images
    @ObservedObject private var store = DecisionStore.shared

    // Seed the deck with the current Later items
    private let seed: [PhotoAsset]
    private let onFinish: () -> Void

    @State private var items: [PhotoAsset] = []
    @State private var index: Int = 0

    private let visibleWindow  = 4
    private let prefetchWindow = 16

    init(items: [PhotoAsset], onFinish: @escaping () -> Void = {}) {
        self.seed = items
        self.onFinish = onFinish
    }

    var body: some View {
        GeometryReader { geo in
            let size = computeCardSize(in: geo.size)

            ZStack {
                ForEach(visibleIndices, id: \.self) { i in
                    let asset = items[i]
                    let z = Double(visibleWindow - (i - index))
                    PhotoCard(
                        asset: asset,
                        size: size,
                        onDelete: { stage(.delete, asset) },
                        onLater:  { stage(.later,  asset) },
                        onKeep:   { stage(.keep,   asset) }
                    )
                    .frame(width: size.width, height: size.height)
                    .padding(.top, 12)
                    .zIndex(z)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.001)) // keep gestures responsive
        }
        .navigationTitle("Review Later")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") { onFinish(); dismiss() }
            }
        }
        .task {
            items = seed
            index = 0
            prefetchAroundCurrent(CGSize(width: 600, height: 600))
        }
        .onDisappear { onFinish() }
    }

    // MARK: - Derived

    private var visibleIndices: [Int] {
        guard !items.isEmpty else { return [] }
        let end = min(items.count, index + visibleWindow)
        return Array(index..<end)
    }

    // MARK: - Actions

    private func stage(_ status: DecisionStatus, _ asset: PhotoAsset) {
        // Record the user’s final decision
        store.stage(assetID: asset.id, as: status)

        // If they chose keep/delete, ensure it’s removed from the Later set
        if status != .later {
            // ✅ DecisionStore expects an unlabeled Set<String>
            store.unstageLater(Set([asset.id]))
        }

        advance()
    }

    private func advance() {
        index += 1
        if index >= items.count {
            // Finished the deck
            onFinish()
            dismiss()
        } else {
            prefetchAroundCurrent(CGSize(width: 600, height: 600))
        }
    }

    // MARK: - Prefetch

    private func prefetchAroundCurrent(_ size: CGSize) {
        guard !items.isEmpty else { return }
        let end = min(items.count, index + prefetchWindow)
        let window = Array(items[index..<end])
        images.startPrefetch(assets: window, targetSize: size)
    }

    // MARK: - Layout

    private func computeCardSize(in container: CGSize) -> CGSize {
        let insetTop: CGFloat = 8
        let insetSides: CGFloat = 16
        let w = container.width - insetSides * 2
        let h = container.height - insetTop - 12
        return CGSize(width: w, height: h)
    }

    @Environment(\.dismiss) private var dismiss
}
