import SwiftUI
import Photos
import UIKit

struct RootView: View {
    @StateObject var lib = PhotoLibrary()

    @State private var showAlbumPicker = false
    @State private var confirmBatchDelete = false

    var body: some View {
        NavigationStack {
            content
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(.hidden, for: .navigationBar)
                .background(Color.black.ignoresSafeArea())
        }
        // TOP: header below the status bar (no overlap)
        .safeAreaInset(edge: .top) {
            HeaderBar(
                title: titleForSource(lib.source),
                laterAction: { toggleLater() },
                deleteAction: { confirmBatchDelete = true },
                albumAction: { showAlbumPicker = true },
                pendingDeleteCount: lib.pendingDeleteIDs.count
            )
            .padding(.horizontal, 12)
            .padding(.top, 4)
        }
        // BOTTOM: mini bar above the home indicator
        .safeAreaInset(edge: .bottom) {
            BottomMiniBar(
                laterAction: { toggleLater() },
                deleteAction: { confirmBatchDelete = true },
                undoAction: { lib.undoLast() },
                albumAction: { showAlbumPicker = true },
                pendingDeleteCount: lib.pendingDeleteIDs.count,
                isShowingLater: lib.source == .later,
                canUndo: lib.lastAction != nil
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
        // Alerts & sheets
        .alert("Delete \(lib.pendingDeleteIDs.count) photo(s)?",
               isPresented: $confirmBatchDelete) {
            Button("Delete", role: .destructive) { lib.commitDeletes() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Items move to \"Recently Deleted\" and can be restored for ~30 days.")
        }
        .sheet(isPresented: $showAlbumPicker) {
            AlbumPickerView(lib: lib)
        }
    }

    // MARK: - Screen content

    @ViewBuilder
    private var content: some View {
        switch lib.authStatus {
        case .authorized, .limited:
            CardStackView(lib: lib) // fills behind the insets

        case .denied:
            VStack(spacing: 12) {
                Text("Photo access is required").font(.headline)
                Text("Enable in Settings → Privacy → Photos.")
                Button("Request Again") { lib.requestAccessAndLoad() }
            }
            .padding()

        default:
            VStack {
                ProgressView()
                Text("Requesting access…")
            }
            .task { lib.requestAccessAndLoad() }
        }
    }

    // MARK: - Actions

    private func toggleLater() {
        if lib.source == .later { lib.loadAll() } else { lib.loadLater() }
    }

    private func titleForSource(_ s: PhotoLibrary.Source) -> String {
        switch s {
        case .all:   return "SwipeClean – Photos"
        case .later: return "SwipeClean — Later"
        case .album(let c): return c.localizedTitle ?? "Album"
        }
    }
}

// MARK: - Header + Bottom bar (unchanged from before)

private struct HeaderBar: View {
    let title: String
    let laterAction: () -> Void
    let deleteAction: () -> Void
    let albumAction: () -> Void
    let pendingDeleteCount: Int

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)

            Spacer()

            Menu {
                Button(action: { laterAction() }) {
                    Label("Later", systemImage: "clock")
                }
                Button(role: .destructive, action: { deleteAction() }) {
                    Label("Delete Pending (\(pendingDeleteCount))", systemImage: "trash")
                }
                .disabled(pendingDeleteCount == 0)

                Divider()
                Button(action: { albumAction() }) {
                    Label("Albums…", systemImage: "rectangle.stack")
                }
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.title2)
                    .padding(8)
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct BottomMiniBar: View {
    let laterAction: () -> Void
    let deleteAction: () -> Void
    let undoAction: () -> Void
    let albumAction: () -> Void
    let pendingDeleteCount: Int
    let isShowingLater: Bool
    let canUndo: Bool

    var body: some View {
        HStack(spacing: 22) {
            Button(action: { laterAction() }) {
                VStack(spacing: 2) { Image(systemName: "clock"); Text(isShowingLater ? "All" : "Later") }
            }
            Button(action: { deleteAction() }) {
                VStack(spacing: 2) {
                    Image(systemName: "trash.fill").symbolRenderingMode(.hierarchical)
                    Text(pendingDeleteCount > 0 ? "Delete \(pendingDeleteCount)" : "Delete")
                }
            }
            .tint(.red)
            .disabled(pendingDeleteCount == 0)

            Button(action: { undoAction() }) {
                VStack(spacing: 2) { Image(systemName: "arrow.uturn.backward.circle"); Text("Undo") }
            }
            .disabled(!canUndo)
            .opacity(canUndo ? 1 : 0.5)

            Button(action: { albumAction() }) {
                VStack(spacing: 2) { Image(systemName: "rectangle.stack"); Text("Albums") }
            }
        }
        .font(.footnote)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: Capsule())
    }
}
