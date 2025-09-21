import SwiftUI

private extension PhotoAuthStatus {
    var isAuthorized: Bool { self == .authorized || self == .limited }
}

struct CardStackView: View {
    @Environment(\.photoLibrary) private var lib
    @Environment(\.imageLoader)  private var images
    @EnvironmentObject private var store: DecisionStore
    @EnvironmentObject private var albumSel: AlbumSelection

    @State private var items: [PhotoAsset] = []
    @State private var currentIndex = 0

    private let visibleWindow  = 4
    private let prefetchWindow = 16

    var body: some View {
        GeometryReader { geo in
            let cardSize = computeCardSize(in: geo.size)

            ZStack {
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .task { await requestIfNeededAndLoad() }
        .onChange(of: lib.authorizationStatus) { _, new in
            if new.isAuthorized { loadInitial() }
        }
        .onChange(of: albumSel.selection) { _, _ in
            if lib.authorizationStatus.isAuthorized { loadInitial() }
        }
    }

    // MARK: - Derived
    private var visibleIndices: [Int] {
        guard !items.isEmpty else { return [] }
        let end = min(items.count, currentIndex + visibleWindow)
        return Array(currentIndex..<end)
    }

    // MARK: - Loading
    private func requestIfNeededAndLoad() async {
        let status = lib.authorizationStatus
        if status == .notDetermined {
            let new = await lib.requestAuthorization()
            if new.isAuthorized { await MainActor.run { loadInitial() } }
        } else if status.isAuthorized {
            loadInitial()
        }
    }

    private func loadInitial() {
        let includeFavorites = true
        if let selected = albumSel.selection {
            items = lib.fetch(in: selected, includeFavorites: includeFavorites)
        } else {
            items = lib.fetchAllPhotos(includeFavorites: includeFavorites)
        }
        currentIndex = 0
        prefetchAroundCurrent(CGSize(width: 600, height: 600))
    }

    private func prefetchAroundCurrent(_ size: CGSize) {
        guard !items.isEmpty else { return }
        let end = min(items.count, currentIndex + prefetchWindow)
        let window = Array(items[currentIndex..<end])
        images.startPrefetch(assets: window, targetSize: size)
    }

    // MARK: - Swipes
    private func advance(_ size: CGSize) {
        currentIndex = min(currentIndex + 1, max(items.count - 1, 0))
        prefetchAroundCurrent(size)
    }

    private func deleteTop(_ size: CGSize) {
        guard currentIndex < items.count else { return }
        let asset = items[currentIndex]
        // IMPORTANT: call the store method; no '$' prefix, and make enum explicit to avoid inference issues
        store.stage(assetID: asset.id, as: DecisionStatus.delete)
        advance(size)
    }

    private func keepTop(_ size: CGSize) {
        guard currentIndex < items.count else { return }
        let asset = items[currentIndex]
        store.stage(assetID: asset.id, as: DecisionStatus.keep)
        advance(size)
    }

    private func laterTop(_ size: CGSize) {
        guard currentIndex < items.count else { return }
        let asset = items[currentIndex]
        store.stage(assetID: asset.id, as: DecisionStatus.later)
        advance(size)
    }

    // MARK: - Layout
    private func computeCardSize(in size: CGSize) -> CGSize {
        let insetTop: CGFloat = 8
        let insetSides: CGFloat = 16
        let w = size.width - insetSides * 2
        let h = size.height - insetTop - 12
        return CGSize(width: w, height: h)
    }
}
