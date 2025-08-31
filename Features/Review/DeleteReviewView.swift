import SwiftUI
import Photos

/// Shows all photos staged for deletion. Lets the user deselect some,
/// and bulk delete the selected ones using PhotoLibraryService.
struct DeleteReviewView: View {
    @Environment(\.photoLibrary) private var lib
    @Environment(\.imageLoader)  private var images
    @ObservedObject private var store = DecisionStore.shared

    @State private var assets: [PhotoAsset] = []
    @State private var selection = Set<String>() // localIdentifiers
    @State private var isDeleting = false
    @State private var errorMessage: String?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        VStack(spacing: 0) {
            if assets.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "trash.slash")
                        .font(.system(size: 36))
                    Text("Nothing marked for deletion")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(assets, id: \.id) { asset in
                            ThumbCell(
                                asset: asset,
                                selected: selection.contains(asset.id),
                                images: images
                            )
                            .onTapGesture {
                                toggle(asset.id)
                            }
                        }
                    }
                    .padding(8)
                }
                Divider()
                toolbar
            }
        }
        .navigationTitle("Review Deletes")
        .toolbarTitleDisplayMode(.inline)
        .onAppear { reloadAssetsFromStore() }
        .onChange(of: store.toDeleteIDs) { _, _ in
            reloadAssetsFromStore()
        }
        .alert("Error", isPresented: .constant(errorMessage != nil), actions: {
            Button("OK") { errorMessage = nil }
        }, message: {
            Text(errorMessage ?? "")
        })
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 12) {
            Button {
                // Deselect: keep selected
                for id in selection {
                    store.stageKeep(id) // removes from delete list
                }
                selection.removeAll()
                reloadAssetsFromStore()
            } label: {
                Label("Keep Selected", systemImage: "checkmark.circle")
            }
            .buttonStyle(.bordered)

            Spacer()

            Button {
                if selection.isEmpty { return }
                Task { await confirmDelete() }
            } label: {
                if isDeleting {
                    ProgressView()
                } else {
                    Label("Delete (\(selection.count))", systemImage: "trash.fill")
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .disabled(selection.isEmpty || isDeleting)
        }
        .padding(12)
        .background(.bar)
    }

    // MARK: - Actions

    private func toggle(_ id: String) {
        if selection.contains(id) { selection.remove(id) }
        else { selection.insert(id) }
    }

    private func reloadAssetsFromStore() {
        // Rebuild assets from the store’s toDelete IDs.
        let ids = store.toDeleteIDs
        selection = Set(ids)
        assets = fetchAssets(for: ids)
    }

    private func fetchAssets(for ids: [String]) -> [PhotoAsset] {
        guard !ids.isEmpty else { return [] }
        let result = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
        var out: [PhotoAsset] = []
        out.reserveCapacity(result.count)
        result.enumerateObjects { a, _, _ in out.append(PhotoAsset(a)) }
        // Keep user-visible order similar to ids[]
        let indexByID = ids.enumerated().reduce(into: [String: Int]()) { $0[$1.element] = $1.offset }
        return out.sorted { (indexByID[$0.id] ?? 0) < (indexByID[$1.id] ?? 0) }
    }

    private func confirmDelete() async {
        isDeleting = true
        defer { isDeleting = false }

        do {
            try await lib.delete(localIDs: Array(selection))
            // Remove just the deleted ones from store
            for id in selection {
                if store.status(for: id) == .toDelete {
                    store.unstage(id)
                }
            }
            selection.removeAll()
            reloadAssetsFromStore()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Thumbnail Cell

private struct ThumbCell: View {
    let asset: PhotoAsset
    let selected: Bool
    let images: ImageLoading

    @State private var image: UIImage?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle().fill(Color.secondary.opacity(0.12))
                        .overlay(ProgressView())
                }
            }
            .frame(height: 110)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            if selected {
                Image(systemName: "checkmark.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .blue)
                    .padding(6)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .task {
            // Modest target size for grid thumbs
            let scale = UIScreen.main.scale
            let target = CGSize(width: 120 * scale, height: 120 * scale)
            let ui = await images.thumbnail(for: asset, targetSize: target)
            await MainActor.run { self.image = ui }
        }
    }
}
