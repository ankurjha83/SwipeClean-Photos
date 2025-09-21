//
//  AlbumPickerView.swift
//  PhotoZ
//

import SwiftUI

struct AlbumPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.photoLibrary) private var lib
    @EnvironmentObject private var albumSel: AlbumSelection

    @State private var albums: [Album] = []

    var body: some View {
        NavigationStack {
            List {
                // ALL PHOTOS
                Button {
                    albumSel.selection = nil        // <-- assign directly (no $)
                    dismiss()
                } label: {
                    HStack {
                        Label("All Photos", systemImage: "photo.on.rectangle")
                        Spacer()
                        if albumSel.selection == nil {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                }

                // ALBUMS
                Section("Albums") {
                    ForEach(albums) { album in
                        Button {
                            albumSel.selection = album   // <-- assign directly (no $)
                            dismiss()
                        } label: {
                            // If you have AlbumRowView, use it:
                            // AlbumRowView(album: album, isSelected: albumSel.selection == album)
                            HStack {
                                Text(albumTitle(album))
                                Spacer()
                                if albumSel.selection == album {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Choose Album")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        // Load albums once the view appears
        .task {
            // If your service exposes a different API for albums, swap this line accordingly.
            albums = lib.fetchAlbums()
        }
    }

    // MARK: - Helpers

    private func albumTitle(_ album: Album) -> String {
        // If you created Album+extras with `title`, feel free to just return album.title
        // This fallback reads from the underlying PHAssetCollection:
        album.collection.localizedTitle ?? "Album"
    }
}
