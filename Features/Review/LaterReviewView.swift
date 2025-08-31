import SwiftUI

/// Shows photos marked as "Decide Later". Lets you remove items from Later or clear all.
struct LaterReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.photoLibrary) private var lib
    @Environment(\.imageLoader) private var images
    @ObservedObject private var store = DecisionStore.shared

    @State private var assets: [PhotoAsset] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 10)], spacing: 10) {
                    ForEach(assets, id: \.id) { asset in
                        Thumb(asset: asset)
                            .overlay(alignment: .topTrailing) {
                                Button {
                                    store.unstageLater(asset.id)   // remove just this one
                                    refresh()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 18, weight: .bold))
                                        .symbolRenderingMode(.hierarchical)
                                }
                                .tint(.secondary)
                                .buttonStyle(.plain)
                                .padding(4)
                            }
                    }
                }
                .padding(12)
            }
            .navigationTitle("Decide Later")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear") {
                        store.clearLater()
                        refresh()
                    }
                    .disabled(assets.isEmpty)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear { refresh() }
            .onChange(of: store.laterIDs) { _, _ in refresh() }
        }
    }

    private func refresh() {
        // Build the asset list from the current library using the staged Later IDs.
        let all = lib.fetchAllPhotos(includeFavorites: true)
        let set = Set(store.laterIDs)
        assets = all.filter { set.contains($0.id) }
    }

    // MARK: - Small thumbnail cell
    @MainActor
    private struct Thumb: View {
        let asset: PhotoAsset
        @Environment(\.imageLoader) private var images
        @State private var uiImage: UIImage?

        var body: some View {
            ZStack {
                if let img = uiImage {
                    Image(uiImage: img).resizable().scaledToFill()
                } else {
                    Rectangle().fill(Color.secondary.opacity(0.1))
                        .overlay(ProgressView())
                }
            }
            .frame(width: 110, height: 110)
            .clipped()
            .cornerRadius(10)
            .task {
                let scale = UIScreen.main.scale
                let target = CGSize(width: 110 * scale, height: 110 * scale)
                uiImage = await images.thumbnail(for: asset, targetSize: target)
            }
        }
    }
}
