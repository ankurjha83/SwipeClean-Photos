import SwiftUI
import Photos

struct CardStackView: View {
    @ObservedObject var lib: PhotoLibrary

    @State private var showViewer = false
    @State private var selectedAsset: PHAsset?

    // Bottom-center toast
    @State private var toast: TriageToast?
    @State private var toastCancel: DispatchWorkItem?

    var body: some View {
        GeometryReader { geo in
            let hInset: CGFloat = 14
            let topReserve: CGFloat = geo.safeAreaInsets.top + 58
            let bottomReserve: CGFloat = geo.safeAreaInsets.bottom + 72
            let cardW = geo.size.width - hInset * 2
            let cardH = max(420, geo.size.height - (topReserve + bottomReserve))
            let cardSize = CGSize(width: cardW, height: cardH)

            ZStack {
                ForEach(Array(lib.stack.prefix(3)).reversed(), id: \.localIdentifier) { asset in
                    PhotoCard(
                        asset: asset,
                        lib: lib,
                        cardSize: cardSize,
                        onSingleTap: {
                            selectedAsset = asset
                            showViewer = true
                        },
                        onAction: { kind in
                            showToast(kind)
                        }
                    )
                    .scaleEffect(asset == lib.stack.first ? 1.0 : 0.98)
                    .offset(y: asset == lib.stack.first ? 0 : 12)
                    .zIndex(asset == lib.stack.first ? 1 : 0)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)

            .overlay(alignment: .bottom) {
                if let t = toast {
                    HStack { Spacer(); ActionToastIcon(type: t); Spacer() }
                        .padding(.bottom, geo.safeAreaInsets.bottom + 72)
                        .allowsHitTesting(false)
                        .transition(.opacity.combined(with: .scale))
                        .zIndex(1000)
                }
            }

            .onAppear { prefetchWindow(for: cardSize) }
            .onChange(of: lib.stack.first?.localIdentifier, initial: false) { _, _ in
                prefetchWindow(for: cardSize)
            }
            .onDisappear {
                Task { await ImageLoader.shared.clearAllCaching(target: cardSize) }
            }
        }
        .fullScreenCover(isPresented: $showViewer) {
            if let asset = selectedAsset {
                PhotoViewer(asset: asset, lib: lib)
            }
        }
    }

    // MARK: - Prefetch (top + next 6)

    private func prefetchWindow(for cardSize: CGSize) {
        let topID = lib.stack.first?.localIdentifier
        let nextIDs = Array(lib.stack.dropFirst().prefix(6)).map { $0.localIdentifier }
        Task { await ImageLoader.shared.prefetchWindow(top: topID, next: nextIDs, target: cardSize) }
    }

    // MARK: - Toast

    private func showToast(_ t: TriageToast) {
        toastCancel?.cancel()
        withAnimation { toast = t }
        let work = DispatchWorkItem { withAnimation { self.toast = nil } }
        toastCancel = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: work)
    }
}
