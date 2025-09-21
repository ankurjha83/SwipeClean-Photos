import SwiftUI

@main
struct PhotoZApp: App {
    // App-lifetime singletons / models
    @StateObject private var store = DecisionStore.shared
    @StateObject private var albumSel = AlbumSelection()

    var body: some Scene {
        WindowGroup {
            RootView()
                // Services via EnvironmentKey(s)
                .environment(\.photoLibrary, PhotoLibraryService.shared)
                .environment(\.imageLoader, ImageLoaderService.shared)
                // ObservableObjects via environmentObject(_:)
                .environmentObject(store)
                .environmentObject(albumSel)
        }
    }
}
