//
//  PhotoAuthStatus 2.swift
//  PhotoZ
//
//  Created by Swati Pareek on 17/08/25.
//


// Core/Protocols/PhotoLibraryProtocol.swift
import Foundation

enum PhotoAuthStatus { case notDetermined, denied, limited, authorized }

protocol PhotoLibraryProtocol: AnyObject {
    var authorizationStatus: PhotoAuthStatus { get }
    func requestAuthorization() async -> PhotoAuthStatus
    func fetchAllPhotos(includeFavorites: Bool) -> [PhotoAsset]
    func fetch(in album: Album, includeFavorites: Bool) -> [PhotoAsset]
    func delete(localIDs: [String]) async throws
}
