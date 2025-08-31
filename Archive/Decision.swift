//
//  Decision.swift
//  PhotoZ
//
//  Created by Swati Pareek on 13/08/25.
//


import Foundation
import Photos

enum Decision: String, Codable { case later }

struct AssetRef: Hashable, Codable {
    let localIdentifier: String
}

struct LaterStore {
    private static let key = "later_ids_v1"
    static func load() -> Set<String> {
        (UserDefaults.standard.array(forKey: key) as? [String]).map(Set.init) ?? []
    }
    static func add(_ id: String) {
        var s = load(); s.insert(id)
        UserDefaults.standard.set(Array(s), forKey: key)
    }
    static func remove(_ id: String) {
        var s = load(); s.remove(id)
        UserDefaults.standard.set(Array(s), forKey: key)
    }
}
