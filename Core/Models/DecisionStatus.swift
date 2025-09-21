import Foundation

public enum DecisionStatus: String, Codable, Equatable {
    case none
    case keep
    case delete
    case later
}
