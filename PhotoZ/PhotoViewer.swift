import SwiftUI
import Photos
import PhotosUI

struct PhotoViewer: View {
    let asset: PHAsset
    @ObservedObject var lib: PhotoLibrary

    @State private var image: UIImage?
    @State private var live: PHLivePhoto?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            GeometryReader { geo in
                Group {
                    if let live {
                        LivePhotoContainer(livePhoto: live)
                            .ignoresSafeArea()
                    } else if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ProgressView().controlSize(.large)
                    }
                }
                .task {
                    await load(for: geo.size)   // <-- pass target size
                }
            }

            // Close button
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white.opacity(0.9))
                            .background(Color.black.opacity(0.25), in: Circle())
                    }
                    .padding()
                    Spacer()
                }
                Spacer()
            }
        }
        .onDisappear {
            Task { await ImageLoader.shared.cancel(for: asset.localIdentifier) } // <-- new cancel API
        }
    }

    // MARK: - Loading

    private func load(for size: CGSize) async {
        // Prefer Live Photo when available
        if asset.mediaSubtypes.contains(.photoLive) {
            if let lp = await ImageLoader.shared.livePhoto(for: asset.localIdentifier, target: size) {
                await MainActor.run { self.live = lp }
                return
            }
        }
        // Fallback to still image (use viewer size as target)
        if let img = await ImageLoader.shared.thumb(for: asset.localIdentifier, target: size) {
            await MainActor.run { self.image = img }
        }
    }
}

// MARK: - UIKit host for PHLivePhotoView

struct LivePhotoContainer: UIViewRepresentable {
    var livePhoto: PHLivePhoto?

    func makeUIView(context: Context) -> PHLivePhotoView {
        let v = PHLivePhotoView()
        v.contentMode = .scaleAspectFit
        return v
    }

    func updateUIView(_ uiView: PHLivePhotoView, context: Context) {
        uiView.livePhoto = livePhoto
        // Optionally start playback:
        // if livePhoto != nil { uiView.startPlayback(with: .full) }
    }
}
