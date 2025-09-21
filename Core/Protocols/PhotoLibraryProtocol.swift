//import Foundation
//
//@MainActor
//protocol PhotoLibraryProtocol: AnyObject {
//    var authorizationStatus: PhotoAuthStatus { get }
//    func requestAuthorization() async -> PhotoAuthStatus
//
//    func fetchAllPhotos(includeFavorites: Bool) -> [PhotoAsset]
//    func fetch(in album: Album, includeFavorites: Bool) -> [PhotoAsset]   // <- used by CardStackView
//    func fetchAlbums() -> [Album]
//    func delete(localIDs: [String]) async throws
//
//    func presentLimitedLibraryPicker()
//}
import Photos

/// Photo library surface used by the app. Main-actor because PhotoKit is UI-bound.
/// Keep this protocol internal unless all referenced model types are public.
@MainActor
protocol PhotoLibraryProtocol: AnyObject {
    var authorizationStatus: PhotoAuthStatus { get }
    @discardableResult
    func requestAuthorization() async -> PhotoAuthStatus

    /// All photos ordered recent-first.
    func fetchAllPhotos(includeFavorites: Bool) -> [PhotoAsset]

    /// Photos within a specific album ordered recent-first.
    func fetch(in album: Album, includeFavorites: Bool) -> [PhotoAsset]

    /// Look up concrete assets by local identifiers (order preserved).
    func assets(withIDs ids: [String]) -> [PhotoAsset]

    /// 🔹 NEW: List albums the user can pick from (includes Recents/User Library, Favorites, and user-created albums).
    func fetchAlbums() -> [Album]
}
