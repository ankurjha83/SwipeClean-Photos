//import SwiftUI
//
//// Provide default environment values from the singletons on the main actor.
//private struct PhotoLibraryKey: EnvironmentKey {
//    @MainActor static var defaultValue: PhotoLibraryProtocol = PhotoLibraryService.shared
//}
//
//private struct ImageLoaderKey: EnvironmentKey {
//    @MainActor static var defaultValue: ImageLoading = ImageLoaderService.shared
//}
//
//extension EnvironmentValues {
//    var photoLibrary: PhotoLibraryProtocol {
//        get { self[PhotoLibraryKey.self] }
//        set { self[PhotoLibraryKey.self] = newValue }
//    }
//    var imageLoader: ImageLoading {
//        get { self[ImageLoaderKey.self] }
//        set { self[ImageLoaderKey.self] = newValue }
//    }
//}

import SwiftUI

private struct PhotoLibraryKey: EnvironmentKey {
    static let defaultValue: PhotoLibraryProtocol = PhotoLibraryService.shared
}

extension EnvironmentValues {
    var photoLibrary: PhotoLibraryProtocol {
        get { self[PhotoLibraryKey.self] }
        set { self[PhotoLibraryKey.self] = newValue }
    }
}
