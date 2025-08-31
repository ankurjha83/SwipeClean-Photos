//
//  AlbumSelection.swift
//  PhotoZ
//
//  Created by Swati Pareek on 17/08/25.
//


import Foundation

/// Global selection for which album the deck should show. `nil` = All Photos.
@MainActor
final class AlbumSelection: ObservableObject {
    static let shared = AlbumSelection()
    @Published var selected: Album? = nil
}
