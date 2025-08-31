//
//  LaterDeckView.swift
//  PhotoZ
//

import SwiftUI

private extension PhotoAuthStatus {
    var isAuthorized: Bool { self == .authorized || self == .limited }
}

struct LaterDeckView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.photoLibrary) private var lib
    @Environment(\.imageLoader)  private var images
    @EnvironmentObject private var store: DecisionStore

    @State private var items: [PhotoAsset] = []
    @State private var currentIndex = 0

    private let visibleWindow  = 4
    private let prefetchWindow = 12

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let cardSize = computeCardSize(in: geo.size)

                ZStack {
                    if items.isEmpty {
                        ContentUnavailableView(
                            "No 'Later' photos",
                            systemImage: "clock.badge.exclamationmark",
                            description: Text("Swipe a photo up on the main deck to add it here.")
                        )
                    } else {
                        ForEach(visibleIndices, id: \.self) { idx in
                            let asset = items[idx]
                            let z = Double(visibleWindow - (idx - currentIndex))

                            PhotoCard(
                                asset: asset,
                                size: cardSize,
                                onDelete: { deleteTop(cardSize) },
                                onLater:  { laterTop(cardSize)  },
                                onKeep:   { keepTop(cardSize)   }
                            )
                            .frame(width: cardSize.width, height: cardSize.height)
                            .padding(.top, 12)
                            .zIndex(z)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
                .onAppear(perform: reloadFromStore)
            }
            .navigationTitle("Review: Later")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear All") {
                        store.clearAllLater()
                        reloadFromStore()
                    }
                    .disabled(store.laterIDs.isEmpty)
                }
            }
        }
        // Keep deck in sync if decisions change elsewhere
        .onReceive(store.$decisions) { _ in reloadFromStore() }
    }

    // MARK: - Loading & Derived

    private func reloadFromStore() {
        let ids = Set(store.laterIDs)
        guard lib.authorizationStatus.isAuthorized, !ids.isEmpty else {
            items = []
            currentIndex = 0
            return
        }
        // Simple approach: fetch all photos and filter to 'later' ids.
        // (This avoids needing a separate “fetch by id” service.)
        let all = lib.fetchAllPhotos(includeFavorites: true)
        items = all.filter { ids.contains($0.id) }
        currentIndex = 0
        prefetchAroundCurrent(CGSize(width: 600, height: 600))
    }

    private var visibleIndices: [Int] {
        guard !items.isEmpty else { return [] }
        let end = min(items.count, currentIndex + visibleWindow)
        return Array(currentIndex..<end)
    }

    private func computeCardSize(in size: CGSize) -> CGSize {
        let insetTop: CGFloat = 8
        let insetSides: CGFloat = 16
        let w = size.width - insetSides * 2
        let h = size.height - insetTop - 12
        return CGSize(width: w, height: h)
    }

    private func prefetchAroundCurrent(_ size: CGSize) {
        guard !items.isEmpty else { return }
        let end = min(items.count, currentIndex + prefetchWindow)
        let window = Array(items[currentIndex..<end])
        images.startPrefetch(assets: window, targetSize: size)
    }

    // MARK: - Swipes (same semantics as main deck)

    private func advance(_ size: CGSize) {
        // If we reached the end, let the deck empty out gracefully
        currentIndex = min(currentIndex + 1, max(items.count - 1, 0))
        // If the current item is now "processed", drop processed prefix
        if currentIndex >= items.count {
            items = []
            currentIndex = 0
        }
        prefetchAroundCurrent(size)
    }

    private func deleteTop(_ size: CGSize) {
        guard currentIndex < items.count else { return }
        let asset = items[currentIndex]
        store.stage(assetID: asset.id, as: .delete)  // remove from Later in your UI model
        // Optimistically remove from local list to feel snappy
        items.remove(at: currentIndex)
        if currentIndex >= items.count { currentIndex = max(items.count - 1, 0) }
        prefetchAroundCurrent(size)
    }

    private func keepTop(_ size: CGSize) {
        guard currentIndex < items.count else { return }
        let asset = items[currentIndex]
        store.stage(assetID: asset.id, as: .keep)    // remove from Later; mark kept
        items.remove(at: currentIndex)
        if currentIndex >= items.count { currentIndex = max(items.count - 1, 0) }
        prefetchAroundCurrent(size)
    }

    private func laterTop(_ size: CGSize) {
        // User reaffirmed 'later' — keep item but still advance to next
        guard currentIndex < items.count else { return }
        advance(size)
    }
}
