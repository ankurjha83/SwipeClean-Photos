import SwiftUI
import Photos

struct PhotoCard: View {
    let asset: PHAsset
    @ObservedObject var lib: PhotoLibrary
    let cardSize: CGSize
    var onSingleTap: () -> Void
    var onAction: (TriageToast) -> Void

    @State private var image: UIImage?
    @State private var offset: CGSize = .zero
    @State private var isInCloud = false
    @State private var loadFailed = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ZStack {
                if let ui = image {
                    Image(uiImage: ui)
                        .resizable()
                        .interpolation(.high)        // <- sharper
                        .scaledToFill()
                } else if loadFailed {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 28))
                        Text("Preview unavailable")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text("Tap to open").font(.caption2)
                    }
                    .foregroundStyle(.white)
                } else {
                    ProgressView().controlSize(.large)
                }
                RoundedRectangle(cornerRadius: 28)
                    .strokeBorder(.white.opacity(0.25), lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 28))

            if isInCloud {
                Image(systemName: "icloud.and.arrow.down")
                    .padding(8)
                    .background(.thinMaterial, in: Circle())
                    .padding(8)
            }
        }
        .frame(width: cardSize.width, height: cardSize.height)
        .background(.black.opacity(0.001))
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .shadow(radius: 8, y: 6)
        .offset(offset)
        .rotationEffect(.degrees(Double(offset.width / 20)))

        // Double-tap = Favorite
        .highPriorityGesture(
            TapGesture(count: 2).onEnded {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                lib.favoriteTop()
                onAction(.favorite)
            }
        )
        // Single-tap = open viewer
        .onTapGesture { onSingleTap() }

        // Swipes: Right=Keep, Left=Delete, Up=Later
        .gesture(
            DragGesture()
                .onChanged { value in offset = value.translation }
                .onEnded { value in
                    let t = value.translation
                    if t.width > 100 {                // RIGHT → KEEP
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        lib.keepTop(); onAction(.keep)
                    } else if t.width < -100 {        // LEFT → DELETE
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        lib.markDeleteTop(); onAction(.delete)
                    } else if t.height < -100 {       // UP → LATER
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        lib.decideLaterTop(); onAction(.later)
                    }
                    withAnimation(.spring()) { offset = .zero }
                }
        )
        .onAppear {
            // Ask a little bigger than the visible card for crispness.
            let inflate: CGFloat = 1.1
            let requestSize = CGSize(width: cardSize.width * inflate,
                                     height: cardSize.height * inflate)
            Task {
                let img = await ImageLoader.shared.thumb(for: asset.localIdentifier, target: requestSize)
                await MainActor.run { self.image = img; self.loadFailed = (img == nil) }
            }
            lib.checkCloudStatus(for: asset) { inCloud in self.isInCloud = inCloud }
        }
        .onDisappear {
            Task { await ImageLoader.shared.cancel(for: asset.localIdentifier) }
        }
    }
}
