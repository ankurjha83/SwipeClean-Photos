//
//  ImageLoaderKey.swift
//  PhotoZ
//
//  Created by Swati Pareek on 01/09/25.
//


import SwiftUI

private struct ImageLoaderKey: EnvironmentKey {
    static let defaultValue: ImageLoading = ImageLoaderService.shared
}

extension EnvironmentValues {
    var imageLoader: ImageLoading {
        get { self[ImageLoaderKey.self] }
        set { self[ImageLoaderKey.self] = newValue }
    }
}
