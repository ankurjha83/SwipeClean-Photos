import Foundation

@MainActor
final class AlbumSelection: ObservableObject {
    // Use Album?; Album should be Hashable/Equatable (yours is).
    @Published var selection: Album? = nil
}
