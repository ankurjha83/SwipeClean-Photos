//
//  Album.swift
//  PhotoZ
//
//  Created by Swati Pareek on 17/08/25.
//


import Photos

public struct Album: Identifiable, Hashable {
    public let id: String               // PHAssetCollection.localIdentifier
    public let collection: PHAssetCollection
    public init(_ c: PHAssetCollection) {
        self.collection = c
        self.id = c.localIdentifier
    }
}
