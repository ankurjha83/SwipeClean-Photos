import SwiftUI

private struct PhotoLibraryKey: EnvironmentKey {
    static let defaultValue: PhotoLibraryProtocol = PhotoLibraryService.shared
}
private struct ImageLoaderKey: EnvironmentKey {
    static let defaultValue: ImageLoading = ImageLoader.shared
}

public extension EnvironmentValues {
    var photoLibrary: PhotoLibraryProtocol {
        get { self[PhotoLibraryKey.self] }
        set { self[PhotoLibraryKey.self] = newValue }
    }
    var imageLoader: ImageLoading {
        get { self[ImageLoaderKey.self] }
        set { self[ImageLoaderKey.self] = newValue }
    }
}
