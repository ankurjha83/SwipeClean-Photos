import Foundation

/// Observable store for swipe decisions (id = PHAsset.localIdentifier).
/// Persistence: auto-saves to UserDefaults.
@MainActor
final class DecisionStore: ObservableObject {

    // Singleton (or inject your own instance if preferred)
    static let shared = DecisionStore()

    // Storage
    @Published private(set) var decisions: [String: DecisionStatus] = [:] {
        didSet { save() }
    }

    private let defaultsKey = "decisions_v1"

    // Init / Load
    init() { load() }

    // MARK: Staging API

    func stageKeep(_ id: String)   { decisions[id] = .keep }
    func stageDelete(_ id: String) { decisions[id] = .toDelete }
    func stageLater(_ id: String)  { decisions[id] = .later }

    func unstage(_ id: String) { decisions.removeValue(forKey: id) }
    func status(for id: String) -> DecisionStatus? { decisions[id] }

    func ids(_ status: DecisionStatus) -> [String] {
        decisions.compactMap { $0.value == status ? $0.key : nil }
    }

    var keepIDs: [String]     { ids(.keep) }
    var toDeleteIDs: [String] { ids(.toDelete) }
    var laterIDs: [String]    { ids(.later) }

    func clear(_ status: DecisionStatus) {
        decisions = decisions.filter { $0.value != status }
    }

    func resetAll() { decisions.removeAll() }

    func merge(ids: [String], as status: DecisionStatus) {
        guard !ids.isEmpty else { return }
        var next = decisions
        for id in ids { next[id] = status }
        decisions = next
    }

    // MARK: Persistence

    private func save() {
        let raw: [String: Int] = decisions.mapValues { $0.rawValue }
        UserDefaults.standard.set(raw, forKey: defaultsKey)
    }

    private func load() {
        guard let raw = UserDefaults.standard.dictionary(forKey: defaultsKey) as? [String: Int] else {
            decisions = [:]
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
