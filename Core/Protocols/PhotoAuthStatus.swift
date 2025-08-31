import CoreGraphics

public enum PhotoAuthStatus {
    case notDetermined, denied, limited, authorized
}

public protocol PhotoLibraryProtocol: AnyObject {
    var authorizationStatus: PhotoAuthStatus { get }
    func requestAuthorization() async -> PhotoAuthStatus

    func fetchAllPhotos(includeFavorites: Bool) -> [PhotoAsset]
    func fetch(in album: Album, includeFavorites: Bool) -> [PhotoAsset]

    func delete(localIDs: [String]) async throws
}

public extension PhotoAuthStatus {
    init(photoKitRaw: Int) {
        // Maps PHAuthorizationStatus raw values without importing Photos here
        switch photoKitRaw {
        case 3: self = .authorized
        case 2: self = .denied
        case 4: self = .limited
        case 0: fallthrough
        default: self = .notDetermined
        }
    }
}
