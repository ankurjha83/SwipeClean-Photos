import Foundation

/// High-level decision a user can make on a photo.
enum DecisionStatus: Int, Codable, CaseIterable {
    case keep = 0
    case toDelete = 1
    case later = 2
}

/// Observable store for swipe decisions (id = PHAsset.localIdentifier).
/// Step 1: in-memory staging only. (Persistence hooks included; we'll wire them in Step 4.)
@MainActor
final class DecisionStore: ObservableObject {

    /// Singleton is convenient, but you can also create/inject your own instance.
    static let shared = DecisionStore()

    /// id -> status
    @Published private(set) var decisions: [String: DecisionStatus] = [:]

    // MARK: - Staging API

    func stageKeep(_ id: String)   { decisions[id] = .keep }
    func stageDelete(_ id: String) { decisions[id] = .toDelete }
    func stageLater(_ id: String)  { decisions[id] = .later }

    /// Remove any staged decision for a given id.
    func unstage(_ id: String) { decisions.removeValue(forKey: id) }

    /// Current status for an id (if any).
    func status(for id: String) -> DecisionStatus? { decisions[id] }

    /// All IDs for a given status.
    func ids(_ status: DecisionStatus) -> [String] {
        decisions.compactMap { $0.value == status ? $0.key : nil }
    }

    /// Convenience slices.
    var keepIDs: [String]     { ids(.keep) }
    var toDeleteIDs: [String] { ids(.toDelete) }
    var laterIDs: [String]    { ids(.later) }

    /// Clear all items of a specific status.
    func clear(_ status: DecisionStatus) {
        decisions = decisions.filter { $0.value != status }
    }

    /// Reset everything (useful for testing/debug).
    func resetAll() { decisions.removeAll() }

    /// Bulk mark a list of ids with the same status (e.g., from a selection UI).
    func merge(ids: [String], as status: DecisionStatus) {
        guard !ids.isEmpty else { return }
        for id in ids { decisions[id] = status }
    }

    // MARK: - Persistence hooks (wired in Step 4)

    private let defaultsKey = "decisions_v1"

    /// Encode & save to UserDefaults. (Call in Step 4.)
    func save() {
        let raw: [String: Int] = decisions.mapValues { $0.rawValue }
        UserDefaults.standard.set(raw, forKey: defaultsKey)
    }

    /// Load from UserDefaults. (Call in Step 4.)
    func load() {
        guard let raw = UserDefaults.standard.dictionary(forKey: defaultsKey) as? [String: Int] else {
            return
        }
        var out: [String: DecisionStatus] = [:]
        out.reserveCapacity(raw.count)
        for (k, v) in raw {
            if let status = DecisionStatus(rawValue: v) {
                out[k] = status
            }
        }
        decisions = out
    }
}
