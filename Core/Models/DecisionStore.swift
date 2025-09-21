import Foundation
import Combine

public final class DecisionStore: ObservableObject {
    public static let shared = DecisionStore()

    /// assetID → decision
    @Published public private(set) var decisions: [String: DecisionStatus] = [:]

    private init() {}

    // MARK: - Mutations

    /// Set the decision for a given asset id.
    public func stage(assetID: String, as status: DecisionStatus) {
        decisions[assetID] = status
    }

    /// Remove the "delete" decision for a set of asset ids.
    public func unstageDelete(_ ids: Set<String>) {
        guard !ids.isEmpty else { return }
        for id in ids where decisions[id] == .delete {
            decisions[id] = DecisionStatus.none
        }
    }

    /// Convenience: unstage a single id from delete.
    public func unstageDelete(_ id: String) {
        unstageDelete(Set([id]))
    }

    /// Clear all items currently marked for delete.
    public func clearDelete() {
        for (id, status) in decisions where status == .delete {
            decisions[id] = DecisionStatus.none
        }
    }

    /// Remove the "later" decision for a set of asset ids.
    public func unstageLater(_ ids: Set<String>) {
        guard !ids.isEmpty else { return }
        for id in ids where decisions[id] == .later {
            decisions[id] = DecisionStatus.none
        }
    }

    /// Clear all items currently marked "later".
    public func clearAllLater() {
        for (id, status) in decisions where status == .later {
            decisions[id] = DecisionStatus.none
        }
    }

    // MARK: - Queries

    public var deleteIDs: [String] {
        decisions.compactMap { $0.value == .delete ? $0.key : nil }
    }

    public var laterIDs: [String] {
        decisions.compactMap { $0.value == .later ? $0.key : nil }
    }

    public var keepIDs: [String] {
        decisions.compactMap { $0.value == .keep ? $0.key : nil }
    }

    public func decision(for id: String) -> DecisionStatus {
        decisions[id] ?? DecisionStatus.none
    }

    // MARK: - Compatibility aliases (for older view code)

    /// Old name some views used.
    public var toDeleteIDs: [String] { deleteIDs }

    /// Old name some views used.
    public func clearAllDeletes() { clearDelete() }
}
